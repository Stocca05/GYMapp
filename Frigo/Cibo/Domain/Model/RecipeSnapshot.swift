import Foundation

/// Espone una ricetta nata da un piatto effettivamente cucinato.
nonisolated struct RecipeSnapshot: Sendable, Hashable, Identifiable, Codable {
    /// Identificatore stabile della ricetta.
    let id: RecipeID
    /// Nome scelto al momento della preparazione.
    let name: String
    /// Numero di porzioni dell'ultima preparazione.
    let servings: Int
    /// Ingredienti e quantità usate nella preparazione.
    let ingredients: [RecipeIngredientSnapshot]
    /// Miniatura opzionale del piatto.
    let thumbnailPNG: Data?
    /// Data della prima preparazione.
    let createdAt: Date
    /// Data dell'ultima preparazione.
    let lastCookedAt: Date
    /// Numero di volte in cui il piatto è stato cucinato.
    let timesCooked: Int
}

/// Descrive un ingrediente effettivamente usato in una ricetta personale.
nonisolated struct RecipeIngredientSnapshot: Sendable, Hashable, Identifiable, Codable {
    /// Identificatore del prodotto usato.
    let productID: ProductID
    /// Nome conservato per mantenere leggibile lo storico.
    let productName: String
    /// Unità della quantità.
    let unit: UnitOfMeasure
    /// Quantità usata.
    let quantity: Int

    /// Identificatore del prodotto usato da SwiftUI.
    var id: ProductID { productID }
}
