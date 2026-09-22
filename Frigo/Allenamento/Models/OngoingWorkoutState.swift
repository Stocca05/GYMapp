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
}
