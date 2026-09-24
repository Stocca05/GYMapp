import Foundation
import ActivityKit

nonisolated struct WorkoutTimerAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable {
        var startTime: Date
        var restingEndTime: Date
        var exerciseName: String
        var isResting: Bool
    }
    
    var planName: String
}
