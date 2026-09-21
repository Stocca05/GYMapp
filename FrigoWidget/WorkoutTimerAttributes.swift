import Foundation
import ActivityKit

struct WorkoutTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var restingEndTime: Date
        var exerciseName: String
        var isResting: Bool
    }
    
    var planName: String
}
