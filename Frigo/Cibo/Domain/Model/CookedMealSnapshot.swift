import Foundation

/// Espone una preparazione realmente cucinata nello storico personale.
nonisolated struct CookedMealSnapshot: Sendable, Hashable, Identifiable, Codable {
    /// Identificatore stabile della preparazione.
    let id: UUID
    /// Ricetta personale aggiornata dalla preparazione.
    let recipeID: RecipeID
    /// Nome del piatto al momento della preparazione.
    let name: String
    /// Porzioni preparate.
    let servings: Int
    /// Ingredienti e quantità realmente consumati.
    let ingredients: [RecipeIngredientSnapshot]
    /// Miniatura opzionale del piatto.
    let thumbnailPNG: Data?
    /// Istante in cui il piatto è stato cucinato.
    let cookedAt: Date
}
