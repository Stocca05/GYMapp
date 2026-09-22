import Foundation
import SwiftUI

enum SetType: String, Codable, CaseIterable, Hashable, Identifiable {
    case working = "Work"
    case warmup = "Warm-up"
    case drop = "Drop"
    case failure = "Max"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .warmup: return .orange
        case .working: return .green
        case .drop: return .purple
        case .failure: return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .warmup: return "flame.fill"
        case .working: return "checkmark.circle.fill"
        case .drop: return "arrow.down.right.circle.fill"
        case .failure: return "exclamationmark.triangle.fill"
        }
    }
}

struct WorkoutSet: Identifiable, Codable, Hashable {
    let id: UUID
    var targetReps: Int
    var targetWeight: Double?
    var restTimeInSeconds: Int
    var isCompleted: Bool
    
    var setType: SetType
    var rpe: Int?
    
    init(id: UUID = UUID(), 
         targetReps: Int, 
         targetWeight: Double? = nil, 
         restTimeInSeconds: Int = 90, 
         setType: SetType = .working,
         rpe: Int? = nil,
         isCompleted: Bool = false) {
        self.id = id
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.restTimeInSeconds = restTimeInSeconds
        self.setType = setType
        self.rpe = rpe
        self.isCompleted = isCompleted
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, targetReps, targetWeight, restTimeInSeconds, isCompleted, setType, rpe
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.targetReps = try container.decodeIfPresent(Int.self, forKey: .targetReps) ?? 0
        self.targetWeight = try container.decodeIfPresent(Double.self, forKey: .targetWeight)
        self.restTimeInSeconds = try container.decodeIfPresent(Int.self, forKey: .restTimeInSeconds) ?? 90
        self.isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        self.setType = try container.decodeIfPresent(SetType.self, forKey: .setType) ?? .working
        self.rpe = try container.decodeIfPresent(Int.self, forKey: .rpe)
    }
}
