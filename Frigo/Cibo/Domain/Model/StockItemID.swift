import Foundation

/// Identifica in modo univoco un lotto in inventario.
nonisolated struct StockItemID: Hashable, Sendable, Codable {
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
