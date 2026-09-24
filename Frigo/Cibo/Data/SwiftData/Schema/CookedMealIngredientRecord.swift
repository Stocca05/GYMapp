import Foundation
import SwiftData

/// Modello SwiftData privato di un ingrediente usato in una preparazione storica.
@Model final class CookedMealIngredientRecord {
    @Attribute(.unique) var id: UUID
    var cookedMeal: CookedMealRecord?
    var productID: UUID
    var productName: String
    var unitRaw: String
    var quantity: Int

    /// Crea un record ingrediente senza logica di dominio.
    init(id: UUID, cookedMeal: CookedMealRecord?, productID: UUID, productName: String, unitRaw: String, quantity: Int) {
        self.id = id
        self.cookedMeal = cookedMeal
        self.productID = productID
        self.productName = productName
        self.unitRaw = unitRaw
        self.quantity = quantity
    }
}
