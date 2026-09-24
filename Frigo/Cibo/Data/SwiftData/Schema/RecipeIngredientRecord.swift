import Foundation
import SwiftData

/// Modello SwiftData privato di un ingrediente conservato nello storico ricette.
@Model final class RecipeIngredientRecord {
    @Attribute(.unique) var id: UUID
    var recipe: RecipeRecord?
    var productID: UUID
    var productName: String
    var unitRaw: String
    var quantity: Int

    /// Crea un record ingrediente senza logica di dominio.
    init(id: UUID, recipe: RecipeRecord?, productID: UUID, productName: String, unitRaw: String, quantity: Int) {
        self.id = id
        self.recipe = recipe
        self.productID = productID
        self.productName = productName
        self.unitRaw = unitRaw
        self.quantity = quantity
    }
}
