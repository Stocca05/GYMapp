import Foundation

enum MuscleGroup: String, Codable, CaseIterable, Sendable {
    case chest = "Petto"
    case back = "Dorso"
    case legs = "Gambe"
    case shoulders = "Spalle"
    case arms = "Braccia"
    case core = "Addome"
    case fullBody = "Full Body"
    case cardio = "Cardio"
    
    var iconName: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.cross.training"
        case .legs: return "figure.step.training"
        case .shoulders: return "figure.arms.open"
        case .arms: return "figure.gymnastics"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.mind.and.body"
        case .cardio: return "figure.run"
        }
    }
}

struct ExerciseModel: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let name: String
    let description: String?
    let primaryMuscle: MuscleGroup
    let equipmentRequirement: String?
    let imageName: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        primaryMuscle: MuscleGroup,
        equipmentRequirement: String? = nil,
        imageName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.primaryMuscle = primaryMuscle
        self.equipmentRequirement = equipmentRequirement
        self.imageName = imageName
    }
}
