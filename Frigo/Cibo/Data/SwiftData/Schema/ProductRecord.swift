import Foundation
import SwiftData

/// Modello SwiftData privato della persistenza di un prodotto.
@Model final class ProductRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRaw: String
    var baseUnitRaw: String
    var defaultShelfLifeDays: Int?
    var openShelfLifeDays: Int?
    var defaultQuantityPerPackage: Int?
    var displayScale: Double
    var imageAspectRatio: Double
    var thumbnailPNG: Data?
    @Attribute(.externalStorage) var fullImagePNG: Data?
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \StockItemRecord.product) var items: [StockItemRecord] = []

    /// Crea un record prodotto senza logica di dominio.
    init(id: UUID, name: String, categoryRaw: String, baseUnitRaw: String, defaultShelfLifeDays: Int?, openShelfLifeDays: Int?, defaultQuantityPerPackage: Int?, displayScale: Double, imageAspectRatio: Double, thumbnailPNG: Data?, fullImagePNG: Data?, createdAt: Date) {
        self.id = id; self.name = name; self.categoryRaw = categoryRaw; self.baseUnitRaw = baseUnitRaw
        self.defaultShelfLifeDays = defaultShelfLifeDays; self.openShelfLifeDays = openShelfLifeDays
        self.defaultQuantityPerPackage = defaultQuantityPerPackage
        self.displayScale = displayScale; self.imageAspectRatio = imageAspectRatio; self.thumbnailPNG = thumbnailPNG
        self.fullImagePNG = fullImagePNG; self.createdAt = createdAt
    }
}
