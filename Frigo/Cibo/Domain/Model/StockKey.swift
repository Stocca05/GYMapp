import Foundation

/// Rappresenta la chiave con cui è lecito aggregare quantità di stock.
nonisolated struct StockKey: Hashable, Sendable, Codable {
    /// Categoria merceologica condivisa.
    let category: ProductCategory

    /// Unità di misura condivisa.
    let unit: UnitOfMeasure
}
