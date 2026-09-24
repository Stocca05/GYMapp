import Foundation

/// Raccoglie i dati di un piatto appena cucinato e dei suoi consumi reali.
nonisolated struct CookedMealDraft: Sendable, Hashable, Codable {
    /// Nome del piatto cucinato.
    let name: String
    /// Numero di porzioni preparate.
    let servings: Int
    /// Ingredienti prelevati dalla dispensa.
    let ingredients: [CookedIngredientDraft]
    /// Immagine elaborata opzionale del piatto.
    let imageData: Data?
    /// Miniatura elaborata opzionale del piatto.
    let thumbnailData: Data?

    /// Restituisce le violazioni deterministiche del piatto.
    var validationIssues: [ValidationIssue] {
        var issues: [ValidationIssue] = []
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.emptyName) }
        if name.count > 120 { issues.append(.nameTooLong) }
        if servings <= 0 || ingredients.contains(where: { $0.quantity <= 0 }) { issues.append(.nonPositiveQuantity) }
        if ingredients.isEmpty { issues.append(.missingIngredients) }
        let stockIDs = ingredients.compactMap(\.stockItemID)
        if Set(stockIDs).count != stockIDs.count { issues.append(.duplicateIngredient) }
        return issues
    }
}

/// Rappresenta la quantità di un singolo prodotto usata per cucinare.
nonisolated struct CookedIngredientDraft: Sendable, Hashable, Codable {
    /// Prodotto usato.
    let productID: ProductID
    /// Confezione specifica da cui prelevare, se scelta dall'utente.
    var stockItemID: StockItemID? = nil
    /// Quantità consumata nella sua unità base.
    let quantity: Int

}
