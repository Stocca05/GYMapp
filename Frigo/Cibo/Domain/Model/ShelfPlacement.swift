import Foundation

/// Descrive la posizione relativa di un lotto su un ripiano.
nonisolated struct ShelfPlacement: Sendable, Hashable, Codable {
    /// Indice verticale del ripiano, a partire da zero.
    let shelfIndex: Int

    /// Posizione orizzontale normalizzata nell'intervallo da zero a uno.
    let xFraction: Double

    /// Profondità normalizzata nell'intervallo da zero a uno.
    let depth: Double
}
