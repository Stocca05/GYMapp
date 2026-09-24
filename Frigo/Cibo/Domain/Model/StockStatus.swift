import Foundation

/// Descrive il ciclo di vita di un lotto.
nonisolated enum StockStatus: String, Codable, CaseIterable, Sendable, Identifiable {
    /// Lotto disponibile in inventario.
    case active
    /// Lotto completamente consumato.
    case consumed
    /// Lotto scartato.
    case discarded

    /// Identificatore stabile dello stato.
    var id: Self { self }
}
