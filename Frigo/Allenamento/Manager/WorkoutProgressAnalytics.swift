import Foundation

enum ProgressPeriod: String, CaseIterable, Identifiable {
  case month = "30 giorni"
  case quarter = "3 mesi"
  case halfYear = "6 mesi"
  case all = "Tutto"

  var id: Self { self }

  func contains(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> Bool {
    let today = calendar.startOfDay(for: now)
    let start: Date?
    switch self {
    case .month: start = calendar.date(byAdding: .day, value: -29, to: today)
    case .quarter: start = calendar.date(byAdding: .month, value: -3, to: today)
    case .halfYear: start = calendar.date(byAdding: .month, value: -6, to: today)
    case .all: start = nil
    }
    return date <= now && (start.map { date >= $0 } ?? true)
  }
}

struct ExerciseProgressSession: Identifiable {
  let id: UUID
  let date: Date
  let sets: [WorkoutSet]
}

struct ExerciseProgressDay: Identifiable {
  let date: Date
  let sessions: [ExerciseProgressSession]
  let isWeightRecord: Bool

  var id: Date { date }
  var sets: [WorkoutSet] { sessions.flatMap(\.sets) }
  var maxWeight: Double? { sets.compactMap(\.targetWeight).max() }
  var totalReps: Int { sets.reduce(0) { $0 + $1.targetReps } }
  var missingWeightCount: Int { sets.filter { $0.targetWeight == nil }.count }

  // Un carico non registrato non equivale a un carico di zero kg.
  var totalVolume: Double? {
    guard maxWeight != nil else { return nil }
    return sets.reduce(0.0) { $0 + ($1.targetWeight ?? 0) * Double($1.targetReps) }
  }

  func bestReps(at weight: Double) -> Int? {
    sets.filter { $0.targetWeight == weight }.map(\.targetReps).max()
  }
}

struct ExerciseProgressHistory: Identifiable {
  let exercise: ExerciseModel
  let days: [ExerciseProgressDay]

  var id: UUID { exercise.id }
  var recordedWeights: [Double] {
    Array(Set(days.flatMap(\.sets).compactMap(\.targetWeight))).sorted()
  }

  func days(in period: ProgressPeriod, now: Date = Date(), calendar: Calendar = .current)
    -> [ExerciseProgressDay]
  {
    days.filter { period.contains($0.date, now: now, calendar: calendar) }
  }
}

enum ProgressMetric: String, CaseIterable, Identifiable {
  case maxWeight = "Carico"
  case volume = "Volume"
  case repsAtWeight = "Ripetizioni al carico"
  case sets = "Serie"
  case reps = "Ripetizioni"

  var id: Self { self }
  var unit: String {
    switch self {
    case .maxWeight: return "kg"
    case .volume: return "kg × rip."
    case .repsAtWeight, .reps: return "rip."
    case .sets: return "serie"
    }
  }

  var explanation: String {
    switch self {
    case .maxWeight: return "Il carico massimo registrato in ogni giornata."
    case .volume: return "Peso × ripetizioni, sommati sulle serie della giornata."
    case .repsAtWeight: return "Il massimo di ripetizioni in una singola serie al carico scelto."
    case .sets: return "Il numero di serie completate in ogni giornata."
    case .reps: return "Le ripetizioni totali delle serie completate in ogni giornata."
    }
  }

  var usesBars: Bool { self == .volume || self == .sets || self == .reps }

  func value(for day: ExerciseProgressDay, weight: Double? = nil) -> Double? {
    switch self {
    case .maxWeight: return day.maxWeight
    case .volume: return day.totalVolume
    case .repsAtWeight:
      guard let weight, let reps = day.bestReps(at: weight) else { return nil }
      return Double(reps)
    case .sets: return Double(day.sets.count)
    case .reps: return Double(day.totalReps)
    }
  }

  func formatted(_ value: Double?) -> String {
    guard let value else { return "—" }
    return "\(value.formatted(.number.precision(.fractionLength(0...2)))) \(unit)"
  }

  func change(from previous: Double?, to current: Double?) -> String? {
    guard let previous, let current else { return nil }
    let difference = current - previous
    if difference == 0 { return "Invariato" }
    let sign = difference > 0 ? "+" : "−"
    return "\(sign)\(formatted(abs(difference)))"
  }

  func percentageChange(from previous: Double?, to current: Double?) -> String? {
    guard let previous, let current, previous > 0 else { return nil }
    let change = (current - previous) / previous
    return change.formatted(.percent.precision(.fractionLength(0...1)).sign(strategy: .always()))
  }
}

extension WorkoutManager {
  /// Aggrega per ID di catalogo, anche se l'esercizio appare in schede differenti.
  /// I record vengono calcolati sull'intero storico prima di applicare filtri alla UI.
  func exerciseProgressHistories(now: Date = Date(), calendar: Calendar = .current)
    -> [ExerciseProgressHistory]
  {
    var exercises: [UUID: ExerciseModel] = [:]
    var samples: [UUID: [ExerciseProgressSession]] = [:]

    for session in completedSessions.sorted(by: { $0.date < $1.date }) where session.date <= now {
      let grouped = Dictionary(grouping: session.completedExercises, by: { $0.baseExercise.id })
      for (exerciseID, entries) in grouped {
        let sets = entries.flatMap(\.sets)
        guard let exercise = entries.first?.baseExercise, !sets.isEmpty else { continue }
        exercises[exerciseID] = exercise
        samples[exerciseID, default: []].append(
          ExerciseProgressSession(id: session.id, date: session.date, sets: sets)
        )
      }
    }

    return samples.compactMap { exerciseID, sessions in
      guard let exercise = exercises[exerciseID] else { return nil }
      let grouped = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.date) }
      var previousBest: Double?
      let days = grouped.keys.sorted().map { date in
        let daySessions = grouped[date, default: []].sorted { $0.date < $1.date }
        let maxWeight = daySessions.flatMap(\.sets).compactMap(\.targetWeight).max()
        let isRecord = maxWeight.map { weight in previousBest.map { weight > $0 } ?? false } ?? false
        if let maxWeight { previousBest = max(previousBest ?? maxWeight, maxWeight) }
        return ExerciseProgressDay(date: date, sessions: daySessions, isWeightRecord: isRecord)
      }
      return ExerciseProgressHistory(exercise: exercise, days: days)
    }
    .sorted { $0.exercise.name.localizedStandardCompare($1.exercise.name) == .orderedAscending }
  }
}
