with open("Frigo/Cibo/Features/Cooking/CookingView.swift", "r") as f:
    content = f.read()

state_var = "@State private var lotsByProduct: [ProductID: [StockItemSnapshot]] = [:]"
new_vars = "@State private var lotsByProduct: [ProductID: [StockItemSnapshot]] = [:]\n    @State private var availableQuantitiesMap: [ProductID: Int] = [:]"

content = content.replace(state_var, new_vars)

old_available = """    private var availableQuantities: [ProductID: Int] {
        lotsByProduct.mapValues { $0.reduce(0) { $0 + $1.currentQuantity } }
    }"""
new_available = ""

content = content.replace(old_available, new_available)

old_cancook = """    private func canCook(_ recipe: RecipeSnapshot) -> Bool {
        recipe.ingredients.allSatisfy { availableQuantities[$0.productID, default: 0] >= $0.quantity }
    }"""
new_cancook = """    private func canCook(_ recipe: RecipeSnapshot) -> Bool {
        recipe.ingredients.allSatisfy { availableQuantitiesMap[$0.productID, default: 0] >= $0.quantity }
    }"""

content = content.replace(old_cancook, new_cancook)

# In loadSnapshot:
old_load = """            lotsByProduct = Dictionary(grouping: loaded.items, by: \.productID).mapValues {
                $0.sorted(by: ShelfGrouping.isOrderedBefore)
            }
            lotsByID = Dictionary(uniqueKeysWithValues: loaded.items.map { ($0.id, $0) })"""
new_load = """            let grouped = Dictionary(grouping: loaded.items, by: \.productID).mapValues {
                $0.sorted(by: ShelfGrouping.isOrderedBefore)
            }
            lotsByProduct = grouped
            availableQuantitiesMap = grouped.mapValues { $0.reduce(0) { $0 + $1.currentQuantity } }
            lotsByID = Dictionary(uniqueKeysWithValues: loaded.items.map { ($0.id, $0) })"""

content = content.replace(old_load, new_load)

with open("Frigo/Cibo/Features/Cooking/CookingView.swift", "w") as f:
    f.write(content)

