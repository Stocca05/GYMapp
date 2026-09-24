import Foundation

/// Definisce l'accesso asincrono all'inventario senza esporre la persistenza.
nonisolated protocol InventoryRepository: Sendable {
    /// Osserva subito lo stato corrente e ogni commit successivo.
    ///
    /// - Returns: Stream di snapshot immutabili.
    func observe() async -> AsyncStream<InventorySnapshot>
    /// Restituisce lo snapshot corrente.
    ///
    /// - Returns: Snapshot immutabile dell'inventario.
    /// - Throws: Propaga errori di persistenza tipizzati.
    func snapshot() async throws -> InventorySnapshot
    /// Crea un prodotto e tutte le sue confezioni indipendenti in un unico commit.
    ///
    /// - Parameter draft: Dati validabili del prodotto e della prima confezione.
    /// - Returns: Identificatore della prima confezione.
    /// - Throws: Propaga errori di validazione o persistenza.
    func addProduct(_ draft: NewProductDraft) async throws -> StockItemID
    /// Aggiunge confezioni indipendenti a un prodotto già presente nel catalogo.
    ///
    /// - Parameters:
    ///   - productID: Prodotto a cui associare la confezione.
    ///   - packageCount: Numero di confezioni o pezzi aggiunti.
    ///   - location: Collocazione della nuova confezione.
    /// - Returns: Identificatore della prima confezione creata.
    /// - Throws: Propaga errori di validazione o persistenza.
    func addStock(productID: ProductID, packageCount: Int, location: StorageLocation) async throws -> StockItemID
    /// Registra un piatto cucinato, scala le quantità e salva o aggiorna la ricetta.
    ///
    /// - Parameter draft: Dati del piatto e ingredienti realmente usati.
    /// - Returns: Identificatore della ricetta personale associata al piatto.
    /// - Throws: Propaga errori di validazione, disponibilità o persistenza.
    func cook(_ draft: CookedMealDraft) async throws -> RecipeID
    /// Elimina una ricetta personale e i suoi ingredienti salvati.
    /// Lo storico dei piatti già cucinati resta disponibile.
    ///
    /// - Parameter recipeID: Identificatore della ricetta da eliminare.
    /// - Throws: Errore se la ricetta non esiste o se il salvataggio non riesce.
    func deleteRecipe(_ recipeID: RecipeID) async throws
    /// Consuma una quantità di una singola confezione senza registrare ricette o piatti.
    /// - Parameters:
    ///   - itemID: Confezione da aggiornare.
    ///   - quantity: Quantità positiva da sottrarre nell'unità base.
    /// - Throws: Errore se la confezione non è disponibile o la quantità è insufficiente.
    func consume(_ itemID: StockItemID, quantity: Int) async throws
    /// Sposta più lotti con un singolo commit.
    ///
    /// - Parameters:
    ///   - itemIDs: Lotti da spostare.
    ///   - placement: Posizione richiesta.
    /// - Throws: Propaga errori di dominio o persistenza.
    func move(_ itemIDs: [StockItemID], to placement: ShelfPlacement) async throws
    /// Trasferisce più lotti in un'altra collocazione e assegna loro una posizione valida.
    ///
    /// - Parameters:
    ///   - itemIDs: Lotti da trasferire.
    ///   - location: Nuova collocazione fisica.
    /// - Throws: Propaga errori di dominio o persistenza.
    func move(_ itemIDs: [StockItemID], to location: StorageLocation) async throws
}
