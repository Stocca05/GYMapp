import Foundation

/// Identifica in modo univoco un prodotto del catalogo.
nonisolated struct ProductID: Hashable, Sendable, Codable {
    /// Valore UUID sottostante dell'identificatore.
    let rawValue: UUID

    /// Crea un nuovo identificatore casuale.
    init() {
        rawValue = UUID()
    }

    /// Crea un identificatore da un UUID esistente.
    ///
    /// - Parameter rawValue: UUID da incapsulare.
    init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}
