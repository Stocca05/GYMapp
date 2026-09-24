import Foundation
import Testing
@testable import Frigo

/// Verifica l'aggiunta e lo spostamento degli alimenti nello store SwiftData.
struct SwiftDataInventoryStoreTests {
    /// Ogni confezione è indipendente, ma viene mostrata nello stesso gruppo.
    @Test func addProductCreatesIndividualPackages() async throws {
        let store = try await makeStore()
        let itemID = try await store.addProduct(makeProductDraft())
        let snapshot = try await store.snapshot()
        #expect(snapshot.items.contains { $0.id == itemID })
        #expect(snapshot.items.count == 3)
        #expect(snapshot.items.allSatisfy { $0.currentQuantity == 1_000 })
        let group = try #require(ShelfGrouping.group(items: snapshot.items).first)
        #expect(group.count == 3)
        #expect(group.totalQuantity == 3_000)
    }

    /// Verifica lo spostamento di un prodotto nel frigorifero.
    @Test func moveClampsPlacement() async throws {
        let store = try await makeStore()
        let itemID = try await store.addProduct(makeProductDraft())
        try await store.move([itemID], to: ShelfPlacement(shelfIndex: 99, xFraction: -1, depth: 2))
        let item = try #require(try await store.snapshot().items.first { $0.id == itemID })
        #expect(item.placement.shelfIndex == StorageLocation.fridge.defaultShelfCount - 1)
        #expect(item.placement.xFraction == 0)
        #expect(item.placement.depth == 1)
    }

    /// Verifica il trasferimento di un alimento tra le collocazioni disponibili.
    @Test func moveTransfersItemToAnotherLocation() async throws {
        let store = try await makeStore()
        let itemID = try await store.addProduct(makeProductDraft())

        try await store.move([itemID], to: .pantry)

        let snapshot = try await store.snapshot()
        let item = try #require(snapshot.items.first { $0.id == itemID })
        #expect(item.location == .pantry)
        #expect(snapshot.items(in: .fridge).count == 2)
        #expect(snapshot.items.reduce(0) { $0 + $1.currentQuantity } == 3_000)
        #expect((0..<StorageLocation.pantry.defaultShelfCount).contains(item.placement.shelfIndex))
    }

    /// Verifica che una seconda aggiunta riusi quantità e durata salvate sul prodotto.
    @Test func addStockReusesSavedProductDefaults() async throws {
        let store = try await makeStore()
        _ = try await store.addProduct(makeProductDraft())
        let product = try #require(try await store.snapshot().products.first)

        _ = try await store.addStock(productID: product.id, packageCount: 2, location: .pantry)
        let addedItem = try #require(try await store.snapshot().items.first { $0.location == .pantry })

        #expect(addedItem.currentQuantity == 1_000)
        #expect(try await store.snapshot().items(in: .pantry).count == 2)
        #expect(addedItem.expirationDate > addedItem.createdAt)
    }

    /// Verifica che cucinare un piatto consumi ingredienti e crei la ricetta personale.
    @Test func cookingConsumesIngredientsAndSavesRecipe() async throws {
        let store = try await makeStore()
        _ = try await store.addProduct(makeProductDraft())
        let product = try #require(try await store.snapshot().products.first)

        let recipeID = try await store.cook(CookedMealDraft(name: "Pasta al latte", servings: 2, ingredients: [CookedIngredientDraft(productID: product.id, quantity: 1_500)], imageData: nil, thumbnailData: nil))
        let snapshot = try await store.snapshot()
        let recipe = try #require(snapshot.recipes.first { $0.id == recipeID })

        #expect(snapshot.items.reduce(0) { $0 + $1.currentQuantity } == 1_500)
        #expect(snapshot.items.count == 2)
        let opened = try #require(snapshot.items.first { $0.isOpen })
        #expect(opened.currentQuantity == 500)
        let closed = try #require(snapshot.items.first { !$0.isOpen })
        #expect(opened.expirationDate < closed.expirationDate)
        #expect(recipe.timesCooked == 1)
        #expect(recipe.ingredients == [RecipeIngredientSnapshot(productID: product.id, productName: "Latte", unit: .milliliters, quantity: 1_500)])
        #expect(snapshot.cookedMeals.first?.ingredients == recipe.ingredients)
    }

    /// Spostare la confezione aperta non deve spostare le altre o alterarne i dati.
    @Test func movingOpenedPackagePreservesContentsAndExpiry() async throws {
        let store = try await makeStore()
        let id = try await store.addProduct(makeProductDraft())
        let before = try #require(try await store.snapshot().items.first { $0.id == id })
        _ = try await store.cook(CookedMealDraft(name: "Latte caldo", servings: 1,
            ingredients: [CookedIngredientDraft(productID: before.productID, stockItemID: id, quantity: 250)], imageData: nil, thumbnailData: nil))
        let opened = try #require(try await store.snapshot().items.first { $0.id == id })
        try await store.move([id], to: .freezer)
        let snapshot = try await store.snapshot()
        let moved = try #require(snapshot.items(in: .freezer).first)
        #expect(moved.id == id)
        #expect(moved.currentQuantity == 750)
        #expect(moved.isOpen)
        #expect(moved.expirationDate == opened.expirationDate)
        #expect(moved.openedDate == opened.openedDate)
        #expect(snapshot.items(in: .fridge).count == 2)
    }

