import re

with open("FrigoWidget/WorkoutTimerAttributes.swift", "r") as f:
    text = f.read()

new_content = """import Foundation
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
"""

with open("FrigoWidget/WorkoutTimerAttributes.swift", "w") as f:
    f.write(new_content)
