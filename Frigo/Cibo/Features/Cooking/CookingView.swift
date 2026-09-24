import SwiftUI
import PhotosUI

/// Permette di registrare un piatto usando le singole confezioni disponibili.
struct CookingView: View {
    let inventory: any InventoryRepository
    let subjectExtractor: any SubjectExtracting
    let initialRecipe: RecipeSnapshot?
    @Environment(\.dismiss) private var dismiss
    @State private var snapshot: InventorySnapshot?
    @State private var lotsByProduct: [ProductID: [StockItemSnapshot]] = [:]
    @State private var availableQuantitiesMap: [ProductID: Int] = [:]
    @State private var lotsByID: [StockItemID: StockItemSnapshot] = [:]
    @State private var remainingQuantities: [StockItemID: Int] = [:]
    @State private var name = ""
    @State private var servings = 1
    @State private var photoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showingCamera = false
    @State private var errorMessage: String?
    @State private var isSaving = false

    /// Crea la schermata, opzionalmente con una ricetta da ripetere.
    init(inventory: any InventoryRepository, subjectExtractor: any SubjectExtracting, initialRecipe: RecipeSnapshot? = nil) {
        self.inventory = inventory
        self.subjectExtractor = subjectExtractor
        self.initialRecipe = initialRecipe
    }

    private var availableProducts: [(ProductSnapshot, [StockItemSnapshot])] {
        guard let snapshot else { return [] }
        return snapshot.products.compactMap { product in
            guard let lots = lotsByProduct[product.id], lots.isEmpty == false else { return nil }
            return (product, lots)
        }
        .sorted { $0.0.name.localizedCaseInsensitiveCompare($1.0.name) == .orderedAscending }
    }

    private var ingredientDrafts: [CookedIngredientDraft] {
        remainingQuantities.compactMap { itemID, remaining -> CookedIngredientDraft? in
            guard let lot = lotsByID[itemID] else { return nil }
            let consumed = lot.currentQuantity - remaining
            guard consumed > 0 else { return nil }
            return CookedIngredientDraft(productID: lot.productID, stockItemID: itemID, quantity: consumed)
        }
    }



    var body: some View {
        NavigationStack {
            List {
                Section("Piatto") {
                    TextField("Nome del piatto", text: $name).textInputAutocapitalization(.sentences)
                    Stepper("Porzioni: \(servings)", value: $servings, in: 1...24)
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(imageData == nil ? "Aggiungi foto" : "Foto selezionata", systemImage: "photo")
                    }
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button("Scatta foto", systemImage: "camera") { showingCamera = true }
                    }
                }

                Section("Ingredienti dalla dispensa") {
                    if availableProducts.isEmpty {
                        ContentUnavailableView("Dispensa vuota", systemImage: "basket", description: Text("Aggiungi prima alcuni prodotti."))
                    } else {
                        ForEach(availableProducts, id: \.0.id) { product, lots in
                            CookingIngredientRow(product: product, lots: lots, remainingQuantities: $remainingQuantities)
                        }
                    }
                }

                if let snapshot, snapshot.recipes.isEmpty == false {
                    Section {
                        ForEach(snapshot.recipes.sorted { canCook($0) && !canCook($1) }) { recipe in
                            Button { load(recipe) } label: { RecipeRow(recipe: recipe, isAvailable: canCook(recipe)) }
                                .buttonStyle(.plain)
                                .disabled(canCook(recipe) == false)
                        }
                    } header: { Text("Piatti già cucinati") } footer: { Text("Tocca un piatto disponibile per usare di nuovo le sue quantità.") }
                }

                if let snapshot, snapshot.cookedMeals.isEmpty == false {
                    Section("Ultime preparazioni") {
                        ForEach(snapshot.cookedMeals.sorted { $0.cookedAt > $1.cookedAt }.prefix(5)) { meal in
                            LabeledContent(meal.name, value: "\(meal.servings) porz.")
                        }
                    }
                }

                if let errorMessage { Section { Text(errorMessage).foregroundStyle(.red) } }
            }
            .disabled(isSaving)
            .navigationTitle("Cucina")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Salvataggio…" : "Cucinato") { Task { await cook() } }
                        .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || ingredientDrafts.isEmpty)
                }
            }
        }
        .interactiveDismissDisabled(isSaving)
        .task {
            await loadSnapshot()
            if let initialRecipe { load(initialRecipe) }
        }
        .onChange(of: photoItem) { _, item in Task { await loadPhoto(item) } }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker(onImage: { data in imageData = data; showingCamera = false }, onCancel: { showingCamera = false })
        }
    }

    private func canCook(_ recipe: RecipeSnapshot) -> Bool {
        recipe.ingredients.allSatisfy { availableQuantitiesMap[$0.productID, default: 0] >= $0.quantity }
    }

    @MainActor private func loadSnapshot() async {
        do {
            let loaded = try await inventory.snapshot()
            snapshot = loaded
            let grouped = Dictionary(grouping: loaded.items, by: \.productID).mapValues {
                $0.sorted(by: ShelfGrouping.isOrderedBefore)
            }
            lotsByProduct = grouped
            availableQuantitiesMap = grouped.mapValues { $0.reduce(0) { $0 + $1.currentQuantity } }
            lotsByID = Dictionary(uniqueKeysWithValues: loaded.items.map { ($0.id, $0) })
        } catch { errorMessage = String(describing: error) }
    }

    @MainActor private func load(_ recipe: RecipeSnapshot) {
        name = recipe.name
        servings = recipe.servings
        remainingQuantities = [:]
        for ingredient in recipe.ingredients {
            var quantityToUse = ingredient.quantity
            for lot in lotsByProduct[ingredient.productID, default: []] where quantityToUse > 0 {
                let used = min(quantityToUse, lot.currentQuantity)
                remainingQuantities[lot.id] = lot.currentQuantity - used
                quantityToUse -= used
            }
        }
    }

    @MainActor private func cook() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let processed: ExtractedSubject?
            if let imageData { processed = try await subjectExtractor.extractSubject(from: imageData) }
            else { processed = nil }
            _ = try await inventory.cook(CookedMealDraft(name: name, servings: servings, ingredients: ingredientDrafts, imageData: processed?.fullPNG, thumbnailData: processed?.thumbnailPNG))
            dismiss()
        } catch { errorMessage = String(describing: error) }
    }

    @MainActor private func loadPhoto(_ item: PhotosPickerItem?) async {
        do { imageData = try await item?.loadTransferable(type: Data.self) }
        catch { errorMessage = String(describing: error) }
    }
}

