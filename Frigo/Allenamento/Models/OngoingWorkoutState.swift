import Foundation

struct OngoingWorkoutState: Codable, Equatable, Hashable {
    var plan: WorkoutPlan
    var activeExercises: [WorkoutExercise]
    var completedSetIDs: Set<UUID>
    var currentExIndex: Int
    var currentSetIndex: Int
    var startTime: Date
    var isResting: Bool
    var remainingRestSeconds: Int
    var restingEndTime: Date?
    var totalRestSeconds: Int
    /// Optional for compatibility with previously encoded workout state.
    var deferredExerciseIDs: Set<UUID>? = nil

    func pendingSetIndex(for exerciseIndex: Int) -> Int? {
        guard activeExercises.indices.contains(exerciseIndex) else { return nil }
        return activeExercises[exerciseIndex].sets.firstIndex { !completedSetIDs.contains($0.id) }
    }

    var remainingExerciseIndices: [Int] {
        activeExercises.indices.filter { pendingSetIndex(for: $0) != nil }
    }

    var nextAlternativeExerciseID: UUID? {
        let candidates = remainingExerciseIndices.filter { $0 != currentExIndex }
        let circular = candidates.filter { $0 > currentExIndex } + candidates.filter { $0 < currentExIndex }
        let index = circular.first { !(deferredExerciseIDs ?? []).contains(activeExercises[$0].id) } ?? circular.first
        return index.map { activeExercises[$0].id }
    }
}
