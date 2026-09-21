import Foundation

/// Run with Tests/run-progress-checks.sh. Uses the application's actual models and manager.
@main
struct WorkoutProgressAnalyticsChecks {
  @MainActor
  static func main() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Lisbon")!
    let formatter = ISO8601DateFormatter()
    func date(_ value: String) -> Date { formatter.date(from: value)! }
    let now = date("2026-09-21T20:00:00Z")
    let bench = ExerciseModel(name: "Panca", primaryMuscle: .chest)
    let other = ExerciseModel(name: "Panca", primaryMuscle: .chest)
    func entry(_ exercise: ExerciseModel, _ weight: Double?, _ reps: Int) -> WorkoutExercise {
      WorkoutExercise(baseExercise: exercise, sets: [
        WorkoutSet(targetReps: reps, targetWeight: weight, isCompleted: true)
      ])
    }
    func session(_ time: String, _ entries: [WorkoutExercise]) -> WorkoutSession {
      WorkoutSession(planId: UUID(), date: date(time), completedExercises: entries)
    }
    let manager = WorkoutManager()
    manager.completedSessions = [
      session("2026-09-18T12:00:00Z", [entry(bench, 105, 5)]),
      session("2026-08-01T12:00:00Z", [entry(bench, 100, 5)]),
      session("2026-09-10T00:15:00Z", [entry(bench, 60.5, 8), entry(bench, 65, 6), entry(bench, 60.5, 3)]),
      session("2026-09-10T22:00:00Z", [entry(bench, 70, 5), entry(other, nil, 12)]),
      session("2026-09-14T12:00:00Z", [entry(bench, 105, 5)]),
      session("2026-09-19T12:00:00Z", [entry(bench, nil, 10), entry(other, 0, 15)]),
      session("2026-09-20T12:00:00Z", []),
      session("2026-09-22T12:00:00Z", [entry(bench, 200, 2)])
    ]
    let histories = manager.exerciseProgressHistories(now: now, calendar: calendar)
    precondition(histories.count == 2, "Same names with different catalog IDs must stay separate")
    let history = histories.first { $0.id == bench.id }!
    precondition(history.days.count == 5, "Combine same-day sessions; omit legacy and future sessions")
    precondition(history.days.map(\.date) == history.days.map(\.date).sorted())
    let day = history.days[1]
    precondition(day.sessions.count == 2 && day.sets.count == 4)
    precondition(day.maxWeight == 70 && day.totalVolume == 1405.5 && day.totalReps == 22)
    precondition(day.bestReps(at: 60.5) == 8, "Compare best single set, not total reps at weight")
    precondition(day.bestReps(at: 80) == nil)
    precondition(!day.isWeightRecord, "A period filter must not erase an earlier personal best")
    precondition(history.days.filter(\.isWeightRecord).count == 1, "Repeated bests are not new records")
    let recent = history.days(in: .month, now: now, calendar: calendar)
    precondition(recent.count == 4 && recent.filter(\.isWeightRecord).count == 1)
    let missing = history.days.last!
    precondition(missing.maxWeight == nil && missing.totalVolume == nil && missing.missingWeightCount == 1)
    precondition(ProgressMetric.reps.value(for: missing) == 10)
    precondition(ProgressMetric.sets.value(for: missing) == 1)
    let zero = histories.first { $0.id == other.id }!.days.last!
    precondition(zero.maxWeight == 0 && zero.totalVolume == 0, "Explicit zero is distinct from missing weight")
    precondition(ProgressMetric.volume.percentageChange(from: 0, to: 20) == nil)
    precondition(ProgressMetric.maxWeight.change(from: nil, to: 20) == nil)

    let lowerBound = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: now))!
    precondition(ProgressPeriod.month.contains(lowerBound, now: now, calendar: calendar))
    precondition(!ProgressPeriod.month.contains(lowerBound.addingTimeInterval(-1), now: now, calendar: calendar))
    precondition(!ProgressPeriod.all.contains(now.addingTimeInterval(1), now: now, calendar: calendar))
    let dstNow = date("2026-03-30T12:00:00Z")
    let dstBoundary = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: dstNow))!
    precondition(ProgressPeriod.month.contains(dstBoundary, now: dstNow, calendar: calendar))
    precondition(!ProgressPeriod.month.contains(dstBoundary.addingTimeInterval(-1), now: dstNow, calendar: calendar))

    let original = manager.completedSessions[0]
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(WorkoutSession.self, from: data)
    precondition(decoded.completedExercises == original.completedExercises)
    var legacy = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    legacy.removeValue(forKey: "completedExercises")
    let old = try JSONDecoder().decode(WorkoutSession.self, from: JSONSerialization.data(withJSONObject: legacy))
    precondition(old.completedExercises.isEmpty && old.id == original.id)

    manager.completedSessions = []
    precondition(manager.exerciseProgressHistories(now: now, calendar: calendar).isEmpty)
    print("PASS: daily aggregation, catalog IDs, decimals, records across periods, repetitions at weight, missing/zero weights, date boundaries and DST, legacy JSON, empty history.")
  }
}
