import Foundation
import SwiftData
import os

/// Implementa il repository con un unico actor proprietario di SwiftData.
actor SwiftDataInventoryStore: ModelActor, InventoryRepository {
    nonisolated let modelExecutor: any ModelExecutor
    nonisolated let modelContainer: ModelContainer
    private let dateProvider: any DateProviding
    private let calendar: Calendar
    private var revision = 0
    private var continuations: [UUID: AsyncStream<InventorySnapshot>.Continuation] = [:]

    /// Crea uno store configurato; il chiamante deve invocarlo fuori dal main actor.
    ///
    /// - Parameters:
    ///   - modelContainer: Container SwiftData isolato del modulo.
    ///   - dateProvider: Provider dell'istante corrente.
    ///   - calendar: Calendario usato dalle regole pure.
    init(modelContainer: ModelContainer, dateProvider: any DateProviding, calendar: Calendar) {
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
        self.modelContainer = modelContainer
        self.dateProvider = dateProvider
        self.calendar = calendar
    }

    /// Crea lo store da un task distaccato dal main actor.
    ///
    /// - Parameters:
    ///   - modelContainer: Container SwiftData isolato del modulo.
    ///   - dateProvider: Provider dell'istante corrente.
    ///   - calendar: Calendario usato dalle regole pure.
    /// - Returns: Store associato a un executor non principale.
    nonisolated static func makeOffMainActor(modelContainer: ModelContainer, dateProvider: any DateProviding, calendar: Calendar) async throws -> SwiftDataInventoryStore {
        let store = await Task.detached { SwiftDataInventoryStore(modelContainer: modelContainer, dateProvider: dateProvider, calendar: calendar) }.value
        try await store.preparePackages()
        return store
    }

    private func preparePackages() throws {
        try StockPackageMigration.normalize(in: modelContext)
    }

    /// Osserva lo snapshot corrente e tutti i commit futuri.
    func observe() -> AsyncStream<InventorySnapshot> {
        let identifier = UUID()
        let stream = AsyncStream<InventorySnapshot>(bufferingPolicy: .bufferingNewest(1)) { continuation in
            continuations[identifier] = continuation
            do { continuation.yield(try makeSnapshot()) } catch { CiboLog.persistence.error("Unable to create initial inventory snapshot") }
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(identifier) }
            }
        }
        return stream
    }

    /// Restituisce lo snapshot corrente.
    func snapshot() throws -> InventorySnapshot { try makeSnapshot() }

    /// Crea un prodotto e la sua prima confezione in un unico commit.
    func addProduct(_ draft: NewProductDraft) throws -> StockItemID {
        try validate(draft.validationIssues)
        let now = dateProvider.now
        let productID = UUID(); let itemID = UUID()
        let expiration = ExpirationPolicy.initialExpiration(addedOn: now, shelfLifeDays: draft.shelfLifeDays, overrideDate: draft.expirationDate, calendar: calendar)
        let placement = ShelfPlacementPolicy.autoPlace(location: draft.location, occupied: try occupiedPlacements(in: draft.location))
        let product = ProductRecord(id: productID, name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines), categoryRaw: draft.category.rawValue, baseUnitRaw: draft.baseUnit.rawValue, defaultShelfLifeDays: draft.shelfLifeDays, openShelfLifeDays: draft.openShelfLifeDays, defaultQuantityPerPackage: draft.quantityPerPackage, displayScale: draft.displayScale, imageAspectRatio: 1, thumbnailPNG: draft.thumbnailData, fullImagePNG: draft.imageData, createdAt: now)
        modelContext.insert(product)
        for index in 0..<draft.packageCount {
            let item = StockItemRecord(id: index == 0 ? itemID : UUID(), product: product, initialQuantity: draft.quantityPerPackage, currentQuantity: draft.quantityPerPackage, expirationDate: expiration, isOpen: false, openedDate: nil, locationRaw: draft.location.rawValue, shelfIndex: placement.shelfIndex, xFraction: placement.xFraction, depth: placement.depth, statusRaw: StockStatus.active.rawValue, createdAt: now, closedAt: nil)
            modelContext.insert(item)
        }
        try saveAndPublish()
        return StockItemID(rawValue: itemID)
    }

    /// Aggiunge una confezione usando le impostazioni già salvate sul prodotto.
    func addStock(productID: ProductID, packageCount: Int, location: StorageLocation) throws -> StockItemID {
        guard packageCount > 0 else { throw InventoryError.validation([.nonPositiveQuantity]) }
        guard let product = try productRecord(for: productID) else { throw InventoryError.productNotFound(productID) }
        guard let shelfLifeDays = product.defaultShelfLifeDays, shelfLifeDays > 0 else {
            throw InventoryError.persistence(message: "Missing product shelf life")
        }

        let now = dateProvider.now
        let itemID = UUID()
        let expiration = ExpirationPolicy.initialExpiration(addedOn: now, shelfLifeDays: shelfLifeDays, overrideDate: nil, calendar: calendar)
        let placement = ShelfPlacementPolicy.autoPlace(location: location, occupied: try occupiedPlacements(in: location))
        let quantity = product.defaultQuantityPerPackage ?? 1
        guard quantity > 0 else { throw InventoryError.validation([.nonPositiveQuantity]) }
        for index in 0..<packageCount {
            let item = StockItemRecord(id: index == 0 ? itemID : UUID(), product: product, initialQuantity: quantity, currentQuantity: quantity, expirationDate: expiration, isOpen: false, openedDate: nil, locationRaw: location.rawValue, shelfIndex: placement.shelfIndex, xFraction: placement.xFraction, depth: placement.depth, statusRaw: StockStatus.active.rawValue, createdAt: now, closedAt: nil)
            modelContext.insert(item)
        }
        try saveAndPublish()
        return StockItemID(rawValue: itemID)
    }

    /// Registra una preparazione e sottrae gli ingredienti dai lotti più vicini alla scadenza.
    func cook(_ draft: CookedMealDraft) throws -> RecipeID {
        do { return try commitMeal(draft) }
        catch { modelContext.rollback(); throw error }
    }

    /// Elimina la ricetta e gli ingredienti associati, senza alterare lo storico delle preparazioni.
    func deleteRecipe(_ recipeID: RecipeID) throws {
        do {
            guard let recipe = try recipeRecord(for: recipeID) else { throw InventoryError.recipeNotFound(recipeID) }
            modelContext.delete(recipe)
            try saveAndPublish()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func commitMeal(_ draft: CookedMealDraft) throws -> RecipeID {
        try validate(draft.validationIssues)
        var products: [ProductID: ProductRecord] = [:]
        for productID in Set(draft.ingredients.map(\.productID)) {
            guard let product = try productRecord(for: productID) else { throw InventoryError.productNotFound(productID) }
            products[productID] = product
        }
        for ingredient in draft.ingredients {
            if let stockItemID = ingredient.stockItemID {
                guard let item = try itemRecord(for: stockItemID), item.product?.id == ingredient.productID.rawValue, item.statusRaw == StockStatus.active.rawValue, item.currentQuantity >= ingredient.quantity else {
                    throw InventoryError.insufficientStock(ingredient.productID)
                }
            } else if try availableQuantity(for: ingredient.productID) < ingredient.quantity {
                throw InventoryError.insufficientStock(ingredient.productID)
            }
        }

        let now = dateProvider.now
        // Riserva prima le confezioni esplicite: i prelievi automatici usano ciò che rimane.
        let orderedIngredients = draft.ingredients.sorted { $0.stockItemID != nil && $1.stockItemID == nil }
        for ingredient in orderedIngredients {
            if let stockItemID = ingredient.stockItemID {
                guard let product = products[ingredient.productID] else { throw InventoryError.productNotFound(ingredient.productID) }
                try consume(quantity: ingredient.quantity, from: stockItemID, product: product, at: now)
            } else {
                try consume(quantity: ingredient.quantity, of: ingredient.productID, at: now)
            }
        }

        let normalizedName = normalized(draft.name)
        let recipe = try recipeRecords().first { normalized($0.name) == normalizedName }
            ?? RecipeRecord(id: UUID(), name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines), servings: draft.servings, thumbnailPNG: draft.thumbnailData, fullImagePNG: draft.imageData, createdAt: now, lastCookedAt: now, timesCooked: 0)
        if recipe.timesCooked == 0 { modelContext.insert(recipe) }
        for ingredient in recipe.ingredients { modelContext.delete(ingredient) }
        recipe.servings = draft.servings
        recipe.thumbnailPNG = draft.thumbnailData ?? recipe.thumbnailPNG
        recipe.fullImagePNG = draft.imageData ?? recipe.fullImagePNG
        recipe.lastCookedAt = now
        recipe.timesCooked += 1
        let cookedMeal = CookedMealRecord(id: UUID(), recipeID: recipe.id, name: recipe.name, servings: draft.servings, thumbnailPNG: draft.thumbnailData, fullImagePNG: draft.imageData, cookedAt: now)
        modelContext.insert(cookedMeal)
        let ingredientTotals = Dictionary(grouping: draft.ingredients, by: \.productID).compactMap { productID, ingredients -> (ProductID, Int)? in
            let total = ingredients.reduce(0) { $0 + $1.quantity }
            return total > 0 ? (productID, total) : nil
        }
        for (productID, quantity) in ingredientTotals {
            guard let product = products[productID], let unit = UnitOfMeasure(rawValue: product.baseUnitRaw) else {
                throw InventoryError.persistence(message: "Invalid product unit")
            }
            let record = RecipeIngredientRecord(id: UUID(), recipe: recipe, productID: product.id, productName: product.name, unitRaw: unit.rawValue, quantity: quantity)
            modelContext.insert(record)
            let historicalRecord = CookedMealIngredientRecord(id: UUID(), cookedMeal: cookedMeal, productID: product.id, productName: product.name, unitRaw: unit.rawValue, quantity: quantity)
            modelContext.insert(historicalRecord)
        }
        try saveAndPublish()
        return RecipeID(rawValue: recipe.id)
    }

    /// Sposta tutti i lotti richiesti in un unico commit.
    func move(_ itemIDs: [StockItemID], to placement: ShelfPlacement) throws {
        let records = try itemIDs.map { id -> StockItemRecord in
            guard let record = try itemRecord(for: id) else { throw InventoryError.itemNotFound(id) }
            return record
        }
        for record in records {
            guard let location = StorageLocation(rawValue: record.locationRaw) else { throw InventoryError.persistence(message: "Invalid storage location") }
            let clamped = ShelfPlacementPolicy.clamped(placement, location: location)
            record.shelfIndex = clamped.shelfIndex; record.xFraction = clamped.xFraction; record.depth = clamped.depth
        }
        try saveAndPublish()
    }

    /// Trasferisce tutti i lotti richiesti nella collocazione indicata.
    func move(_ itemIDs: [StockItemID], to location: StorageLocation) throws {
        let records = try Set(itemIDs).map { id -> StockItemRecord in
            guard let record = try itemRecord(for: id), record.statusRaw == StockStatus.active.rawValue, record.currentQuantity > 0 else { throw InventoryError.itemNotFound(id) }
            return record
        }
        guard !records.isEmpty else { return }
        let placement = ShelfPlacementPolicy.autoPlace(location: location, occupied: try occupiedPlacements(in: location))
        for record in records {
            record.locationRaw = location.rawValue
            record.shelfIndex = placement.shelfIndex
            record.xFraction = placement.xFraction
            record.depth = placement.depth
        }
        try saveAndPublish()
    }

    private func removeContinuation(_ identifier: UUID) { continuations.removeValue(forKey: identifier) }

    private func validate(_ issues: [ValidationIssue]) throws {
        guard issues.isEmpty else { throw InventoryError.validation(issues) }
    }

    private func saveAndPublish() throws {
        let snapshot: InventorySnapshot
        do {
            snapshot = try makeSnapshot(revision: revision + 1)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw InventoryError.persistence(message: String(describing: error))
        }
        revision += 1
        for continuation in continuations.values { continuation.yield(snapshot) }
    }

    private func makeSnapshot(revision requestedRevision: Int? = nil) throws -> InventorySnapshot {
        do {
            let products = try modelContext.fetch(FetchDescriptor<ProductRecord>()).compactMap(InventoryMapper.productSnapshot(from:))
            let activeStatus = StockStatus.active.rawValue
            let itemDescriptor = FetchDescriptor<StockItemRecord>(predicate: #Predicate { $0.statusRaw == activeStatus && $0.currentQuantity > 0 })
            let items = try modelContext.fetch(itemDescriptor).compactMap(InventoryMapper.itemSnapshot(from:))
            let recipes = try modelContext.fetch(FetchDescriptor<RecipeRecord>()).compactMap(InventoryMapper.recipeSnapshot(from:))
            let cookedMeals = try modelContext.fetch(FetchDescriptor<CookedMealRecord>()).compactMap(InventoryMapper.cookedMealSnapshot(from:))
            return InventorySnapshot(revision: requestedRevision ?? revision, products: products, items: items, recipes: recipes, cookedMeals: cookedMeals)
        } catch { throw InventoryError.persistence(message: String(describing: error)) }
    }

    private func itemRecord(for itemID: StockItemID) throws -> StockItemRecord? {
        let identifier = itemID.rawValue
        do { return try modelContext.fetch(FetchDescriptor<StockItemRecord>(predicate: #Predicate { $0.id == identifier })).first }
        catch { throw InventoryError.persistence(message: String(describing: error)) }
    }

    private func productRecord(for productID: ProductID) throws -> ProductRecord? {
        let identifier = productID.rawValue
        do { return try modelContext.fetch(FetchDescriptor<ProductRecord>(predicate: #Predicate { $0.id == identifier })).first }
        catch { throw InventoryError.persistence(message: String(describing: error)) }
    }

    private func itemRecords() throws -> [StockItemRecord] {
        do { return try modelContext.fetch(FetchDescriptor<StockItemRecord>()) }
        catch { throw InventoryError.persistence(message: String(describing: error)) }
    }

    private func recipeRecords() throws -> [RecipeRecord] {
        do { return try modelContext.fetch(FetchDescriptor<RecipeRecord>()) }
        catch { throw InventoryError.persistence(message: String(describing: error)) }
    }

    private func recipeRecord(for recipeID: RecipeID) throws -> RecipeRecord? {
        let identifier = recipeID.rawValue
        do { return try modelContext.fetch(FetchDescriptor<RecipeRecord>(predicate: #Predicate { $0.id == identifier })).first }
        catch { throw InventoryError.persistence(message: String(describing: error)) }
    }

    private func availableQuantity(for productID: ProductID) throws -> Int {
        let activeStatus = StockStatus.active.rawValue
        let targetID = productID.rawValue
        let descriptor = FetchDescriptor<StockItemRecord>(predicate: #Predicate { $0.statusRaw == activeStatus && $0.product?.id == targetID })
        return try modelContext.fetch(descriptor).reduce(0) { $0 + $1.currentQuantity }
    }

    private func consume(quantity: Int, of productID: ProductID, at date: Date) throws {
        var remaining = quantity
        let activeStatus = StockStatus.active.rawValue
        let targetID = productID.rawValue
        let descriptor = FetchDescriptor<StockItemRecord>(predicate: #Predicate { $0.statusRaw == activeStatus && $0.product?.id == targetID })
        let records = try modelContext.fetch(descriptor).sorted {
                if $0.expirationDate != $1.expirationDate { return $0.expirationDate < $1.expirationDate }
                if $0.isOpen != $1.isOpen { return $0.isOpen }
                if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
                return $0.id.uuidString < $1.id.uuidString
            }
        for record in records where remaining > 0 {
            let consumed = min(record.currentQuantity, remaining)
            guard let product = record.product else { throw InventoryError.productNotFound(productID) }
            try consume(quantity: consumed, from: StockItemID(rawValue: record.id), product: product, at: date)
            remaining -= consumed
        }
        guard remaining == 0 else { throw InventoryError.insufficientStock(productID) }
    }

    private func consume(quantity: Int, from itemID: StockItemID, product: ProductRecord, at date: Date) throws {
        guard let record = try itemRecord(for: itemID), record.product?.id == product.id, record.statusRaw == StockStatus.active.rawValue, record.currentQuantity >= quantity else {
            throw InventoryError.insufficientStock(ProductID(rawValue: product.id))
        }
        record.currentQuantity -= quantity
        if record.currentQuantity == 0 {
            record.statusRaw = StockStatus.consumed.rawValue
            record.closedAt = date
        } else if record.isOpen == false {
            record.isOpen = true
            record.openedDate = date
            record.expirationDate = ExpirationPolicy.expirationAfterOpening(current: record.expirationDate, openedOn: date, openShelfLifeDays: product.openShelfLifeDays, calendar: calendar)
        }
    }

    /// Registra un consumo diretto, con le stesse regole di apertura usate in cucina.
    func consume(_ itemID: StockItemID, quantity: Int) throws {
        guard quantity > 0 else { throw InventoryError.validation([.nonPositiveQuantity]) }
        guard let item = try itemRecord(for: itemID), let product = item.product else { throw InventoryError.itemNotFound(itemID) }
        do {
            try consume(quantity: quantity, from: itemID, product: product, at: dateProvider.now)
            try saveAndPublish()
        } catch { modelContext.rollback(); throw error }
    }

    private func normalized(_ name: String) -> String {
        name
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
    private func occupiedPlacements(in location: StorageLocation) throws -> [ShelfPlacement] {
        let activeStatus = StockStatus.active.rawValue
        let locationRaw = location.rawValue
        let descriptor = FetchDescriptor<StockItemRecord>(predicate: #Predicate { $0.statusRaw == activeStatus && $0.locationRaw == locationRaw })
        return try modelContext.fetch(descriptor).compactMap { record in
            ShelfPlacement(shelfIndex: record.shelfIndex, xFraction: record.xFraction, depth: record.depth)
        }
    }

}
