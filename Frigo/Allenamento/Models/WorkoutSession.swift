import Foundation

struct WorkoutSession: Identifiable, Codable {
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
        totalVolume = try container.decode(Int.self, forKey: .totalVolume)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        // Le sessioni precedenti non contengono il dettaglio degli esercizi.
        completedExercises = try container.decodeIfPresent(
            [WorkoutExercise].self, forKey: .completedExercises
        ) ?? []
    }
}
