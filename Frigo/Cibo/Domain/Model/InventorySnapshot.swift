import Foundation

/// Rappresenta una vista coerente e immutabile dell'inventario.
nonisolated struct InventorySnapshot: Sendable, Hashable, Codable {
    /// Revisione monotona usata per individuare dati obsoleti.
    let revision: Int

    /// Tutti i prodotti, inclusi quelli senza lotti attivi.
    let products: [ProductSnapshot]

    /// Soltanto i lotti con stato active.
    let items: [StockItemSnapshot]

    /// Ricette personali nate da piatti già cucinati.
    let recipes: [RecipeSnapshot]

    /// Storico delle preparazioni effettuate.
    let cookedMeals: [CookedMealSnapshot]

    /// Crea uno snapshot dell'inventario.
    ///
    /// - Parameters:
    ///   - revision: Revisione monotona dello snapshot.
    ///   - products: Tutti i prodotti del catalogo.
    ///   - items: Soltanto i lotti attivi.
    init(
        revision: Int,
        products: [ProductSnapshot],
        items: [StockItemSnapshot],
        recipes: [RecipeSnapshot] = [],
        cookedMeals: [CookedMealSnapshot] = []
    ) {
        self.revision = revision
        self.products = products
        self.items = items.filter { $0.status == .active && $0.currentQuantity > 0 }
        self.recipes = recipes
        self.cookedMeals = cookedMeals
    }

    /// Restituisce i lotti attivi nella collocazione indicata.
    ///
    /// - Parameter location: Collocazione da filtrare.
    /// - Returns: Lotti presenti nella collocazione richiesta.
    func items(in location: StorageLocation) -> [StockItemSnapshot] {
        items.filter { $0.location == location }
    }

    /// Cerca un prodotto per identificatore.
    ///
    /// - Parameter id: Identificatore del prodotto cercato.
    /// - Returns: Il prodotto, se presente nello snapshot.
    func product(for id: ProductID) -> ProductSnapshot? {
        products.first { $0.id == id }
    }

    /// Raggruppa la disponibilità corrente per prodotto in un solo passaggio.
    ///
    /// - Returns: Quantità attiva totale per ogni prodotto.
    func availableQuantities() -> [ProductID: Int] {
        items.reduce(into: [:]) { result, item in
            result[item.productID, default: 0] += item.currentQuantity
        }
    }
}
