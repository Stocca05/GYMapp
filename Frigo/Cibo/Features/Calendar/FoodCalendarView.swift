import SwiftUI

/// Riunisce le scadenze della scorta attuale e lo storico reale dei piatti per giorno.
struct FoodCalendarView: View {
    @Bindable var viewModel: FridgeViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @State private var selectedDate = Date()
    @State private var visibleMonth = Date()
    @State private var location: StorageLocation?
    @State private var itemToDiscard: StockItemSnapshot?

    private var stock: [StockItemSnapshot] {
        (viewModel.snapshot?.items ?? []).filter { location == nil || $0.location == location }
    }
    private var meals: [CookedMealSnapshot] { viewModel.snapshot?.cookedMeals ?? [] }
    private var dailyStock: [StockItemSnapshot] { stock.filter { calendar.isDate($0.expirationDate, inSameDayAs: selectedDate) } }
    private var dailyMeals: [CookedMealSnapshot] {
        meals.filter { calendar.isDate($0.cookedAt, inSameDayAs: selectedDate) }.sorted { $0.cookedAt < $1.cookedAt }
    }
    private var overdue: [StockItemSnapshot] { stock.filter { $0.expirationDate < calendar.startOfDay(for: Date()) } }
    private var expirationCounts: [Date: Int] { Dictionary(grouping: stock, by: { calendar.startOfDay(for: $0.expirationDate) }).mapValues(\.count) }
    private var mealCounts: [Date: Int] { Dictionary(grouping: meals, by: { calendar.startOfDay(for: $0.cookedAt) }).mapValues(\.count) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Scadenze da mostrare", selection: $location) {
                        Text("Tutte le posizioni").tag(Optional<StorageLocation>.none)
                        ForEach(StorageLocation.allCases) { place in Text(place.displayName).tag(Optional(place)) }
                    }
                    FoodMonthGrid(selectedDate: $selectedDate, visibleMonth: $visibleMonth,
                        expirationCounts: expirationCounts, mealCounts: mealCounts)
                        .padding(.vertical, 6)
                } footer: {
                    Text("Le scadenze riguardano le confezioni ancora in scorta. I piatti cucinati sono mostrati per tutte le posizioni.")
                }

                if !overdue.isEmpty {
                    Section {
                        DisclosureGroup {
                            ForEach(ShelfGrouping.group(items: overdue)) { group in expirationRow(group) }
                        } label: {
                            Label("\(overdue.count) confezioni già scadute", systemImage: "exclamationmark.circle")
                                .foregroundStyle(.red)
                        }
                    } footer: { Text("Restano visibili qui anche quando consulti un altro mese.") }
                }

                Section {
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            Label("\(dailyStock.count) in scadenza", systemImage: "clock")
                            Spacer()
                            Label("\(dailyMeals.count) piatti", systemImage: "fork.knife")
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Label("\(dailyStock.count) in scadenza", systemImage: "clock")
                            Label("\(dailyMeals.count) piatti", systemImage: "fork.knife")
                        }
                    }
                    .font(.subheadline).foregroundStyle(.secondary)
                } header: { Text(selectedDate.formatted(date: .complete, time: .omitted)) }

                if dailyStock.isEmpty && dailyMeals.isEmpty {
                    ContentUnavailableView("Giornata libera", systemImage: "calendar.badge.checkmark",
                        description: Text("Nessuna scadenza della scorta attuale e nessun piatto cucinato registrato per questa data."))
                }
                if !dailyStock.isEmpty {
                    Section("Alimenti in scadenza") {
                        ForEach(ShelfGrouping.group(items: dailyStock)) { group in expirationRow(group) }
                    }
                }
                if !dailyMeals.isEmpty {
                    Section("Piatti cucinati") {
                        ForEach(dailyMeals) { meal in
                            DisclosureGroup {
                                ForEach(Array(meal.ingredients.enumerated()), id: \.offset) { _, ingredient in
                                    LabeledContent(ingredient.productName, value: "\(ingredient.quantity) \(ingredient.unit.abbreviation)")
                                        .font(.subheadline)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(meal.name).font(.headline)
                                    Text("\(meal.servings) porzioni · \(meal.cookedAt.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Calendario Cibo")
            .alert("Sei sicuro?",
                   isPresented: Binding(
                       get: { itemToDiscard != nil },
                       set: { if !$0 { itemToDiscard = nil } }
                   ),
                   presenting: itemToDiscard) { targetItem in

                Button("Butta via", role: .destructive) {
                    Task {
                        if let exactItem = (viewModel.snapshot?.items ?? []).first(where: { $0.id == targetItem.id }) {
                            await viewModel.discardWhole(item: exactItem)
                        }
                    }
                }
                Button("Annulla", role: .cancel) { }

            } message: { targetItem in
                if let product = viewModel.snapshot?.product(for: targetItem.productID) {
                    Text("Vuoi davvero rimuovere questa unità di \(product.name)? Questa operazione non può essere annullata.")
                } else {
                    Text("Vuoi davvero rimuovere questo elemento? Questa operazione non può essere annullata.")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Chiudi") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Oggi") { selectedDate = Date(); visibleMonth = selectedDate }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func expirationRow(_ group: StockGroup) -> some View {
        let product = viewModel.snapshot?.product(for: group.id.productID)
        let members = stock.filter { group.ids.contains($0.id) }
        return DisclosureGroup {
            ForEach(members.sorted(by: ShelfGrouping.isOrderedBefore)) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(item.currentQuantity) \(item.key.unit.abbreviation) · \(item.isOpen ? "Aperta" : "Chiusa")")
                    Text("Scadenza: \(item.expirationDate.formatted(date: .abbreviated, time: .omitted))")
                        .foregroundStyle(.secondary)
                    if let opened = item.openedDate {
                        Text("Aperta il \(opened.formatted(date: .abbreviated, time: .omitted))").foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline).padding(.vertical, 3)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Butta", systemImage: "trash") {
                        itemToDiscard = item
                    }.tint(.red)
                    Button("Usa", systemImage: "fork.knife") {
                        Task {
                            if let exactItem = (viewModel.snapshot?.items ?? []).first(where: { $0.id == item.id }) {
                                await viewModel.quickConsumeOne(item: exactItem)
                            }
                        }
                    }.tint(.orange)
                }
            }
        } label: {
            HStack(spacing: 12) {
                ProductThumbnailView(data: product?.thumbnailPNG, category: product?.category ?? .other)
                VStack(alignment: .leading, spacing: 5) {
                    Text(product?.name ?? "Alimento").font(.headline)
                    Text("\(group.count) \(group.representative.key.unit == .pieces ? "pezzi" : "confezioni") · \(group.totalQuantity) \(group.representative.key.unit.abbreviation)")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Label(group.id.location.displayName, systemImage: group.id.location.foodSymbol)
                        .font(.caption).foregroundStyle(group.id.location.foodTint)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