/// Mostra le confezioni di un prodotto e permette di aprirne una seconda quando serve.
private struct CookingIngredientRow: View {
    let product: ProductSnapshot
    let lots: [StockItemSnapshot]
    @Binding var remainingQuantities: [StockItemID: Int]
    @State private var revealedLotCount = 1

    private var visibleLotCount: Int {
        let selectedLastIndex = lots.lastIndex { remainingQuantities[$0.id] != nil }.map { $0 + 1 } ?? 1
        return min(lots.count, max(revealedLotCount, selectedLastIndex))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(product.name).font(.headline)
            ForEach(lots.prefix(visibleLotCount), id: \.id) { lot in
                CookingLotRow(lot: lot, unit: product.baseUnit, remainingQuantity: binding(for: lot.id))
            }
            if visibleLotCount < lots.count {
                Button("Mostra un'altra confezione", systemImage: "plus.circle") { revealedLotCount = visibleLotCount + 1 }
                    .font(.subheadline.weight(.medium))
            }
        }
        .padding(.vertical, 6)
    }

    private func binding(for itemID: StockItemID) -> Binding<Int?> {
        Binding(get: { remainingQuantities[itemID] }, set: { value in
            if let value { remainingQuantities[itemID] = value }
            else { remainingQuantities.removeValue(forKey: itemID) }
        })
    }
}

/// Gestisce la quantità rimasta in una singola confezione.
private struct CookingLotRow: View {
    let lot: StockItemSnapshot
    let unit: UnitOfMeasure
    @Binding var remainingQuantity: Int?

    private var remaining: Int { remainingQuantity ?? lot.currentQuantity }
    private var consumed: Int { lot.currentQuantity - remaining }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                remainingQuantity = remainingQuantity == nil ? lot.currentQuantity : nil
            } label: {
                HStack {
                    Image(systemName: remainingQuantity == nil ? "circle" : "checkmark.circle.fill")
                        .foregroundStyle(remainingQuantity == nil ? Color.secondary : Color.accentColor)
                    Text(lot.isOpen ? "Confezione aperta" : "Confezione chiusa")
                    Spacer()
                    Text("\(lot.currentQuantity) \(unit.abbreviation)").foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if remainingQuantity != nil {
                Text("\(lot.location.displayName) · Scade \(lot.expirationDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption).foregroundStyle(.secondary)
                Slider(value: Binding(get: { Double(remaining) }, set: { remainingQuantity = min(max(Int($0.rounded()), 0), lot.currentQuantity) }), in: 0...Double(max(lot.currentQuantity, 1)), step: 1)
                HStack {
                    Button("Usa tutto") { remainingQuantity = 0 }
                    Spacer()
                    Button("Non usare") { remainingQuantity = nil }
                }
                .font(.caption)
                .buttonStyle(.borderless)
                HStack {
                    Text("Rimane \(remaining) \(unit.abbreviation)")
                    Spacer()
                    Text("Usati \(consumed) \(unit.abbreviation)")
                }
                .font(.footnote.monospacedDigit())
                .foregroundStyle(consumed > 0 ? Color.accentColor : Color.secondary)
            }
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Mostra una ricetta personale già cucinata.
private struct RecipeRow: View {
    let recipe: RecipeSnapshot
    let isAvailable: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "fork.knife").foregroundStyle(.tint).frame(width: 36, height: 36).background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(recipe.name).foregroundStyle(.primary)
                Text("\(recipe.ingredients.count) ingredienti · \(recipe.timesCooked)× cucinato").font(.footnote).foregroundStyle(.secondary)
                Text(isAvailable ? "Puoi cucinarlo ora" : "Ingredienti insufficienti").font(.footnote.weight(.medium)).foregroundStyle(isAvailable ? .green : .orange)
            }
            Spacer()
            Image(systemName: "arrow.clockwise").foregroundStyle(.secondary)
        }
    }
}
