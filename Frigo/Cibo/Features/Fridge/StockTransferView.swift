import SwiftUI

/// Mostra quantità e scadenza di ogni confezione prima del trasferimento.
struct StockTransferView: View {
    @Bindable var viewModel: FridgeViewModel
    let group: StockGroup
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIDs: Set<StockItemID> = []
    @State private var destination: StorageLocation

    /// Apre il dettaglio senza preselezionare tutte le confezioni di un gruppo multiplo.
    init(viewModel: FridgeViewModel, group: StockGroup) {
        self.viewModel = viewModel
        self.group = group
        _destination = State(initialValue: StorageLocation.allCases.first { $0 != group.id.location } ?? .fridge)
        _selectedIDs = State(initialValue: group.count == 1 ? Set(group.ids) : [])
    }

    private var items: [StockItemSnapshot] {
        (viewModel.snapshot?.items(in: group.id.location) ?? [])
            .filter { $0.productID == group.id.productID && $0.currentQuantity > 0 }
            .sorted(by: ShelfGrouping.isOrderedBefore)
    }
    private var selectedItems: [StockItemSnapshot] { items.filter { selectedIDs.contains($0.id) } }
    private var product: ProductSnapshot? { viewModel.snapshot?.product(for: group.id.productID) }
    private var selectionTitle: String { product?.baseUnit == .pieces ? "Pezzi da spostare" : "Confezioni da spostare" }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Da \(group.id.location.displayName)", systemImage: group.id.location.foodSymbol)
                        .font(.subheadline).foregroundStyle(.secondary)
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(StorageLocation.allCases.filter { $0 != group.id.location }) { location in
                            FoodLocationTile(location: location, isSelected: destination == location) { destination = location }
                        }
                    }
                    .listRowSeparator(.hidden)
                } header: { Text("Dove vuoi spostarlo?") }
                Section {
                    if items.isEmpty {
                        Text("Non ci sono più confezioni disponibili in questa posizione.")
                    } else {
                        Button(selectedItems.count == items.count ? "Deseleziona tutto" : "Seleziona tutto") {
                            selectedIDs = selectedItems.count == items.count ? [] : Set(items.map(\.id))
                        }
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            packageRow(item, index: index)
                        }
                    }
                } header: {
                    Text(selectionTitle)
                } footer: {
                    Text("Scegli uno o più elementi. Quantità residua, apertura e scadenza restano invariate quando li sposti.")
                }
                if let error = viewModel.errorMessage {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .disabled(viewModel.isMoving)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    Text(selectedItems.isEmpty ? "Seleziona almeno un elemento" : "\(selectedItems.count) selezionati · \(selectedItems.reduce(0) { $0 + $1.currentQuantity }) \(product?.baseUnit.abbreviation ?? "")")
                        .font(.subheadline).foregroundStyle(.secondary).monospacedDigit()
                    Button {
                        let ids = selectedItems.map(\.id)
                        Task { if await viewModel.move(ids, to: destination) { dismiss() } }
                    } label: {
                        HStack(spacing: 10) {
                            if viewModel.isMoving { ProgressView().tint(.white) }
                            Text(viewModel.isMoving ? "Spostamento…" : "Sposta in \(destination.shortName)")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedItems.isEmpty || viewModel.isMoving)
                }
                .padding().background(.regularMaterial)
            }
            .navigationTitle(product?.name ?? "Sposta alimento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }.disabled(viewModel.isMoving)
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isMoving)
        .presentationDragIndicator(.visible)
        .onChange(of: items.map(\.id)) { _, ids in selectedIDs.formIntersection(ids) }
    }

    private func packageRow(_ item: StockItemSnapshot, index: Int) -> some View {
        Button {
            if selectedIDs.contains(item.id) { selectedIDs.remove(item.id) }
            else { selectedIDs.insert(item.id) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(selectedIDs.contains(item.id) ? Color.accentColor : .secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(product?.baseUnit == .pieces ? "Pezzo" : "Confezione") \(index + 1)")
                        .font(.headline)
                    Text("\(item.currentQuantity) \(item.key.unit.abbreviation) · \(item.isOpen ? "Aperta" : "Chiusa")")
                    Text("Scadenza \(item.expirationDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                }
                .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(selectedIDs.contains(item.id) ? Color.accentColor.opacity(0.08) : Color(uiColor: .secondarySystemGroupedBackground))
        .accessibilityAddTraits(selectedIDs.contains(item.id) ? .isSelected : [])
    }
}
