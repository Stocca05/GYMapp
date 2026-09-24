import Foundation

/// Rappresenta gli errori tipizzati delle operazioni sull'inventario.
nonisolated enum InventoryError: Error, Equatable, Sendable, Codable {
    /// Il lotto richiesto non esiste.
    case itemNotFound(StockItemID)
    /// Il prodotto richiesto non esiste.
    case productNotFound(ProductID)
    /// La ricetta richiesta non esiste.
    case recipeNotFound(RecipeID)
    /// La quantità disponibile del prodotto non è sufficiente.
    case insufficientStock(ProductID)
    /// Il comando contiene una o più violazioni di validazione.
    case validation([ValidationIssue])
    /// La persistenza ha restituito un errore tecnico.
    case persistence(message: String)
}
