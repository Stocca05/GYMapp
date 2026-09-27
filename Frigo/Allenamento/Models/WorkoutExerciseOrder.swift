import Foundation

enum WorkoutExerciseOrder {
    static func move(_ id: UUID, by offset: Int, in exercises: [WorkoutExercise]) -> [WorkoutExercise] {
        guard (offset == -1 || offset == 1), let index = exercises.firstIndex(where: { $0.id == id }),
              exercises.indices.contains(index + offset) else { return exercises }
        var linkedPartners: [UUID: UUID] = [:]
        for index in exercises.indices where exercises[index].isLinkedToNext && index + 1 < exercises.count {
            linkedPartners[exercises[index].id] = exercises[index + 1].id
        }
        var result = exercises
        result.swapAt(index, index + offset)
        // Do not silently link a moved exercise to a different superset partner.
        for index in result.indices {
            result[index].isLinkedToNext = index + 1 < result.count
                && linkedPartners[result[index].id] == result[index + 1].id
        }
        return result
    }
}
