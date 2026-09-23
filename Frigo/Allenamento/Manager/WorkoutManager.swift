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
        UserDefaults.standard.set(lastCompletedPlanId.uuidString, forKey: "lastCompletedPlanId")
      } else {
        UserDefaults.standard.removeObject(forKey: "lastCompletedPlanId")
      }
    }
  }

  /// Data dell'ultimo allenamento, usata per capire se l'utente si è già allenato oggi.
  var lastWorkoutDate: Date? {
    didSet {
      UserDefaults.standard.set(lastWorkoutDate, forKey: "lastWorkoutDate")
    }
  }

  /// Inizializzatore del Manager.
  /// Carica i dati da disco se disponibili.
  init() {
    // 1. Carica preferenze utente
    if let uuidString = UserDefaults.standard.string(forKey: "lastCompletedPlanId") {
      self.lastCompletedPlanId = UUID(uuidString: uuidString)
    }
    self.lastWorkoutDate = UserDefaults.standard.object(forKey: "lastWorkoutDate") as? Date

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

  private func setupExerciseDatabase() {
    exerciseDatabase = [
      ExerciseModel(
        name: "Panca Piana con Bilanciere",
        description: "Esercizio multiarticolare per la costruzione del gran pettorale.",
        primaryMuscle: .chest,
        equipmentRequirement: "Panca e Bilanciere",
        imageName: "bench_press_anim"
      ),
      ExerciseModel(
        name: "Squat",
        description: "Il re della parte inferiore. Sviluppa quadricipiti e glutei potenti.",
        primaryMuscle: .legs,
        equipmentRequirement: "Rack e Bilanciere",
        imageName: "squat_anim"
      ),
      ExerciseModel(
        name: "Trazioni alla Sbarra",
        description: "Esercizio base a corpo libero per l'ipertrofia del gran dorsale.",
        primaryMuscle: .back,
        equipmentRequirement: "Sbarra per Trazioni",
        imageName: "pull_ups_anim"
      ),
      ExerciseModel(
        name: "Military Press",
        description: "Spinte verticali con bilanciere per rinforzare i deltoidi.",
        primaryMuscle: .shoulders,
        equipmentRequirement: "Bilanciere",
        imageName: "military_press_anim"
      ),
      ExerciseModel(
        name: "Curl Bicipiti con Manubri",
        description: "Classico esercizio di isolamento delle braccia.",
        primaryMuscle: .arms,
        equipmentRequirement: "Manubri",
        imageName: "bicep_curl_anim"
      ),
            ExerciseModel(
        name: "Spinte con manubri su panca piana",
        description: "Esercizio per il petto con manubri.",
        primaryMuscle: .chest,
        equipmentRequirement: "Manubri e Panca",
        imageName: "dumbbell_bench_press_anim"
      ),
      ExerciseModel(
        name: "Chest Press macchinario",
        description: "Esercizio al macchinario per il grande pettorale.",
        primaryMuscle: .chest,
        equipmentRequirement: "Macchinario",
        imageName: "chest_press_anim"
      ),
      ExerciseModel(
        name: "Lento avanti con manubri da seduti",
        description: "Schiena ben appoggiata allo schienale. Per le spalle.",
        primaryMuscle: .shoulders,
        equipmentRequirement: "Manubri e Panca",
        imageName: "seated_press_anim"
      ),
      ExerciseModel(
        name: "Alzate laterali con manubri",
        description: "Esercizio di isolamento per i deltoidi laterali.",
        primaryMuscle: .shoulders,
        equipmentRequirement: "Manubri",
        imageName: "lateral_raises_anim"
      ),
      ExerciseModel(
        name: "Lat machine avanti",
        description: "Trazione verticale per il dorso.",
        primaryMuscle: .back,
        equipmentRequirement: "Lat Machine",
        imageName: "lat_pulldown_anim"
      ),
      ExerciseModel(
        name: "Pushdown ai cavi",
        description: "Esercizio di isolamento per i tricipiti.",
        primaryMuscle: .arms,
        equipmentRequirement: "Cavi",
        imageName: "tricep_pushdown_anim"
      ),
      ExerciseModel(
        name: "Leg Press a 45 gradi",
        description: "Non staccare MAI il sedere e la parte bassa della schiena dallo schienale.",
        primaryMuscle: .legs,
        equipmentRequirement: "Leg Press",
        imageName: "leg_press_anim"
      ),
      ExerciseModel(
        name: "Leg Extension",
        description: "Esercizio di isolamento per i quadricipiti.",
        primaryMuscle: .legs,
        equipmentRequirement: "Macchinario",
        imageName: "leg_extension_anim"
      ),
      ExerciseModel(
        name: "Leg Curl da seduto",
        description: "Isolamento per i femorali da seduto.",
        primaryMuscle: .legs,
        equipmentRequirement: "Macchinario",
        imageName: "seated_leg_curl_anim"
      ),
      ExerciseModel(
        name: "Calf alla pressa",
        description: "Esercizio per i polpacci alla pressa.",
        primaryMuscle: .legs,
        equipmentRequirement: "Leg Press",
        imageName: "calf_press_anim"
      ),
      ExerciseModel(
        name: "Plank",
        description: "Esercizio statico per il core. Fermati non appena perdi la postura corretta.",
        primaryMuscle: .core,
        equipmentRequirement: "Corpo libero",
        imageName: "bird_dog_anim"
      ),
      ExerciseModel(
        name: "Bird-Dog",
        description: "Esercizio per stabilità L4-L5.",
        primaryMuscle: .core,
        equipmentRequirement: "Corpo libero",
        imageName: "bird_dog_anim"
      ),
      ExerciseModel(
        name: "Iperestensioni su panca",
        description: "A corpo libero, con esecuzione lenta e controllata.",
        primaryMuscle: .core,
        equipmentRequirement: "Panca per lombari",
        imageName: "bird_dog_anim"
      ),
      ExerciseModel(
        name: "Rematore al macchinario con appoggio",
        description: "Tieni il petto saldamente in appoggio per proteggere la bassa schiena.",
        primaryMuscle: .back,
        equipmentRequirement: "Macchinario",
        imageName: "lat_pulldown_anim"
      ),
      ExerciseModel(
        name: "Lat machine con presa inversa",
        description: "Variante per dorso e bicipiti.",
        primaryMuscle: .back,
        equipmentRequirement: "Lat Machine",
        imageName: "lat_pulldown_anim"
      ),
      ExerciseModel(
        name: "Pectoral Machine",
        description: "Esercizio di isolamento per il petto (croci al macchinario).",
        primaryMuscle: .chest,
        equipmentRequirement: "Macchinario",
        imageName: "chest_press_anim"
      ),
      ExerciseModel(
        name: "Alzate laterali ai cavi",
        description: "Tensione continua per i deltoidi.",
        primaryMuscle: .shoulders,
        equipmentRequirement: "Cavi",
        imageName: "lateral_raises_anim"
      ),
      ExerciseModel(
        name: "Curl con manubri su panca inclinata",
        description: "Isolamento per bicipiti in massimo allungamento.",
        primaryMuscle: .arms,
        equipmentRequirement: "Manubri e Panca",
        imageName: "bicep_curl_anim"
      ),
      ExerciseModel(
        name: "Curl a martello ai cavi",
        description: "Per bicipiti e brachioradiale.",
        primaryMuscle: .arms,
        equipmentRequirement: "Cavi",
        imageName: "bicep_curl_anim"
      ),
      ExerciseModel(
        name: "Leg Press (Pedana Alta)",
        description: "Versione della Leg Press per massimizzare il focus sui glutei/femorali. Tieni i piedi posizionati in alto.",
        primaryMuscle: .legs,
        equipmentRequirement: "Leg Press",
        imageName: "leg_press_anim"
      ),
      ExerciseModel(
        name: "Affondi con manubri (Split Squat)",
        description: "Esercizio per gambe e glutei (o Bulgarian Split Squat).",
        primaryMuscle: .legs,
        equipmentRequirement: "Manubri",
        imageName: "squat_anim"
      ),
      ExerciseModel(
        name: "Leg Curl disteso",
        description: "Isolamento femorali da posizione prona.",
        primaryMuscle: .legs,
        equipmentRequirement: "Macchinario",
        imageName: "seated_leg_curl_anim"
      ),
      ExerciseModel(
        name: "Calf seduto",
        description: "Polpacci da seduto (stimolo sul soleo).",
        primaryMuscle: .legs,
        equipmentRequirement: "Macchinario",
        imageName: "calf_press_anim"
      ),
      ExerciseModel(
        name: "Crunch inverso",
        description: "Esercizio dinamico per l'addome.",
        primaryMuscle: .core,
        equipmentRequirement: "Corpo libero",
        imageName: "bird_dog_anim"
      ),
      ExerciseModel(
        name: "Crunch a terra",
        description: "Flessioni del busto per stimolare il retto dell'addome.",
        primaryMuscle: .core,
        equipmentRequirement: "Tappetino",
        imageName: "bird_dog_anim"
      ),
    ]
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

  func startOrResumeWorkout(plan: WorkoutPlan) {
    registerInteraction()
    if ongoingWorkout?.plan.id != plan.id {
      // Avvia una nuova sessione da zero
      ongoingWorkout = OngoingWorkoutState(
        plan: plan,
        activeExercises: plan.exercises,
        completedSetIDs: [],
        currentExIndex: 0,
        currentSetIndex: 0,
        startTime: Date(),
        isResting: false,
        remainingRestSeconds: 0,
        totalRestSeconds: 1
      )
    }
  }

  // MARK: - Persistenza Dati

  private var plansFilePath: URL {
    URL.documentsDirectory.appending(path: "myPlans.json")
  }

  private var sessionsFilePath: URL {
    URL.documentsDirectory.appending(path: "mySessions.json")
  }

  private var exercisesFilePath: URL {
    URL.documentsDirectory.appending(path: "myExercises.json")
  }

  // MARK: - Generic Persistence Helpers

  private func saveToDisk<T: Encodable>(_ object: T, to url: URL) {
    do {
      let data = try JSONEncoder().encode(object)
      Task.detached(priority: .background) {
        do {
          try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch {
          print("Impossibile salvare su disco (\(url.lastPathComponent)): \(error.localizedDescription)")
        }
      }
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

  /// Keeps exactly one Live Activity for the current workout and updates it only
  /// when the workout state changes. The system renders the countdown itself.
  @MainActor
  func updateWorkoutLiveActivity(for ongoing: OngoingWorkoutState) {
    let endTime = ongoing.restingEndTime ?? Date()
    let state = WorkoutTimerAttributes.ContentState(
      startTime: Date(),
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
  }

  private func nextExerciseTitle(for ongoing: OngoingWorkoutState) -> String {
    let currentExercise = ongoing.activeExercises[ongoing.currentExIndex]
    if ongoing.currentSetIndex < currentExercise.sets.count - 1 {
      return "Serie \(ongoing.currentSetIndex + 2)"
    }
    if ongoing.currentExIndex < ongoing.activeExercises.count - 1 {
      return ongoing.activeExercises[ongoing.currentExIndex + 1].baseExercise.name
    }
    return "Fine allenamento"
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
