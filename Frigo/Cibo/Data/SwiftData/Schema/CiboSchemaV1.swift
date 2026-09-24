import Foundation
import SwiftData

/// Definisce lo schema originale, mantenuto per migrare i dati già salvati.
enum CiboSchemaV1: VersionedSchema {
    /// Identificatore della prima versione dello schema.
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    /// Modelli inclusi nella prima versione dello schema.
    static var models: [any PersistentModel.Type] { [ProductRecord.self, StockItemRecord.self, RecipeRecord.self, MealRecord.self, RecipeRequirementRecord.self] }

    /// Modello prodotto precedente all'aggiunta della confezione standard.
    @Model final class ProductRecord {
        @Attribute(.unique) var id: UUID
        var name: String
        var categoryRaw: String
        var baseUnitRaw: String
        var defaultShelfLifeDays: Int?
        var openShelfLifeDays: Int?
        var displayScale: Double
        var imageAspectRatio: Double
        var thumbnailPNG: Data?
        @Attribute(.externalStorage) var fullImagePNG: Data?
        var createdAt: Date
        @Relationship(deleteRule: .cascade, inverse: \StockItemRecord.product) var items: [StockItemRecord] = []

        init(id: UUID, name: String, categoryRaw: String, baseUnitRaw: String, defaultShelfLifeDays: Int?, openShelfLifeDays: Int?, displayScale: Double, imageAspectRatio: Double, thumbnailPNG: Data?, fullImagePNG: Data?, createdAt: Date) {
            self.id = id; self.name = name; self.categoryRaw = categoryRaw; self.baseUnitRaw = baseUnitRaw
            self.defaultShelfLifeDays = defaultShelfLifeDays; self.openShelfLifeDays = openShelfLifeDays
            self.displayScale = displayScale; self.imageAspectRatio = imageAspectRatio; self.thumbnailPNG = thumbnailPNG
            self.fullImagePNG = fullImagePNG; self.createdAt = createdAt
        }
    }

    /// Modello lotto originale, invariato nella migrazione.
    @Model final class StockItemRecord {
        @Attribute(.unique) var id: UUID
        var product: ProductRecord?
        var initialQuantity: Int; var currentQuantity: Int; var expirationDate: Date; var isOpen: Bool; var openedDate: Date?
        var locationRaw: String; var shelfIndex: Int; var xFraction: Double; var depth: Double; var statusRaw: String; var createdAt: Date; var closedAt: Date?

        init(id: UUID, product: ProductRecord?, initialQuantity: Int, currentQuantity: Int, expirationDate: Date, isOpen: Bool, openedDate: Date?, locationRaw: String, shelfIndex: Int, xFraction: Double, depth: Double, statusRaw: String, createdAt: Date, closedAt: Date?) {
            self.id = id; self.product = product; self.initialQuantity = initialQuantity; self.currentQuantity = currentQuantity
            self.expirationDate = expirationDate; self.isOpen = isOpen; self.openedDate = openedDate; self.locationRaw = locationRaw
            self.shelfIndex = shelfIndex; self.xFraction = xFraction; self.depth = depth; self.statusRaw = statusRaw; self.createdAt = createdAt; self.closedAt = closedAt
        }
    }

    /// Ricetta della versione originale, mantenuta solo per riconoscere lo store esistente.
    @Model final class RecipeRecord {
        @Attribute(.unique) var id: UUID
        var name: String
        @Relationship(deleteRule: .cascade, inverse: \RecipeRequirementRecord.recipe) var requirements: [RecipeRequirementRecord] = []

        init(id: UUID, name: String) {
            self.id = id
            self.name = name
        }
    }

    /// Piatto cucinato della versione originale, mantenuto per la migrazione.
    @Model final class MealRecord {
        @Attribute(.unique) var id: UUID
        var name: String
        var createdAt: Date
        var photoData: Data?
        var usagesData: Data?

        init(id: UUID, name: String, createdAt: Date, photoData: Data?, usagesData: Data?) {
            self.id = id
            self.name = name
            self.createdAt = createdAt
            self.photoData = photoData
            self.usagesData = usagesData
        }
    }

    /// Requisito della ricetta nella versione originale.
    @Model final class RecipeRequirementRecord {
        @Attribute(.unique) var id: UUID
        var recipe: RecipeRecord?
        var amount: Int
        var categoryRaw: String
        var unitRaw: String

        init(id: UUID, recipe: RecipeRecord?, amount: Int, categoryRaw: String, unitRaw: String) {
            self.id = id
            self.recipe = recipe
            self.amount = amount
            self.categoryRaw = categoryRaw
            self.unitRaw = unitRaw
        }
    }
}
