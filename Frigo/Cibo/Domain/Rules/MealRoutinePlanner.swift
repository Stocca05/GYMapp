import Foundation

/// Momento della giornata a cui assegnare un piatto pianificato.
nonisolated enum MealSlot: String, Sendable, Hashable, Codable, CaseIterable {
    case lunch
    case dinner

    var displayName: String {
        switch self {
        case .lunch: "Pranzo"
        case .dinner: "Cena"
        }
    }
}

/// Un suggerimento non vincolante per un pasto della routine.
nonisolated struct MealRoutineEntry: Sendable, Hashable, Identifiable {
    let date: Date
    let slot: MealSlot
    let recipe: RecipeSnapshot
    /// Prima scadenza tra gli ingredienti usati per la ricetta, se disponibile.
    let prioritizedExpirationDate: Date?
    /// Quantità leggermente insufficiente che può essere adattata quando si apre il piatto.
    /// Sono ammesse soltanto carenze in grammi: uova, pezzi e liquidi restano vincoli rigidi.
    let adaptableShortages: [MealRoutineShortage]

    var id: String {
        "\(date.timeIntervalSinceReferenceDate)-\(slot.rawValue)-\(recipe.id.rawValue.uuidString)"
    }
}

/// Una piccola carenza che non rende inutile un suggerimento della routine.
nonisolated struct MealRoutineShortage: Sendable, Hashable, Identifiable {
    let productID: ProductID
    let productName: String
    let unit: UnitOfMeasure
    let requestedQuantity: Int
    let availableQuantity: Int

    var id: ProductID { productID }
    var missingQuantity: Int { max(0, requestedQuantity - availableQuantity) }
}

/// Crea una simulazione di pranzi e cene senza modificare l'inventario.
nonisolated enum MealRoutinePlanner {
    /// Pianifica i pasti finché le ricette salvate sono preparabili con le quantità simulate.
    /// A ogni turno viene favorita la ricetta che impiega l'ingrediente con scadenza più vicina.
    static func make(
        from snapshot: InventorySnapshot,
        startingOn startDate: Date = .now,
        calendar: Calendar = .current
    ) -> [MealRoutineEntry] {
        var available = snapshot.availableQuantities()
        let earliestExpiration = snapshot.items.reduce(into: [ProductID: Date]()) { result, item in
            result[item.productID] = min(result[item.productID] ?? item.expirationDate, item.expirationDate)
        }
        let recipes = snapshot.recipes.filter { recipe in
            recipe.ingredients.isEmpty == false && recipe.ingredients.allSatisfy { $0.quantity > 0 }
        }
        var entries: [MealRoutineEntry] = []
        var date = calendar.startOfDay(for: startDate)
        var slot = MealSlot.forPlanning(on: startDate, calendar: calendar)
        var lastRecipeID: RecipeID?

        while let candidate = nextRecipe(
            from: recipes,
            available: available,
            earliestExpiration: earliestExpiration,
            cookedMeals: snapshot.cookedMeals,
            slot: slot,
            previousRecipeID: lastRecipeID,
            calendar: calendar
        ) {
            let recipe = candidate.recipe
            let expiration = recipe.ingredients.compactMap { earliestExpiration[$0.productID] }.min()
            entries.append(MealRoutineEntry(date: date, slot: slot, recipe: recipe, prioritizedExpirationDate: expiration, adaptableShortages: candidate.shortages))
            for ingredient in recipe.ingredients {
                // In caso di piccola carenza in grammi, pianifica ciò che c'è davvero
                // anziché creare quantità simulate negative.
                available[ingredient.productID, default: 0] -= min(ingredient.quantity, available[ingredient.productID, default: 0])
            }
            lastRecipeID = recipe.id

            if slot == .lunch {
                slot = .dinner
            } else {
                slot = .lunch
                date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            }
        }
        return entries
    }

    private static func nextRecipe(
        from recipes: [RecipeSnapshot],
        available: [ProductID: Int],
        earliestExpiration: [ProductID: Date],
        cookedMeals: [CookedMealSnapshot],
        slot: MealSlot,
        previousRecipeID: RecipeID?,
        calendar: Calendar
    ) -> Candidate? {
        recipes
            .compactMap { recipe in Candidate(recipe: recipe, available: available) }
            .min { lhs, rhs in
                let leftExpiry = lhs.recipe.ingredients.compactMap { earliestExpiration[$0.productID] }.min() ?? .distantFuture
                let rightExpiry = rhs.recipe.ingredients.compactMap { earliestExpiration[$0.productID] }.min() ?? .distantFuture
                if leftExpiry != rightExpiry { return leftExpiry < rightExpiry }
                let leftAffinity = affinity(for: lhs.recipe, in: slot, cookedMeals: cookedMeals, calendar: calendar)
                let rightAffinity = affinity(for: rhs.recipe, in: slot, cookedMeals: cookedMeals, calendar: calendar)
                if leftAffinity != rightAffinity { return leftAffinity > rightAffinity }
                let leftRepeatsPrevious = lhs.recipe.id == previousRecipeID
                let rightRepeatsPrevious = rhs.recipe.id == previousRecipeID
                if leftRepeatsPrevious != rightRepeatsPrevious { return !leftRepeatsPrevious }
                return lhs.recipe.name.localizedCaseInsensitiveCompare(rhs.recipe.name) == .orderedAscending
            }
    }

    /// Le abitudini sono dedotte dallo storico: prima delle 17 è pranzo, dalle 17 in poi è cena.
    private static func affinity(for recipe: RecipeSnapshot, in slot: MealSlot, cookedMeals: [CookedMealSnapshot], calendar: Calendar) -> Int {
        cookedMeals.reduce(into: 0) { score, meal in
            guard meal.recipeID == recipe.id, MealSlot.forPlanning(on: meal.cookedAt, calendar: calendar) == slot else { return }
            score += 1
        }
    }

    private struct Candidate {
        let recipe: RecipeSnapshot
        let shortages: [MealRoutineShortage]

        init?(recipe: RecipeSnapshot, available: [ProductID: Int]) {
            let shortages = recipe.ingredients.compactMap { ingredient -> MealRoutineShortage? in
                let present = available[ingredient.productID, default: 0]
                guard present < ingredient.quantity else { return nil }
                return MealRoutineShortage(productID: ingredient.productID, productName: ingredient.productName, unit: ingredient.unit, requestedQuantity: ingredient.quantity, availableQuantity: present)
            }
            guard shortages.allSatisfy(\.isAdaptable) else { return nil }
            self.recipe = recipe
            self.shortages = shortages
        }
    }
}

private extension MealRoutineShortage {
    /// La tolleranza resta intenzionalmente piccola: massimo il 15% e mai oltre 30 g.
    var isAdaptable: Bool {
        guard unit == .grams, missingQuantity > 0 else { return false }
        return missingQuantity <= min(30, max(10, requestedQuantity * 15 / 100))
    }
}

private extension MealSlot {
    static func forPlanning(on date: Date, calendar: Calendar) -> MealSlot {
        calendar.component(.hour, from: date) >= 17 ? .dinner : .lunch
    }
}
