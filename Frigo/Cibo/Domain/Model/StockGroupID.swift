import Foundation

/// Identifica un gruppo di stock dello stesso prodotto nella stessa collocazione.
nonisolated struct StockGroupID: Hashable, Sendable, Codable {
    /// Prodotto a cui appartiene il gruppo.
    let productID: ProductID

    /// Collocazione fisica del gruppo.
    let location: StorageLocation
}
