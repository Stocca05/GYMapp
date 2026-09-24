import Foundation
import Observation

@Observable
class WorkoutManager {
    var lastInteractionDate: Date = Date()
    var ongoingWorkout: String? = "Workout"
    
    func checkInactivityAndCancelIfNeeded() {
        guard ongoingWorkout != nil else { return }
        let elapsed = Date().timeIntervalSince(lastInteractionDate)
        if elapsed >= 900 { 
            cancelWorkoutGlobally()
        }
    }

    @MainActor
    func cancelWorkoutGlobally() {
        ongoingWorkout = nil
    }
}
