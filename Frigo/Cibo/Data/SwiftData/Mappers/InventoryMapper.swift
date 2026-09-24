import Foundation
import os

/// Traduce record SwiftData in snapshot Sendable senza esporre i modelli.
nonisolated enum InventoryMapper {
    /// Traduce un record prodotto; categorie sconosciute ricadono su other.
    ///
    /// - Parameter record: Record da tradurre.
    /// - Returns: Snapshot prodotto, oppure nil quando l'unità non è valida.
    static func productSnapshot(from record: ProductRecord) -> ProductSnapshot? {
        guard let unit = UnitOfMeasure(rawValue: record.baseUnitRaw) else {
            CiboLog.persistence.error("Skipping product with unknown unit")
            return nil
        }
        let category = ProductCategory(storedRawValue: record.categoryRaw)
        if category == .other && record.categoryRaw != ProductCategory.other.rawValue {
            CiboLog.persistence.error("Unknown product category mapped to other")
        }
        return ProductSnapshot(id: ProductID(rawValue: record.id), name: record.name, category: category, baseUnit: unit, defaultShelfLifeDays: record.defaultShelfLifeDays, openShelfLifeDays: record.openShelfLifeDays, defaultQuantityPerPackage: record.defaultQuantityPerPackage ?? 1, displayScale: record.displayScale, imageAspectRatio: record.imageAspectRatio, thumbnailPNG: record.thumbnailPNG)
    }

    /// Traduce un record lotto; record non validi vengono ignorati.
    ///
    /// - Parameter record: Record da tradurre.
    /// - Returns: Snapshot lotto, oppure nil per record incoerente.
    static func itemSnapshot(from record: StockItemRecord) -> StockItemSnapshot? {
        guard let product = record.product, let unit = UnitOfMeasure(rawValue: product.baseUnitRaw), let location = StorageLocation(rawValue: record.locationRaw), let status = StockStatus(rawValue: record.statusRaw) else {
            CiboLog.persistence.error("Skipping invalid stock item record")
            return nil
        }
        return StockItemSnapshot(id: StockItemID(rawValue: record.id), productID: ProductID(rawValue: product.id), key: StockKey(category: ProductCategory(storedRawValue: product.categoryRaw), unit: unit), initialQuantity: record.initialQuantity, currentQuantity: record.currentQuantity, expirationDate: record.expirationDate, isOpen: record.isOpen, openedDate: record.openedDate, location: location, placement: ShelfPlacement(shelfIndex: record.shelfIndex, xFraction: record.xFraction, depth: record.depth), status: status, createdAt: record.createdAt, closedAt: record.closedAt)
    }

    /// Traduce una ricetta e i suoi ingredienti in uno snapshot Sendable.
    static func recipeSnapshot(from record: RecipeRecord) -> RecipeSnapshot? {
        let ingredients = record.ingredients.compactMap { ingredient -> RecipeIngredientSnapshot? in
            guard let unit = UnitOfMeasure(rawValue: ingredient.unitRaw) else {
                CiboLog.persistence.error("Skipping recipe ingredient with unknown unit")
                return nil
            }
            return RecipeIngredientSnapshot(productID: ProductID(rawValue: ingredient.productID), productName: ingredient.productName, unit: unit, quantity: ingredient.quantity)
        }
        guard ingredients.count == record.ingredients.count else { return nil }
        return RecipeSnapshot(id: RecipeID(rawValue: record.id), name: record.name, servings: record.servings, ingredients: ingredients, thumbnailPNG: record.thumbnailPNG, createdAt: record.createdAt, lastCookedAt: record.lastCookedAt, timesCooked: record.timesCooked)
    }

    /// Traduce una preparazione storica in uno snapshot Sendable.
    static func cookedMealSnapshot(from record: CookedMealRecord) -> CookedMealSnapshot? {
        let ingredients = record.ingredients.compactMap { ingredient -> RecipeIngredientSnapshot? in
            guard let unit = UnitOfMeasure(rawValue: ingredient.unitRaw) else { return nil }
            return RecipeIngredientSnapshot(productID: ProductID(rawValue: ingredient.productID), productName: ingredient.productName, unit: unit, quantity: ingredient.quantity)
        }
        guard ingredients.count == record.ingredients.count else { return nil }
        return CookedMealSnapshot(id: record.id, recipeID: RecipeID(rawValue: record.recipeID), name: record.name, servings: record.servings, ingredients: ingredients, thumbnailPNG: record.thumbnailPNG, cookedAt: record.cookedAt)
    }

}
