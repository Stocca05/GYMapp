import SwiftUI

/// Il "Cervello Globale" della sezione Allenamento (Manager / Data Controller).
///
/// Abbiamo fatto un upgrade notevole! Sfruttiamo le nuove macro di Apple `@Observable`.
/// In passato usavamo `ObservableObject` e mettevamo `@Published` davanti a ogni variabile.
/// Ora, con `@Observable` (introdotto in iOS 17), Swift fa tutto il tracciamento delle dipendenze
/// sotto il cofano, automaticamente. Si scrive meno codice, ci sono meno bug, ed è molto più
/// performante nel ri-disegnare la UI!
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

  /// Un punto per seduta, in ordine cronologico, usando l'ID dell'esercizio di catalogo.
  func progressionHistory(for exerciseId: UUID)
    -> [(date: Date, maxWeight: Double, totalVolume: Double)]
  {
    completedSessions.sorted { $0.date < $1.date }.compactMap { session in
      let sets = session.completedExercises
        .filter { $0.baseExercise.id == exerciseId }
        .flatMap(\.sets)

      guard !sets.isEmpty else { return nil }

      let maxWeight = sets.compactMap(\.targetWeight).max() ?? 0
      let totalVolume = sets.reduce(0.0) { volume, set in
        volume + (set.targetWeight ?? 0) * Double(set.targetReps)
      }
      return (date: session.date, maxWeight: maxWeight, totalVolume: totalVolume)
    }
  }

  var currentStreak: Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    var streak = 0

    let uniqueWorkoutDates = Array(Set(completedSessions.map { calendar.startOfDay(for: $0.date) }))
      .sorted(by: >)
    guard let firstDate = uniqueWorkoutDates.first else { return 0 }

    var dateToCheck = today
    // Se oggi non c'è allenamento, controlliamo se c'è stato ieri.
    if firstDate != today {
      if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), firstDate == yesterday
      {
        dateToCheck = firstDate
      } else {
        return 0
      }
    }

    for workoutDate in uniqueWorkoutDates {
      if workoutDate == dateToCheck {
        streak += 1
        if let previousDay = calendar.date(byAdding: .day, value: -1, to: dateToCheck) {
          dateToCheck = previousDay
        }
      } else if workoutDate < dateToCheck {
        break
      }
    }

    return streak
  }

  var currentWeekStatus: [Bool] {
    var calendar = Calendar.current
    calendar.firstWeekday = 2  // Lunedì
    let today = Date()

    guard
      let startOfWeek = calendar.date(
        from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))
    else {
      return Array(repeating: false, count: 7)
    }

    var status = Array(repeating: false, count: 7)
    let workoutDates = Set(completedSessions.map { calendar.startOfDay(for: $0.date) })

    for i in 0..<7 {
      if let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
        let dayStart = calendar.startOfDay(for: day)
        if workoutDates.contains(dayStart) {
          status[i] = true
        }
      }
    }

    return status
  }
  
  // MARK: - Analytics for Widgets
  
  var caloriesBurnedToday: Int {
    let today = Calendar.current.startOfDay(for: Date())
    let todaySessions = completedSessions.filter { Calendar.current.startOfDay(for: $0.date) == today }
    // Stimiamo approssimativamente 400 kcal l'ora (molto basico, ma verosimile)
    let totalSeconds = todaySessions.reduce(0) { $0 + $1.durationSeconds }
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
        equipmentRequirement: "Panca e Bilanciere"
      ),
      ExerciseModel(
        name: "Squat",
        description: "Il re della parte inferiore. Sviluppa quadricipiti e glutei potenti.",
        primaryMuscle: .legs,
        equipmentRequirement: "Rack e Bilanciere"
      ),
      ExerciseModel(
        name: "Trazioni alla Sbarra",
        description: "Esercizio base a corpo libero per l'ipertrofia del gran dorsale.",
        primaryMuscle: .back,
        equipmentRequirement: "Sbarra per Trazioni"
      ),
      ExerciseModel(
        name: "Military Press",
        description: "Spinte verticali con bilanciere per rinforzare i deltoidi.",
        primaryMuscle: .shoulders,
        equipmentRequirement: "Bilanciere"
      ),
      ExerciseModel(
        name: "Curl Bicipiti con Manubri",
        description: "Classico esercizio di isolamento delle braccia.",
        primaryMuscle: .arms,
        equipmentRequirement: "Manubri"
      ),
      ExerciseModel(
        name: "Crunch a terra",
        description: "Flessioni del busto per stimolare il retto dell'addome.",
        primaryMuscle: .core,
        equipmentRequirement: "Tappetino"
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

  /// Rimuove comodamente le schede dalla struttura dati, ideale per l'integrazione
  /// col modifier `.onDelete(perform:)` della SwiftUI List.
  func deletePlan(at offsets: IndexSet) {
    myPlans.remove(atOffsets: offsets)
    savePlansToDisk()
  }

  /// Aggiunge una sessione completata e la salva su disco.
  func addCompletedSession(_ session: WorkoutSession) {
    completedSessions.append(session)
    saveSessionsToDisk()
  }

  /// Analizza logicamente una Scheda per estrarne i gruppi muscolari allenati, senza duplicati.
  func extractTargetMuscleGroups(from plan: WorkoutPlan) -> [MuscleGroup] {
    var uniqueGroups: [MuscleGroup] = []

    for element in plan.exercises {
      let targetMuscle = element.baseExercise.primaryMuscle
      if !uniqueGroups.contains(targetMuscle) {
        uniqueGroups.append(targetMuscle)
      }
    }

    return uniqueGroups
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

  private func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
  }

  private var plansFilePath: URL {
    getDocumentsDirectory().appendingPathComponent("myPlans.json")
  }

  private var sessionsFilePath: URL {
    getDocumentsDirectory().appendingPathComponent("mySessions.json")
  }

  private var exercisesFilePath: URL {
    getDocumentsDirectory().appendingPathComponent("myExercises.json")
  }

  private func savePlansToDisk() {
    do {
      let data = try JSONEncoder().encode(myPlans)
      try data.write(to: plansFilePath, options: [.atomic, .completeFileProtection])
    } catch {
      print("Impossibile salvare i piani su disco: \(error.localizedDescription)")
    }
  }

  private func saveSessionsToDisk() {
    do {
      let data = try JSONEncoder().encode(completedSessions)
      try data.write(to: sessionsFilePath, options: [.atomic, .completeFileProtection])
    } catch {
      print("Impossibile salvare le sessioni su disco: \(error.localizedDescription)")
    }
  }

  private func saveExercisesToDisk() {
    do {
      let data = try JSONEncoder().encode(exerciseDatabase)
      try data.write(to: exercisesFilePath, options: [.atomic, .completeFileProtection])
    } catch {
      print("Impossibile salvare gli esercizi su disco: \(error.localizedDescription)")
    }
  }


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
    ongoingWorkout = nil
    NotificationCenter.default.post(name: Notification.Name("ForceCloseActivity"), object: nil)
  }

  private var restTask: Task<Void, Never>?


  @MainActor
  func startGlobalRestTimer() {
    stopGlobalRestTimer()
    restTask = Task {
      while true {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        if Task.isCancelled { break }

        // Re-leggiamo lo stato FRESCO per non sovrascrivere modifiche dell'utente (kg/reps)
        guard var ongoing = self.ongoingWorkout,
              ongoing.isResting,
              ongoing.remainingRestSeconds > 0 else {
          stopGlobalRestTimer()
          break
        }

        // Modifichiamo SOLO il campo del timer
        ongoing.remainingRestSeconds -= 1
        self.ongoingWorkout = ongoing

        if ongoing.remainingRestSeconds <= 0 {
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

  private func loadPlansFromDisk() -> Bool {
    do {
      let data = try Data(contentsOf: plansFilePath)
      let decodedPlans = try JSONDecoder().decode([WorkoutPlan].self, from: data)
      if !decodedPlans.isEmpty {
        self.myPlans = decodedPlans
        return true
      }
    } catch {
      print("Nessun piano salvato: \(error.localizedDescription)")
    }
    return false
  }

  private func loadSessionsFromDisk() -> Bool {
    do {
      let data = try Data(contentsOf: sessionsFilePath)
      let decoded = try JSONDecoder().decode([WorkoutSession].self, from: data)
      if !decoded.isEmpty {
        self.completedSessions = decoded
        return true
      }
    } catch {
      print("Nessuna sessione salvata: \(error.localizedDescription)")
    }
    return false
  }

  private func loadExercisesFromDisk() -> Bool {
    do {
      let data = try Data(contentsOf: exercisesFilePath)
      let decoded = try JSONDecoder().decode([ExerciseModel].self, from: data)
      if !decoded.isEmpty {
        self.exerciseDatabase = decoded
        return true
      }
    } catch {
      print("Nessun esercizio salvato: \(error.localizedDescription)")
    }
    return false
  }
}
