import ActivityKit
import SwiftUI

/// Il "Cervello Globale" della sezione Allenamento (Manager / Data Controller).
///
/// Abbiamo fatto un upgrade notevole! Sfruttiamo le nuove macro di Apple `@Observable`.
/// In passato usavamo `ObservableObject` e mettevamo `@Published` davanti a ogni variabile.
/// Ora, con `@Observable` (introdotto in iOS 17), Swift fa tutto il tracciamento delle dipendenze
/// sotto il cofano, automaticamente. Si scrive meno codice, ci sono meno bug, ed è molto più
/// performante nel ri-disegnare la UI!
@MainActor
@Observable
class WorkoutManager {
  private let storageDirectory: URL
  private let defaults: UserDefaults
  let fileWriter = WorkoutFileWriter()


  /// Il catalogo globale di tutti gli esercizi conosciuti dall'app.
  var exerciseDatabase: [ExerciseModel] = []

  /// Le schede di allenamento create e salvate (per ora in memoria) dall'utente.
  var myPlans: [WorkoutPlan] = []

  /// Le sessioni passate completate, log storico.
  var completedSessions: [WorkoutSession] = []

  /// L allenamento correntemente in esecuzione
  var ongoingWorkout: OngoingWorkoutState?

  /// Traccia l'ultima interazione dell'utente per terminare automaticamente dopo 15m
  var lastInteractionDate: Date = Date()

  // MARK: - Streak & Analytics

  var currentStreak: Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let workoutDates = Set(completedSessions.map { calendar.startOfDay(for: $0.date) })
    
