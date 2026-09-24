import Foundation

struct WorkoutExercise: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let baseExercise: ExerciseModel
    var sets: [WorkoutSet]
    var notes: String
    var isLinkedToNext: Bool = false
    
    init(id: UUID = UUID(), baseExercise: ExerciseModel, sets: [WorkoutSet] = [], notes: String = "", isLinkedToNext: Bool = false) {
        self.id = id
        self.baseExercise = baseExercise
        self.sets = sets
        self.notes = notes
        self.isLinkedToNext = isLinkedToNext
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, baseExercise, sets, notes, isLinkedToNext
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        baseExercise = try container.decode(ExerciseModel.self, forKey: .baseExercise)
        sets = try container.decodeIfPresent([WorkoutSet].self, forKey: .sets) ?? []
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        isLinkedToNext = try container.decodeIfPresent(Bool.self, forKey: .isLinkedToNext) ?? false
    }
}
