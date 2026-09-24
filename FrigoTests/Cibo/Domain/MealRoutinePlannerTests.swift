import Foundation
import Testing
@testable import Frigo

struct MealRoutinePlannerTests {
    @Test func prioritizesSoonestExpirationAndStopsWhenIngredientsRunOut() {
        let eggs = ProductID(); let pasta = ProductID()
        let today = Date(timeIntervalSinceReferenceDate: 0)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let eggsRecipe = recipe(name: "Frittata", ingredient: RecipeIngredientSnapshot(productID: eggs, productName: "Uova", unit: .pieces, quantity: 1))
        let pastaRecipe = recipe(name: "Pasta", ingredient: RecipeIngredientSnapshot(productID: pasta, productName: "Pasta", unit: .grams, quantity: 100))
        let snapshot = InventorySnapshot(
            revision: 1,
            products: [],
            items: [
                item(productID: eggs, quantity: 1, expiration: calendar.date(byAdding: .day, value: 1, to: today) ?? today),
                item(productID: pasta, quantity: 100, expiration: calendar.date(byAdding: .day, value: 5, to: today) ?? today)
            ],
            recipes: [pastaRecipe, eggsRecipe]
        )

        let routine = MealRoutinePlanner.make(from: snapshot, startingOn: today, calendar: calendar)

        #expect(routine.map(\.recipe.name) == ["Frittata", "Pasta"])
        #expect(routine.map(\.slot) == [.lunch, .dinner])
    }

    @Test func learnsDifferentHabitsForLunchAndDinner() {
        let lunchProduct = ProductID(); let dinnerProduct = ProductID()
        let day = Date(timeIntervalSinceReferenceDate: 0)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let lunch = recipe(name: "Insalata", ingredient: ingredient(productID: lunchProduct, name: "Verdure", quantity: 100))
        let dinner = recipe(name: "Risotto", ingredient: ingredient(productID: dinnerProduct, name: "Riso", quantity: 100))
        let history = [
            meal(recipe: lunch, at: date(day: day, hour: 12, calendar: calendar)),
            meal(recipe: lunch, at: date(day: day, hour: 13, calendar: calendar)),
            meal(recipe: dinner, at: date(day: day, hour: 20, calendar: calendar)),
            meal(recipe: dinner, at: date(day: day, hour: 21, calendar: calendar))
        ]
        let snapshot = InventorySnapshot(revision: 1, products: [], items: [
            item(productID: lunchProduct, quantity: 100, expiration: day),
            item(productID: dinnerProduct, quantity: 100, expiration: day)
        ], recipes: [dinner, lunch], cookedMeals: history)

        let routine = MealRoutinePlanner.make(from: snapshot, startingOn: date(day: day, hour: 12, calendar: calendar), calendar: calendar)

        #expect(routine.map(\.recipe.name) == ["Insalata", "Risotto"])
        #expect(routine.map(\.slot) == [.lunch, .dinner])
    }

    @Test func acceptsOnlySmallShortagesMeasuredInGrams() {
        let pasta = ProductID()
        let today = Date(timeIntervalSinceReferenceDate: 0)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let recipe = self.recipe(name: "Pasta", ingredient: ingredient(productID: pasta, name: "Pasta", quantity: 200))
        let snapshot = InventorySnapshot(revision: 1, products: [], items: [item(productID: pasta, quantity: 180, expiration: today)], recipes: [recipe])

        let routine = MealRoutinePlanner.make(from: snapshot, startingOn: today, calendar: calendar)

        #expect(routine.count == 1)
        #expect(routine.first?.adaptableShortages.first?.missingQuantity == 20)
        #expect(routine.first?.adaptableShortages.first?.availableQuantity == 180)
    }

    @Test func neverAdaptsDiscreteIngredientShortages() {
        let eggs = ProductID()
        let today = Date(timeIntervalSinceReferenceDate: 0)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let omelette = recipe(name: "Frittata", ingredient: RecipeIngredientSnapshot(productID: eggs, productName: "Uova", unit: .pieces, quantity: 2))
        let snapshot = InventorySnapshot(revision: 1, products: [], items: [item(productID: eggs, quantity: 1, expiration: today)], recipes: [omelette])

        #expect(MealRoutinePlanner.make(from: snapshot, startingOn: today, calendar: calendar).isEmpty)
    }

    private func recipe(name: String, ingredient: RecipeIngredientSnapshot) -> RecipeSnapshot {
        RecipeSnapshot(id: RecipeID(rawValue: UUID()), name: name, servings: 1, ingredients: [ingredient], thumbnailPNG: nil, createdAt: .now, lastCookedAt: .now, timesCooked: 1)
    }

    private func ingredient(productID: ProductID, name: String, quantity: Int) -> RecipeIngredientSnapshot {
        RecipeIngredientSnapshot(productID: productID, productName: name, unit: .grams, quantity: quantity)
    }

    private func meal(recipe: RecipeSnapshot, at cookedAt: Date) -> CookedMealSnapshot {
        CookedMealSnapshot(id: UUID(), recipeID: recipe.id, name: recipe.name, servings: recipe.servings, ingredients: recipe.ingredients, thumbnailPNG: nil, cookedAt: cookedAt)
    }

    private func date(day: Date, hour: Int, calendar: Calendar) -> Date {
        calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }

    private func item(productID: ProductID, quantity: Int, expiration: Date) -> StockItemSnapshot {
        StockItemSnapshot(
            id: StockItemID(rawValue: UUID()),
            productID: productID,
            key: StockKey(category: .other, unit: .pieces),
            initialQuantity: quantity,
            currentQuantity: quantity,
            expirationDate: expiration,
            isOpen: false,
            openedDate: nil,
            location: .fridge,
            placement: ShelfPlacement(shelfIndex: 0, xFraction: 0, depth: 0),
            status: .active,
            createdAt: .now,
            closedAt: nil
        )
    }
}