    var dateToCheck = today
    if !workoutDates.contains(today) {
      if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), workoutDates.contains(yesterday) {
        dateToCheck = yesterday
      } else {
        return 0
      }
    }
    
    var streak = 0
    while workoutDates.contains(dateToCheck) {
      streak += 1
      guard let previousDay = calendar.date(byAdding: .day, value: -1, to: dateToCheck) else { break }
      dateToCheck = previousDay
    }
    
    return streak
  }

  var currentWeekStatus: [Bool] {
    var calendar = Calendar.current
    calendar.firstWeekday = 2  // Lunedì
    
    guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
      return Array(repeating: false, count: 7)
    }

    let workoutDates = Set(completedSessions.map { calendar.startOfDay(for: $0.date) })
    
    return (0..<7).map { i in
      guard let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) else { return false }
      return workoutDates.contains(calendar.startOfDay(for: day))
    }
  }
  
  // MARK: - Analytics for Widgets
  
  var caloriesBurnedToday: Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let totalSeconds = completedSessions.reduce(0) { total, session in
      calendar.startOfDay(for: session.date) == today ? total + session.durationSeconds : total
    }
    return Int((Double(totalSeconds) / 3600.0) * 400.0)
  }
  
  struct HistoricalVolume: Identifiable {
    let id = UUID()
    let sessionName: String
    let volume: Int
  }
  
  func getRecentVolumes(limit: Int = 4) -> [HistoricalVolume] {
    let recent = completedSessions.sorted(by: { $0.date > $1.date }).prefix(limit).reversed()
    return recent.compactMap { session in
        let planTitle = myPlans.first(where: { $0.id == session.planId })?.title ?? "S"
        // Prendi solo le prime 2-3 lettere per non sbordare nel grafico
        let shortName = String(planTitle.prefix(3)).uppercased()
        return HistoricalVolume(sessionName: shortName, volume: session.totalVolume)
    }
  }

  // MARK: - Gestione Rotazione e Banner

  /// ID dell'ultima scheda completata. Aggiornato automaticamente su persistenza (UserDefaults).
  var lastCompletedPlanId: UUID? {
    didSet {
      if let lastCompletedPlanId {
        defaults.set(lastCompletedPlanId.uuidString, forKey: "lastCompletedPlanId")
      } else {
        defaults.removeObject(forKey: "lastCompletedPlanId")
      }
    }
  }

  /// Data dell'ultimo allenamento, usata per capire se l'utente si è già allenato oggi.
  var lastWorkoutDate: Date? {
    didSet {
      defaults.set(lastWorkoutDate, forKey: "lastWorkoutDate")
    }
  }

  /// Inizializzatore del Manager.
  /// Carica i dati da disco se disponibili.
  init(storageDirectory: URL = .documentsDirectory, defaults: UserDefaults = .standard) {
    self.storageDirectory = storageDirectory
    self.defaults = defaults
    // 1. Carica preferenze utente
    if let uuidString = defaults.string(forKey: "lastCompletedPlanId") {
      self.lastCompletedPlanId = UUID(uuidString: uuidString)
    }
    self.lastWorkoutDate = defaults.object(forKey: "lastWorkoutDate") as? Date

    // 2. Carica catalogo esercizi da disco, altrimenti usa il default
    if !loadExercisesFromDisk() {
      setupExerciseDatabase()
    }

    // 3. Carica piani da disco
    _ = loadPlansFromDisk()

    // 4. Carica sessioni da disco
    _ = loadSessionsFromDisk()
  }

  // MARK: - Gestione Catalogo Esercizi
  
  func addCustomExercise(_ exercise: ExerciseModel) {
    exerciseDatabase.append(exercise)
    saveExercisesToDisk()
  }


  // MARK: - Funzioni Logiche di Rotazione & Completamento

  /// Verifica se nella giornata odierna (mezzanotte-mezzanotte) è stato già registrato un allenamento.
  var hasWorkedOutToday: Bool {
    guard let lastWorkoutDate else { return false }
    return Calendar.current.isDateInToday(lastWorkoutDate)
  }

  /// Macchina a Stati del Banner. Calcola quale scheda suggerire:
  /// - Nil, se non ci sono schede.
  /// - La Prossima, seguendo l'approccio Rotazionale e analizzando l'ultimo ID salvato.
  func suggestedWorkoutForToday() -> WorkoutPlan? {
    // Nessuna scheda esistente (Stato A)
    guard !myPlans.isEmpty else { return nil }

    // Se c'è un tracciamento pregresso, proviamo a trovare a che indice si trovava l'ultima scheda
    guard let lastId = lastCompletedPlanId,
      let lastIndex = myPlans.firstIndex(where: { $0.id == lastId })
    else {
      // Seleziona la prima scheda in assoluto se non ci sono progressi o la vecchia scheda è stata rimossa
      return myPlans.first
    }

    // Approccio Rotazionale: seleziona quella seguente, con ritorno alla prima una volta finito il ciclo
    let nextIndex = (lastIndex + 1) % myPlans.count
    return myPlans[nextIndex]
  }

  /// Chiude un allenamento: salva il traguardo odierno e fa ruotare di conseguenza la proposta.
  func markWorkoutAsCompleted(_ plan: WorkoutPlan) {
    lastCompletedPlanId = plan.id
    lastWorkoutDate = Date()
  }

  // MARK: - Funzioni di Utilità (Helpers)

  /// Salva o aggiorna una scheda utente in memoria.
  func savePlan(_ plan: WorkoutPlan) {
    if let index = myPlans.firstIndex(where: { $0.id == plan.id }) {
      // Aggiorna l'esistente
      myPlans[index] = plan
    } else {
      // Aggiungi una nuova scheda
      myPlans.append(plan)
    }
    savePlansToDisk()
  }

  /// Aggiunge una sessione completata e la salva su disco.
  func addCompletedSession(_ session: WorkoutSession) {
    completedSessions.append(session)
    saveSessionsToDisk()
  }

  @discardableResult
  func startOrResumeWorkout(plan: WorkoutPlan) -> Bool {
    registerInteraction()
    if ongoingWorkout?.plan.id != plan.id {
      guard let firstExercise = plan.exercises.firstIndex(where: { !$0.sets.isEmpty }) else { return false }
      // Preserve exercise indexes and group boundaries in legacy plans.
      ongoingWorkout = OngoingWorkoutState(
        plan: plan,
        activeExercises: plan.exercises,
        completedSetIDs: [],
        currentExIndex: firstExercise,
        currentSetIndex: 0,
        startTime: Date(),
        isResting: false,
        remainingRestSeconds: 0,
        totalRestSeconds: 1
      )
    }
    return true
  }

  // MARK: - Persistenza Dati

  private var plansFilePath: URL {
    storageDirectory.appending(path: "myPlans.json")
  }

  private var sessionsFilePath: URL {
    storageDirectory.appending(path: "mySessions.json")
  }

  private var exercisesFilePath: URL {
    storageDirectory.appending(path: "myExercises.json")
  }

  // MARK: - Generic Persistence Helpers

  private func saveToDisk<T: Encodable>(_ object: T, to url: URL) {
    do {
      let data = try JSONEncoder().encode(object)
      fileWriter.save(data, to: url)
    } catch {
      print("Errore di codifica: \(error.localizedDescription)")
    }
  }

  private func loadFromDisk<T: Decodable>(from url: URL, as type: T.Type) -> T? {
    do {
      let data = try Data(contentsOf: url)
      return try JSONDecoder().decode(T.self, from: data)
    } catch {
      return nil
    }
  }

  private func savePlansToDisk() { saveToDisk(myPlans, to: plansFilePath) }
  private func saveSessionsToDisk() { saveToDisk(completedSessions, to: sessionsFilePath) }
  private func saveExercisesToDisk() { saveToDisk(exerciseDatabase, to: exercisesFilePath) }

  // MARK: - Inactivity Tracking
  
  func registerInteraction() {
    lastInteractionDate = Date()
  }

  func checkInactivityAndCancelIfNeeded() {
    guard ongoingWorkout != nil else { return }
    let elapsed = Date().timeIntervalSince(lastInteractionDate)
    if elapsed >= 900 { // 15 minuti = 15 * 60 = 900s
      cancelWorkoutGlobally()
    }
  }

  @MainActor
  func cancelWorkoutGlobally() {
    stopGlobalRestTimer()
    endWorkoutLiveActivity()
    ongoingWorkout = nil
    NotificationCenter.default.post(name: Notification.Name("ForceCloseActivity"), object: nil)
  }

  private var restTask: Task<Void, Never>?
  private var restNotificationTask: Task<Void, Never>?

  func scheduleRestCompletionNotification(at endTime: Date) {
    restNotificationTask?.cancel()
    restNotificationTask = Task {
      await WorkoutNotificationManager.shared.scheduleRestCompletion(at: endTime)
    }
  }

  /// Keeps exactly one Live Activity for the current workout and updates it only
  /// when the workout state changes. The system renders the countdown itself.
  @MainActor
  func updateWorkoutLiveActivity(for ongoing: OngoingWorkoutState) {
    let now = Date()
    let endTime = max(now, ongoing.restingEndTime ?? now)
    let state = WorkoutTimerAttributes.ContentState(
      startTime: now,
      restingEndTime: endTime,
      exerciseName: nextExerciseTitle(for: ongoing),
      isResting: ongoing.isResting
    )

    let activities = Activity<WorkoutTimerAttributes>.activities
    if let activity = activities.first {
      for duplicate in activities.dropFirst() {
        Task { @MainActor in
          await duplicate.end(
            ActivityContent(state: duplicate.content.state, staleDate: nil),
            dismissalPolicy: .immediate
          )
        }
      }

      Task { @MainActor in
        await activity.update(ActivityContent(state: state, staleDate: nil))
      }
      return
    }

    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

    do {
      let attributes = WorkoutTimerAttributes(planName: ongoing.plan.title)
      _ = try Activity<WorkoutTimerAttributes>.request(
        attributes: attributes,
        content: ActivityContent(state: state, staleDate: nil),
        pushType: nil
      )
    } catch {
      print("Impossibile avviare la Live Activity: \(error.localizedDescription)")
    }
  }

  @MainActor
  func endWorkoutLiveActivity() {
    for activity in Activity<WorkoutTimerAttributes>.activities {
      Task { @MainActor in
        await activity.end(
          ActivityContent(state: activity.content.state, staleDate: nil),
          dismissalPolicy: .immediate
        )
      }
    }
  }

  @MainActor
  func startGlobalRestTimer() {
    stopGlobalRestTimer()

    if let restingEndTime = ongoingWorkout?.restingEndTime {
      scheduleRestCompletionNotification(at: restingEndTime)
    }

    restTask = Task {
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))
        guard !Task.isCancelled,
              var ongoing = self.ongoingWorkout,
              ongoing.isResting,
              let endTime = ongoing.restingEndTime
        else {
          stopGlobalRestTimer()
          break
        }

        let remainingSeconds = max(0, Int(ceil(endTime.timeIntervalSinceNow)))
        if ongoing.remainingRestSeconds != remainingSeconds {
          ongoing.remainingRestSeconds = remainingSeconds
          self.ongoingWorkout = ongoing
        }

        if remainingSeconds == 0 {
          NotificationCenter.default.post(
            name: Notification.Name("RestFinishedGlobally"), object: nil)
          stopGlobalRestTimer()
          break
        }
      }
    }
  }

  @MainActor
  func stopGlobalRestTimer() {
    restTask?.cancel()
    restTask = nil
    restNotificationTask?.cancel()
    restNotificationTask = nil
    WorkoutNotificationManager.shared.cancelRestCompletion()
  }

  private func nextExerciseTitle(for ongoing: OngoingWorkoutState) -> String {
    guard ongoing.isResting else {
      return ongoing.activeExercises[ongoing.currentExIndex].baseExercise.name
    }
    guard let next = WorkoutSequence.nextPending(afterExercise: ongoing.currentExIndex,
        set: ongoing.currentSetIndex, ongoing: ongoing) else {
      return "Fine allenamento"
    }
    return next.0 == ongoing.currentExIndex
      ? "Serie \(next.1 + 1)" : ongoing.activeExercises[next.0].baseExercise.name
  }

  private func loadPlansFromDisk() -> Bool {
    if let decoded = loadFromDisk(from: plansFilePath, as: [WorkoutPlan].self), !decoded.isEmpty {
      self.myPlans = decoded; return true
    }
    return false
  }

  private func loadSessionsFromDisk() -> Bool {
    if let decoded = loadFromDisk(from: sessionsFilePath, as: [WorkoutSession].self), !decoded.isEmpty {
      self.completedSessions = decoded; return true
    }
    return false
  }

  private func loadExercisesFromDisk() -> Bool {
    if let decoded = loadFromDisk(from: exercisesFilePath, as: [ExerciseModel].self), !decoded.isEmpty {
      self.exerciseDatabase = decoded; return true
    }
    return false
  }
}
