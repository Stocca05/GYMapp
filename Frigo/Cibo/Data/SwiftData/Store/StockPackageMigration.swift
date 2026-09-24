import Foundation
import SwiftData

/// Separa i vecchi lotti aggregati usando il formato salvato sul prodotto.
nonisolated enum StockPackageMigration {
    /// Mantiene quantità, scadenze e stato di apertura; esecuzioni successive non duplicano i pezzi.
    static func normalize(in context: ModelContext) throws {
        do {
            let records = try context.fetch(FetchDescriptor<StockItemRecord>())
            for record in records where record.statusRaw == StockStatus.active.rawValue {
                guard let size = record.product?.defaultQuantityPerPackage, size > 0,
                      record.initialQuantity > size, record.initialQuantity % size == 0,
                      record.currentQuantity > 0, record.currentQuantity <= record.initialQuantity else { continue }
                let count = record.initialQuantity / size
                var remaining = record.currentQuantity
                // Conserva l'identità originale sulla confezione ancora disponibile, anche se parziale.
                let firstQuantity = remaining % size == 0 ? min(size, remaining) : remaining % size
                remaining -= firstQuantity
                for _ in 1..<count {
                    let quantity = min(size, remaining)
                    remaining -= quantity
                    let item = StockItemRecord(id: UUID(), product: record.product,
                        initialQuantity: size, currentQuantity: quantity, expirationDate: record.expirationDate,
                        isOpen: record.isOpen, openedDate: record.openedDate, locationRaw: record.locationRaw,
                        shelfIndex: record.shelfIndex, xFraction: record.xFraction, depth: record.depth,
                        statusRaw: quantity > 0 ? StockStatus.active.rawValue : StockStatus.consumed.rawValue,
                        createdAt: record.createdAt, closedAt: record.closedAt)
                    context.insert(item)
                }
                record.initialQuantity = size
                record.currentQuantity = firstQuantity
            }
            if context.hasChanges { try context.save() }
        } catch {
            context.rollback()
            throw InventoryError.persistence(message: String(describing: error))
        }
    }
}
