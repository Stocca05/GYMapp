import SwiftUI

/// Raccoglie ricette personali, suggerimenti cucinabili e storico delle preparazioni.
struct CookingHubView: View {
    let inventory: any InventoryRepository
    let subjectExtractor: any SubjectExtracting
    @Environment(\.calendar) private var calendar
    @State private var snapshot: InventorySnapshot?
    @State private var availableQuantitiesMap: [ProductID: Int] = [:]
    @State private var section = CookingSection.available
    @State private var showingCooking = false
    @State private var selectedRecipe: RecipeSnapshot?
    @State private var recipeToDelete: RecipeSnapshot?
    @State private var errorMessage: String?


    private var recipes: [RecipeSnapshot] { snapshot?.recipes.sorted { $0.lastCookedAt > $1.lastCookedAt } ?? [] }
    private var cookableRecipes: [RecipeSnapshot] { recipes.filter(canCook) }

    var body: some View {
        NavigationStack {
            Group {
                if let errorMessage {
                    ContentUnavailableView("Piatti non disponibili", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                } else if snapshot == nil {
                    ProgressView("Caricamento piatti…")
                } else {
                    List {
                        Section {
                            Picker("Sezione", selection: $section) {
                                ForEach(CookingSection.allCases) { item in Text(item.title).tag(item) }
                            }
                            .pickerStyle(.segmented)
                        }

                        switch section {
                        case .available:
                            availableSection
                        case .recipes:
                            recipesSection
                        case .history:
                            historySection
                        case .routine:
                            routineSection
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Piatti")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cucina", systemImage: "plus") { selectedRecipe = nil; showingCooking = true }
                }
            }
        }
        .task { await loadSnapshot() }
        .sheet(isPresented: $showingCooking, onDismiss: {
            selectedRecipe = nil
            Task { await loadSnapshot() }
        }) {
            CookingView(inventory: inventory, subjectExtractor: subjectExtractor, initialRecipe: selectedRecipe)
        }
        .alert("Eliminare la ricetta?", isPresented: Binding(
            get: { recipeToDelete != nil },
            set: { if !$0 { recipeToDelete = nil } }
        ), presenting: recipeToDelete) { recipe in
            Button("Elimina", role: .destructive) {
                Task { await deleteRecipe(recipe) }
            }
            Button("Annulla", role: .cancel) { }
        } message: { recipe in
            Text("La ricetta \(recipe.name) e i suoi ingredienti salvati verranno eliminati. Lo storico dei piatti già cucinati resterà disponibile.")
        }
    }

    @ViewBuilder private var availableSection: some View {
        if cookableRecipes.isEmpty {
            Section {
                ContentUnavailableView("Nessun piatto pronto", systemImage: "fork.knife", description: Text(recipes.isEmpty ? "Cucina un primo piatto per creare la tua prima ricetta." : "Aggiungi gli ingredienti mancanti per poter ripreparare i tuoi piatti."))
            }
        } else {
            Section {
                ForEach(cookableRecipes) { recipe in
                    recipeRow(recipe, subtitle: "Tutti gli ingredienti sono disponibili", accent: .green)
                }
            } header: {
                Text("Puoi cucinare ora")
            } footer: {
                Text("Le proposte usano le quantità registrate quando hai cucinato quel piatto.")
            }
        }
    }

    @ViewBuilder private var recipesSection: some View {
        if recipes.isEmpty {
            Section {
                ContentUnavailableView("Nessuna ricetta", systemImage: "book.closed", description: Text("Le ricette vengono create automaticamente quando confermi un piatto cucinato."))
            }
        } else {
            Section("Tutte le tue ricette") {
                ForEach(recipes) { recipe in
                    recipeRow(recipe, subtitle: canCook(recipe) ? "Pronta da cucinare" : missingIngredientsDescription(recipe), accent: canCook(recipe) ? .green : .orange)
                }
            }
        }
    }

    @ViewBuilder private var historySection: some View {
        let meals = snapshot?.cookedMeals.sorted { $0.cookedAt > $1.cookedAt } ?? []
        if meals.isEmpty {
            Section {
                ContentUnavailableView("Storico vuoto", systemImage: "clock.arrow.circlepath", description: Text("I piatti confermati appariranno qui."))
            }
        } else {
            Section("Tutti i piatti cucinati") {
                ForEach(meals) { meal in
                    CookedMealRow(meal: meal)
                }
            }
        }
    }

    @ViewBuilder private var routineSection: some View {
        let routine = snapshot.map { MealRoutinePlanner.make(from: $0, calendar: calendar) } ?? []
        if routine.isEmpty {
            Section {
                ContentUnavailableView(
                    "Nessuna routine disponibile",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text(recipes.isEmpty ? "Cucina un piatto per salvare la prima ricetta, poi potremo pianificare pranzi e cene." : "Aggiungi gli ingredienti necessari per almeno una ricetta.")
                )
            }
        } else {
            Section {
                ForEach(routine) { entry in
                    Button { selectedRecipe = entry.recipe; showingCooking = true } label: {
                        MealRoutineRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Routine intelligente")
            } footer: {
                Text("Impara dallo storico quali piatti prepari a pranzo o a cena, varia le proposte e dà precedenza alle scadenze. Per piccole carenze in grammi potrai usare la quantità disponibile.")
            }
        }
    }

    private func canCook(_ recipe: RecipeSnapshot) -> Bool {
        recipe.ingredients.allSatisfy { availableQuantitiesMap[$0.productID, default: 0] >= $0.quantity }
    }

    private func missingIngredientsDescription(_ recipe: RecipeSnapshot) -> String {
        let missing = recipe.ingredients.filter { availableQuantitiesMap[$0.productID, default: 0] < $0.quantity }
        guard let first = missing.first else { return "Pronta da cucinare" }
        let suffix = missing.count > 1 ? " +\(missing.count - 1)" : ""
        return "Manca \(first.productName)\(suffix)"
    }

    private func recipeRow(_ recipe: RecipeSnapshot, subtitle: String, accent: Color) -> some View {
        Button { selectedRecipe = recipe; showingCooking = true } label: {
            RecipeCard(recipe: recipe, subtitle: subtitle, accent: accent)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Elimina", systemImage: "trash", role: .destructive) {
                recipeToDelete = recipe
            }
        }
    }

    @MainActor private func deleteRecipe(_ recipe: RecipeSnapshot) async {
        do {
            try await inventory.deleteRecipe(recipe.id)
            recipeToDelete = nil
            await loadSnapshot()
        } catch {
            recipeToDelete = nil
            errorMessage = String(describing: error)
        }
    }

    @MainActor private func loadSnapshot() async {
        do { 
            let loaded = try await inventory.snapshot()
            snapshot = loaded
            availableQuantitiesMap = loaded.availableQuantities()
        } catch { errorMessage = String(describing: error) }
    }
}

/// Identifica una delle sezioni della libreria personale.
private enum CookingSection: String, CaseIterable, Identifiable {
    case available
    case recipes
    case history
    case routine

    var id: Self { self }
    var title: String {
        switch self {
        case .available: "Da cucinare"
        case .recipes: "Ricette"
        case .history: "Storico"
        case .routine: "Routine"
        }
    }
}

/// Mostra un pasto suggerito nel piano, distinto tra pranzo e cena.
private struct MealRoutineRow: View {
    let entry: MealRoutineEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.slot == .lunch ? "sun.max.fill" : "moon.stars.fill")
                .foregroundStyle(entry.slot == .lunch ? .orange : .indigo)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.slot.displayName + " · " + entry.date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(entry.recipe.name).font(.headline).foregroundStyle(.primary)
                if let expiration = entry.prioritizedExpirationDate {
                    Text("Priorità: consuma entro " + expiration.formatted(date: .abbreviated, time: .omitted))
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
                if let shortage = entry.adaptableShortages.first {
                    Text("Adattabile: \(shortage.availableQuantity) di \(shortage.requestedQuantity) \(shortage.unit.abbreviation) di \(shortage.productName)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 3)
    }
}

/// Disegna una ricetta con stato di disponibilità.
private struct RecipeCard: View {
    let recipe: RecipeSnapshot
    let subtitle: String
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            if let data = recipe.thumbnailPNG, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill().frame(width: 52, height: 52).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Image(systemName: "fork.knife").font(.title3).foregroundStyle(accent).frame(width: 52, height: 52).background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name).foregroundStyle(.primary).font(.headline)
                Text("\(recipe.servings) porzioni · \(recipe.timesCooked)× cucinato").font(.footnote).foregroundStyle(.secondary)
                Text(subtitle).font(.footnote.weight(.medium)).foregroundStyle(accent)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 3)
    }
}

/// Disegna una singola preparazione nello storico.
private struct CookedMealRow: View {
    let meal: CookedMealSnapshot

    var body: some View {
        HStack(spacing: 12) {
            if let data = meal.thumbnailPNG, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill().frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Image(systemName: "fork.knife.circle.fill").font(.title2).foregroundStyle(.tint).frame(width: 44, height: 44)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(meal.name).font(.headline)
                Text("\(meal.servings) porzioni · \(meal.cookedAt.formatted(date: .abbreviated, time: .omitted))").font(.footnote).foregroundStyle(.secondary)
                Text(meal.ingredients.map { "\($0.quantity) \($0.unit.abbreviation) \($0.productName)" }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
}
