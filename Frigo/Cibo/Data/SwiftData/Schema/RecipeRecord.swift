import Foundation
import SwiftData

/// Modello SwiftData privato di una ricetta personale.
@Model final class RecipeRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var servings: Int
    var thumbnailPNG: Data?
    @Attribute(.externalStorage) var fullImagePNG: Data?
    var createdAt: Date
    var lastCookedAt: Date
    var timesCooked: Int
    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredientRecord.recipe) var ingredients: [RecipeIngredientRecord] = []

    /// Crea un record ricetta senza logica di dominio.
    init(id: UUID, name: String, servings: Int, thumbnailPNG: Data?, fullImagePNG: Data?, createdAt: Date, lastCookedAt: Date, timesCooked: Int) {
        self.id = id
        self.name = name
        self.servings = servings
        self.thumbnailPNG = thumbnailPNG
        self.fullImagePNG = fullImagePNG
        self.createdAt = createdAt
        self.lastCookedAt = lastCookedAt
        self.timesCooked = timesCooked
    }
}