    /// Se una selezione non è più valida, nessuna delle altre confezioni viene trasferita.
    @Test func invalidTransferDoesNotPartiallyMoveStock() async throws {
        let store = try await makeStore()
        let id = try await store.addProduct(makeProductDraft())
        let before = try await store.snapshot()
        do {
            try await store.move([id, StockItemID(rawValue: UUID())], to: .pantry)
            Issue.record("Il lotto inesistente deve far fallire il trasferimento")
        } catch is InventoryError { }
        let after = try await store.snapshot()
        #expect(Set(after.items) == Set(before.items))
        #expect(after.revision == before.revision)
    }

    /// Un consumo combinato eccessivo deve ripristinare anche le confezioni già toccate.
    @Test func failedCookingRollsBackAllPackages() async throws {
        let store = try await makeStore()
        let id = try await store.addProduct(makeProductDraft())
        let before = try await store.snapshot()
        let product = try #require(before.products.first)
        do {
            _ = try await store.cook(CookedMealDraft(name: "Troppo latte", servings: 1,
                ingredients: [CookedIngredientDraft(productID: product.id, stockItemID: id, quantity: 1_000),
                              CookedIngredientDraft(productID: product.id, quantity: 2_500)], imageData: nil, thumbnailData: nil))
            Issue.record("La quantità combinata supera quella disponibile")
        } catch is InventoryError { }
        let after = try await store.snapshot()
        #expect(Set(after.items) == Set(before.items))
        #expect(after.recipes.isEmpty)
        #expect(after.cookedMeals.isEmpty)
        // Un salvataggio successivo non deve committare consumi rimasti in sospeso.
        try await store.move([id], to: .pantry)
        #expect(try await store.snapshot().items.reduce(0) { $0 + $1.currentQuantity } == 3_000)
    }

    /// Tutte le confezioni selezionate arrivano a destinazione e si raggruppano con quelle presenti.
    @Test func transferMergesGroupsWithoutMergingPackages() async throws {
        let store = try await makeStore()
        _ = try await store.addProduct(makeProductDraft())
        let product = try #require(try await store.snapshot().products.first)
        _ = try await store.addStock(productID: product.id, packageCount: 2, location: .pantry)
        let ids = try await store.snapshot().items(in: .fridge).map(\.id)
        try await store.move(ids, to: .pantry)
        let snapshot = try await store.snapshot()
        #expect(snapshot.items(in: .fridge).isEmpty)
        #expect(snapshot.items(in: .pantry).count == 5)
        let groups = ShelfGrouping.group(items: snapshot.items)
        #expect(groups.count == 1)
        #expect(groups.first?.count == 5)
        #expect(groups.first?.totalQuantity == 5_000)
    }

    /// Il consumo diretto aggiorna solo la confezione scelta e non crea un piatto.
    @Test func directConsumptionOpensOnlySelectedPackage() async throws {
        let store = try await makeStore()
        let id = try await store.addProduct(makeProductDraft())
        let before = try await store.snapshot()
        try await store.consume(id, quantity: 250)
        let after = try await store.snapshot()
        let item = try #require(after.items.first { $0.id == id })
        #expect(item.currentQuantity == 750)
        #expect(item.isOpen)
        #expect(item.openedDate != nil)
        #expect(item.expirationDate < (try #require(before.items.first { $0.id == id })).expirationDate)
        #expect(Set(after.items.filter { $0.id != id }) == Set(before.items.filter { $0.id != id }))
        #expect(after.recipes.isEmpty)
        #expect(after.cookedMeals.isEmpty)
    }

    /// Terminare una confezione la rimuove dalla scorta attiva e impedisce consumi ulteriori.
    @Test func directConsumptionFinishesSinglePackage() async throws {
        let store = try await makeStore()
        let id = try await store.addProduct(makeProductDraft())
        try await store.consume(id, quantity: 1_000)
        let after = try await store.snapshot()
        #expect(after.items.count == 2)
        #expect(!after.items.contains { $0.id == id })
        do {
            try await store.consume(id, quantity: 1)
            Issue.record("La confezione terminata non deve essere consumabile")
        } catch is InventoryError { }
        #expect(Set(try await store.snapshot().items) == Set(after.items))
    }

    /// Quantità non valide non devono cambiare le scorte, neppure dopo un salvataggio successivo.
    @Test func invalidDirectConsumptionLeavesStockUnchanged() async throws {
        let store = try await makeStore()
        let id = try await store.addProduct(makeProductDraft())
        let before = try await store.snapshot()
        for quantity in [-1, 0, 1_001] {
            do {
                try await store.consume(id, quantity: quantity)
                Issue.record("Il consumo non valido deve essere rifiutato")
            } catch is InventoryError { }
        }
        #expect(Set(try await store.snapshot().items) == Set(before.items))
        try await store.consume(id, quantity: 100)
        #expect(try await store.snapshot().items.reduce(0) { $0 + $1.currentQuantity } == 2_900)
    }

    private func makeStore() async throws -> SwiftDataInventoryStore {
        let container = try await CiboContainerFactory.make(inMemory: true)
        return try await SwiftDataInventoryStore.makeOffMainActor(modelContainer: container, dateProvider: FixedDateProvider(now: Date(timeIntervalSince1970: 1_735_689_600)), calendar: .current)
    }

    private func makeProductDraft() -> NewProductDraft {
        NewProductDraft(name: "Latte", category: .dairy, baseUnit: .milliliters, packageCount: 3, quantityPerPackage: 1_000, location: .fridge, shelfLifeDays: 5, expirationDate: nil, openShelfLifeDays: 2, displayScale: 1, imageData: nil)
    }
}
