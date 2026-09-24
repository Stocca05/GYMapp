import Foundation

/// Espone i dati immutabili di un lotto al di fuori della persistenza.
nonisolated struct StockItemSnapshot: Sendable, Hashable, Identifiable, Codable {
    /// Identificatore del lotto.
    let id: StockItemID

    /// Identificatore del prodotto associato.
    let productID: ProductID

    /// Chiave di aggregazione denormalizzata al momento della lettura.
    let key: StockKey

    /// Quantità presente alla creazione del lotto.
    let initialQuantity: Int

    /// Quantità attualmente disponibile.
    let currentQuantity: Int

    /// Data di scadenza del lotto.
    let expirationDate: Date

    /// Indica se il lotto è stato aperto.
    let isOpen: Bool

    /// Data di apertura, se il lotto è stato aperto.
    let openedDate: Date?

    /// Collocazione fisica del lotto.
    let location: StorageLocation

    /// Posizione visuale del lotto sul ripiano.
    let placement: ShelfPlacement

    /// Stato del ciclo di vita del lotto.
    let status: StockStatus

    /// Data di creazione del lotto.
    let createdAt: Date

    /// Data di chiusura del lotto, se concluso.
    let closedAt: Date?
}
