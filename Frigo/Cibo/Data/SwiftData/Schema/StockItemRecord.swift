import Foundation
import SwiftData

/// Modello SwiftData privato della persistenza di un lotto.
@Model final class StockItemRecord {
    @Attribute(.unique) var id: UUID
    var product: ProductRecord?
    var initialQuantity: Int; var currentQuantity: Int; var expirationDate: Date; var isOpen: Bool; var openedDate: Date?
    var locationRaw: String; var shelfIndex: Int; var xFraction: Double; var depth: Double; var statusRaw: String; var createdAt: Date; var closedAt: Date?

    /// Crea un record lotto senza logica di dominio.
    init(id: UUID, product: ProductRecord?, initialQuantity: Int, currentQuantity: Int, expirationDate: Date, isOpen: Bool, openedDate: Date?, locationRaw: String, shelfIndex: Int, xFraction: Double, depth: Double, statusRaw: String, createdAt: Date, closedAt: Date?) {
        self.id = id; self.product = product; self.initialQuantity = initialQuantity; self.currentQuantity = currentQuantity
        self.expirationDate = expirationDate; self.isOpen = isOpen; self.openedDate = openedDate; self.locationRaw = locationRaw
        self.shelfIndex = shelfIndex; self.xFraction = xFraction; self.depth = depth; self.statusRaw = statusRaw; self.createdAt = createdAt; self.closedAt = closedAt
    }
}
