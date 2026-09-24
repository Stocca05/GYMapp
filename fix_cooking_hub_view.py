with open("Frigo/Cibo/Features/Cooking/CookingHubView.swift", "r") as f:
    content = f.read()

state_var = "@State private var snapshot: InventorySnapshot?"
new_vars = "@State private var snapshot: InventorySnapshot?\n    @State private var availableQuantitiesMap: [ProductID: Int] = [:]"
content = content.replace(state_var, new_vars)

old_aq = "    private var availableQuantities: [ProductID: Int] { snapshot?.availableQuantities() ?? [:] }"
new_aq = ""
content = content.replace(old_aq, new_aq)

content = content.replace("availableQuantities[", "availableQuantitiesMap[")

old_load = """    @MainActor private func loadSnapshot() async {
        do { snapshot = try await inventory.snapshot() }
        catch { errorMessage = String(describing: error) }
    }"""
new_load = """    @MainActor private func loadSnapshot() async {
        do { 
            let loaded = try await inventory.snapshot()
            snapshot = loaded
            availableQuantitiesMap = loaded.availableQuantities()
        } catch { errorMessage = String(describing: error) }
    }"""
content = content.replace(old_load, new_load)

with open("Frigo/Cibo/Features/Cooking/CookingHubView.swift", "w") as f:
    f.write(content)
