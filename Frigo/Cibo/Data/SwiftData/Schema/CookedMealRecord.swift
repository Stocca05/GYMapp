import Foundation
import SwiftData

/// Modello SwiftData privato di una singola preparazione nello storico.
@Model final class CookedMealRecord {
    @Attribute(.unique) var id: UUID
    var recipeID: UUID
    var name: String
    var servings: Int
    var thumbnailPNG: Data?
    @Attribute(.externalStorage) var fullImagePNG: Data?
    var cookedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \CookedMealIngredientRecord.cookedMeal) var ingredients: [CookedMealIngredientRecord] = []

    /// Crea un record preparazione senza logica di dominio.
    init(id: UUID, recipeID: UUID, name: String, servings: Int, thumbnailPNG: Data?, fullImagePNG: Data?, cookedAt: Date) {
        self.id = id
        self.recipeID = recipeID
        self.name = name
        self.servings = servings
        self.thumbnailPNG = thumbnailPNG
        self.fullImagePNG = fullImagePNG
        self.cookedAt = cookedAt
    }
}
