import Foundation

/// Rappresenta i lotti dello stesso prodotto nella stessa collocazione.
nonisolated struct StockGroup: Sendable, Hashable, Identifiable {
    /// Identificatore del gruppo composto da prodotto e collocazione.
    let id: StockGroupID

    /// Primo lotto nell'ordine FEFO, usato per posizione e presentazione.
    let representative: StockItemSnapshot

    /// Numero di lotti nel gruppo.
    let count: Int

    /// Quantità corrente totale dei lotti nel gruppo.
    let totalQuantity: Int

    /// Quantità iniziale effettiva delle confezioni ancora presenti.
    let totalInitialQuantity: Int

    /// Identificatori dei lotti nel gruppo in ordine FEFO.
    let ids: [StockItemID]

    /// Posizione del lotto rappresentativo.
    let placement: ShelfPlacement

    /// Crea un gruppo di stock.
    ///
    /// - Parameters:
    ///   - id: Identificatore composto da prodotto e collocazione.
    ///   - representative: Primo lotto nell'ordine FEFO.
    ///   - count: Numero di lotti nel gruppo.
    ///   - totalQuantity: Quantità corrente totale.
    ///   - ids: Identificatori dei lotti in ordine FEFO.
    ///   - placement: Posizione del lotto rappresentativo.
    init(
        id: StockGroupID,
        representative: StockItemSnapshot,
        count: Int,
        totalQuantity: Int,
        ids: [StockItemID],
        placement: ShelfPlacement,
        totalInitialQuantity: Int? = nil
    ) {
        self.id = id
        self.representative = representative
        self.count = count
        self.totalQuantity = totalQuantity
        self.totalInitialQuantity = totalInitialQuantity ?? representative.initialQuantity * count
        self.ids = ids
        self.placement = placement
    }
}
