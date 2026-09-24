import Foundation

struct WorkoutPlan: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var title: String
    var exercises: [WorkoutExercise]
    
    var estimatedDurationInMinutes: Int {
        let allSets = exercises.flatMap { $0.sets }
        guard !allSets.isEmpty else { return 0 }
        
        let averageSecondsPerSetExecution = 30
        let totalExecutionTime = allSets.count * averageSecondsPerSetExecution
        let totalRestTime = allSets.dropLast().reduce(0) { $0 + $1.restTimeInSeconds }
        
        return (totalExecutionTime + totalRestTime) / 60
    }
    
    init(id: UUID = UUID(), title: String, exercises: [WorkoutExercise] = []) {
        self.id = id
        self.title = title
        self.exercises = exercises
    }
}
