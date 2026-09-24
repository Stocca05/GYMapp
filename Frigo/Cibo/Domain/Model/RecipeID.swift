import Foundation

/// Identifica in modo univoco una ricetta personale.
nonisolated struct RecipeID: Hashable, Sendable, Codable, Identifiable {
    /// Valore UUID sottostante dell'identificatore.
    let rawValue: UUID

    /// Identificatore usato da SwiftUI.
    var id: UUID { rawValue }
}
