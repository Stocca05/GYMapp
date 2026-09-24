import Foundation

/// Raggruppa lotti destinati alla stessa posizione logica sullo scaffale.
nonisolated struct ShelfGrouping {
    /// Produce un gruppo per coppia prodotto-collocazione in ordine FEFO stabile.
    ///
    /// - Parameter items: Lotti da raggruppare.
    /// - Returns: Gruppi ordinati dal rispettivo lotto rappresentativo.
    static func group(items: [StockItemSnapshot]) -> [StockGroup] {
        let grouped = Dictionary(grouping: items.filter { $0.status == .active && $0.currentQuantity > 0 }) {
            StockGroupID(productID: $0.productID, location: $0.location)
        }

        return grouped.compactMap { id, members -> StockGroup? in
            let ordered = members.sorted(by: isOrderedBefore)
            guard let representative = ordered.first else {
                return nil
            }

            return StockGroup(
                id: id,
                representative: representative,
                count: ordered.count,
                totalQuantity: ordered.reduce(0) { $0 + $1.currentQuantity },
                ids: ordered.map(\.id),
                placement: representative.placement,
                totalInitialQuantity: ordered.reduce(0) { $0 + $1.initialQuantity }
            )
        }
        .sorted {
            isOrderedBefore($0.representative, $1.representative)
        }
    }

    /// Ordina per scadenza, confezione aperta e identificatore stabile.
    static func isOrderedBefore(_ lhs: StockItemSnapshot, _ rhs: StockItemSnapshot) -> Bool {
        if lhs.expirationDate != rhs.expirationDate { return lhs.expirationDate < rhs.expirationDate }
        if lhs.isOpen != rhs.isOpen { return lhs.isOpen }
        if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
        return lhs.id.rawValue.uuidString < rhs.id.rawValue.uuidString
    }
}
