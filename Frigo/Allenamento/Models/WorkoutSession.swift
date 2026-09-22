import Foundation

struct WorkoutSession: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let planId: UUID
    let date: Date
    let totalVolume: Int
    let durationSeconds: Int
    let completedExercises: [WorkoutExercise]
    
    init(
        id: UUID = UUID(), planId: UUID, date: Date, totalVolume: Int = 0,
        durationSeconds: Int = 0, completedExercises: [WorkoutExercise] = []
    ) {
        self.id = id
        self.planId = planId
        self.date = date
        self.totalVolume = totalVolume
        self.durationSeconds = durationSeconds
        self.completedExercises = completedExercises
    }

    private enum CodingKeys: String, CodingKey {
        case id, planId, date, totalVolume, durationSeconds, completedExercises
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        planId = try container.decode(UUID.self, forKey: .planId)
        date = try container.decode(Date.self, forKey: .date)
        totalVolume = try container.decodeIfPresent(Int.self, forKey: .totalVolume) ?? 0
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds) ?? 0
        completedExercises = try container.decodeIfPresent(
            [WorkoutExercise].self, forKey: .completedExercises
        ) ?? []
    }
}
