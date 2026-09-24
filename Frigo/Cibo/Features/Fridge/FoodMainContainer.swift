import SwiftUI

/// Presenta la scorta con selezione della collocazione, ricerca e azioni sulle confezioni.
struct FoodMainContainer: View {
    @Bindable var viewModel: FridgeViewModel
    let inventory: any InventoryRepository
    let subjectExtractor: any SubjectExtracting
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var groupToDiscard: StockGroup?
    @State private var showingAddProduct = false
    @State private var showingCookingHub = false
    @State private var showingCalendar = false
    @State private var selectedGroup: StockGroup?
    @State private var consumptionGroup: StockGroup?
    @State private var searchText = ""
    @State private var onlyNeedsAttention = false
    @State private var selectedSort: FoodSortOption = .expiration

    private var attentionCount: Int { viewModel.groups.filter(needsAttention).count }
    private var visibleGroups: [StockGroup] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Applica i filtri
        let filtered = viewModel.groups.filter { group in
            (!onlyNeedsAttention || needsAttention(group)) &&
            (query.isEmpty || (viewModel.snapshot?.product(for: group.id.productID)?.name ?? "").localizedStandardContains(query))
        }

        // 2. Applica l'ordinamento scelto
        return filtered.sorted { groupA, groupB in
            switch selectedSort {
            case .expiration:
                return ShelfGrouping.isOrderedBefore(groupA.representative, groupB.representative)
            case .name:
                let nameA = viewModel.snapshot?.product(for: groupA.id.productID)?.name ?? ""
                let nameB = viewModel.snapshot?.product(for: groupB.id.productID)?.name ?? ""
                return nameA.localizedCaseInsensitiveCompare(nameB) == .orderedAscending
            case .quantity:
                return groupA.totalQuantity > groupB.totalQuantity
            case .recent:
                return groupA.representative.createdAt > groupB.representative.createdAt
            }
        }
    }

    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(StorageLocation.allCases) { location in
                        FoodLocationTile(location: location, isSelected: viewModel.selectedLocation == location,
                            subtitle: "\(ShelfGrouping.group(items: viewModel.snapshot?.items(in: location) ?? []).count) alimenti") {
                            viewModel.selectedLocation = location
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 12, trailing: 20))
                .listRowBackground(Color.clear).listRowSeparator(.hidden)

                VStack(alignment: .leading, spacing: 12) {
                    Text("La tua scorta").font(.title2.bold())
                    Text("Tocca un alimento per consumarlo. Scorri la scheda per spostarlo.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) { filterButtons }
                        VStack(alignment: .leading, spacing: 8) { filterButtons }
                    }
                    if onlyNeedsAttention {
                        Text("Scaduti o in scadenza entro \(ExpirationPolicy.expiringSoonThresholdDays) giorni.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 16, trailing: 20))
                .listRowBackground(Color.clear).listRowSeparator(.hidden)
            }

            if attentionCount > 0 && !onlyNeedsAttention {
                Section {
                    Button(action: { showingCookingHub = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(attentionCount) \(attentionCount == 1 ? "alimento" : "alimenti") in scadenza")
                                    .font(.headline)
                                Text("Scopri le ricette salva-spreco per non buttarli!")
                                    .font(.subheadline)
                            }
                            Spacer()
                            Image(systemName: "fork.knife.circle.fill").font(.largeTitle)
                        }
                        .padding()
                        .foregroundStyle(.white)
                        .background(Color.orange.gradient, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
                }
            }

            Section {
                if viewModel.snapshot == nil {
                    ProgressView("Caricamento alimenti…")
                        .frame(maxWidth: .infinity).padding(30)
                        .listRowBackground(Color.clear).listRowSeparator(.hidden)
                } else if visibleGroups.isEmpty {
                    emptyState.listRowBackground(Color.clear).listRowSeparator(.hidden)
                } else {
                    ForEach(visibleGroups) { group in
                        Button { consumptionGroup = group } label: {
                            InteractiveFoodNode(group: group, product: viewModel.snapshot?.product(for: group.id.productID))
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Scegli la confezione e registra quanto hai consumato")
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 12, trailing: 20))
                        .listRowBackground(Color.clear).listRowSeparator(.hidden)
                        .contextMenu {
                            Button("Consumalo", systemImage: "minus.circle") { consumptionGroup = group }
                            Button("Sposta confezioni", systemImage: "arrow.left.arrow.right") { selectedGroup = group }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Butta", systemImage: "trash") {
                                groupToDiscard = group
                            }.tint(.red)
                            quickConsumeAction(group)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) { moveAction(group) }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .animation(reduceMotion ? nil : .snappy, value: visibleGroups.map(\.id))
        .navigationTitle("Cibo")
        .searchable(text: $searchText, prompt: "Cerca nella sezione")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Piatti", systemImage: "fork.knife") { showingCookingHub = true }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Ordina per", selection: $selectedSort) {
                        ForEach(FoodSortOption.allCases) { option in
                            Label(option.rawValue, systemImage: option.symbol).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Calendario", systemImage: "calendar") { showingCalendar = true }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Aggiungi", systemImage: "plus") { showingAddProduct = true }
            }
        }
        .safeAreaInset(edge: .bottom) { moveConfirmation }
        .alert("Operazione non riuscita", isPresented: Binding(get: { viewModel.errorMessage != nil && selectedGroup == nil }, set: { if !$0 { viewModel.clearError() } })) {
            Button("OK", role: .cancel) { viewModel.clearError() }
        } message: { Text(viewModel.errorMessage ?? "") }
        .sheet(isPresented: $showingAddProduct) { AddProductView(inventory: inventory, subjectExtractor: subjectExtractor, defaultLocation: viewModel.selectedLocation) }
        .sheet(isPresented: $showingCookingHub) { CookingHubView(inventory: inventory, subjectExtractor: subjectExtractor) }
        .sheet(isPresented: $showingCalendar) { FoodCalendarView(viewModel: viewModel) }
        .sheet(item: $selectedGroup, onDismiss: { viewModel.clearError() }) { group in
            StockTransferView(viewModel: viewModel, group: group)
        }
        .sheet(item: $consumptionGroup) { group in StockConsumptionView(viewModel: viewModel, group: group) }
        .alert("Sei sicuro?",
               isPresented: Binding(
                   get: { groupToDiscard != nil },
                   set: { if !$0 { groupToDiscard = nil } }
               ),
               presenting: groupToDiscard) { targetGroup in

            Button("Butta via", role: .destructive) {
                Task {
                    await viewModel.discardWhole(from: targetGroup)
                }
            }
            Button("Annulla", role: .cancel) { }

        } message: { targetGroup in
            if let product = viewModel.snapshot?.product(for: targetGroup.id.productID) {
                Text("Vuoi davvero rimuovere l'unità con scadenza più prossima di \(product.name)? Questa operazione non può essere annullata.")
            } else {
                Text("Vuoi davvero rimuovere questo elemento? Questa operazione non può essere annullata.")
            }
        }
        .task { await viewModel.observe() }
    }

    @ViewBuilder private var filterButtons: some View {
        filterButton("Tutti · \(viewModel.groups.count)", symbol: "square.grid.2x2", active: !onlyNeedsAttention) { onlyNeedsAttention = false }
        filterButton("Da controllare · \(attentionCount)", symbol: "clock", active: onlyNeedsAttention) { onlyNeedsAttention = true }
    }

    private func filterButton(_ title: String, symbol: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol).font(.subheadline.weight(.medium))
                .padding(.horizontal, 14).frame(minHeight: 44)
                .foregroundStyle(active ? Color.white : .primary)
                .background(active ? Color.accentColor : Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(viewModel.groups.isEmpty ? "Qui c’è spazio" : "Nessun alimento trovato",
                  systemImage: viewModel.groups.isEmpty ? viewModel.selectedLocation.foodSymbol : "magnifyingglass")
        } description: {
            Text(viewModel.groups.isEmpty ? "Aggiungi il primo alimento in \(viewModel.selectedLocation.shortName.lowercased())." :
                 "Prova un altro nome oppure mostra tutti gli alimenti.")
        } actions: {
            if viewModel.groups.isEmpty {
                Button("Aggiungi alimento", systemImage: "plus") { showingAddProduct = true }
                    .buttonStyle(.borderedProminent)
            } else {
                Button("Mostra tutti") { searchText = ""; onlyNeedsAttention = false }
                    .buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder private var moveConfirmation: some View {
        if let notice = viewModel.moveNotice {
            VStack(alignment: .leading, spacing: 8) {
                Label(notice, systemImage: "checkmark.circle.fill").font(.subheadline.weight(.medium))
                HStack {
                    Button("Mostra destinazione") {
                        if let location = viewModel.movedLocation { viewModel.selectedLocation = location }
                        searchText = ""; onlyNeedsAttention = false
                        viewModel.clearNotice()
                    }
                    Spacer()
                    Button("Chiudi") { viewModel.clearNotice() }
                }
                .font(.subheadline).frame(minHeight: 44)
            }
            .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 4)
            .glassEffect(in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 16).padding(.bottom, 8)
        }
    }

    private func moveAction(_ group: StockGroup) -> some View {
        Button("Sposta", systemImage: "arrow.left.arrow.right") { selectedGroup = group }.tint(.teal)
    }

    private func quickConsumeAction(_ group: StockGroup) -> some View {
        Button("Usa", systemImage: "fork.knife") {
            Task { await viewModel.quickConsumeOne(from: group) }
        }.tint(.orange)
    }

    private func needsAttention(_ group: StockGroup) -> Bool {
        ExpirationPolicy.freshness(until: group.representative.expirationDate, from: Date(), calendar: .current) != .fresh
    }
}

enum FoodSortOption: String, CaseIterable, Identifiable {
    case expiration = "Scadenza"
    case name = "Alfabetico"
    case quantity = "Quantità"
    case recent = "Più recenti"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .expiration: return "calendar.badge.clock"
        case .name: return "textformat.abc"
        case .quantity: return "number"
        case .recent: return "sparkles"
        }
    }
}
