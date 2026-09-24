import SwiftUI

/// Registra un consumo esplicito su una confezione, senza creare un piatto.
struct StockConsumptionView: View {
    @Bindable var viewModel: FridgeViewModel
    let group: StockGroup
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: StockItemID?
    @State private var quantity = 1
    @State private var entryMode: EntryMode = .quantity
    @State private var selectedFraction: ConsumptionFraction = .oneHalf
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var items: [StockItemSnapshot] {
        (viewModel.snapshot?.items(in: group.id.location) ?? [])
            .filter { $0.productID == group.id.productID }
            .sorted(by: ShelfGrouping.isOrderedBefore)
    }
    private var selected: StockItemSnapshot? { items.first { $0.id == selectedID } }
    private var product: ProductSnapshot? { viewModel.snapshot?.product(for: group.id.productID) }
    private var canUseFractions: Bool { selected?.key.unit.isContinuous == true }
    private var consumedQuantity: Int {
        guard let selected else { return 0 }
        switch entryMode {
        case .quantity:
            return quantity
        case .fraction:
            return selectedFraction.quantity(of: selected.currentQuantity)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        Button { select(item) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedID == item.id ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(.tint).font(.title2)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("\(item.key.unit == .pieces ? "Pezzo" : "Confezione") \(index + 1)").font(.headline)
                                    Text("\(item.currentQuantity) \(item.key.unit.abbreviation) · \(item.isOpen ? "Aperta" : "Chiusa")")
                                    Text("Scade \(item.expirationDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                .foregroundStyle(.primary)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 4).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selectedID == item.id ? .isSelected : [])
                    }
                    if items.isEmpty { Text("Non ci sono più confezioni disponibili.") }
                } header: { Text("Quale confezione hai usato?") }
                if let item = selected {
                    Section {
                        if canUseFractions {
                            Picker("Come vuoi scalare?", selection: $entryMode) {
                                ForEach(EntryMode.allCases) { mode in
                                    Text(mode.label).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        if entryMode == .quantity || !canUseFractions {
                            Stepper(value: $quantity, in: 1...item.currentQuantity) {
                                LabeledContent("Quantità usata", value: "\(quantity) \(item.key.unit.abbreviation)")
                            }
                            if item.currentQuantity > 1 {
                                Slider(value: Binding(get: { Double(quantity) }, set: { quantity = Int($0.rounded()) }),
                                       in: 1...Double(item.currentQuantity), step: 1)
                                    .accessibilityLabel("Quantità usata in \(item.key.unit.abbreviation)")
                            }
                        } else {
                            Picker("Porzione usata", selection: $selectedFraction) {
                                ForEach(ConsumptionFraction.allCases) { fraction in
                                    Text("\(fraction.label) · \(fraction.percentageLabel)").tag(fraction)
                                }
                            }
                            LabeledContent("Quantità usata", value: "\(consumedQuantity) \(item.key.unit.abbreviation)")
                            Text("La frazione è calcolata sulla quantità ancora disponibile in questa confezione.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Button("Terminato · usa tutto", systemImage: "checkmark.circle") { quantity = item.currentQuantity }
                        LabeledContent("Rimane", value: "\(max(item.currentQuantity - consumedQuantity, 0)) \(item.key.unit.abbreviation)")
                            .foregroundStyle(.secondary)
                    } header: { Text("Quanto hai consumato?") } footer: {
                        Text(consumedQuantity == item.currentQuantity ? "Questa confezione sarà segnata come terminata. Le altre restano in scorta." : "La quantità residua resta in scorta. La confezione viene segnata come aperta e la scadenza aggiornata, se prevista.")
                    }
                }
                if let errorMessage { Section { Text(errorMessage).foregroundStyle(.red) } }
            }
            .disabled(isSaving)
            .navigationTitle(product?.name ?? "Consumalo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() }.disabled(isSaving) }
            }
            .safeAreaInset(edge: .bottom) {
                Button { Task { await save() } } label: {
                    HStack {
                        if isSaving { ProgressView().tint(.white) }
                        Text(isSaving ? "Salvataggio…" : "Conferma consumo").font(.headline)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving || selected == nil || consumedQuantity < 1 || consumedQuantity > (selected?.currentQuantity ?? 0))
                .padding().background(.regularMaterial)
            }
        }
        .interactiveDismissDisabled(isSaving)
        .presentationDragIndicator(.visible)
        .onAppear { if items.count == 1, let item = items.first { select(item) } }
        .onChange(of: selected?.currentQuantity) { _, available in
            if let available { quantity = min(quantity, available) }
        }
        .onChange(of: canUseFractions) { _, supportsFractions in
            if !supportsFractions { entryMode = .quantity }
        }
    }

    private func select(_ item: StockItemSnapshot) {
        selectedID = item.id
        quantity = min(item.currentQuantity, item.key.unit.defaultStep)
        errorMessage = nil
    }

    @MainActor private func save() async {
        guard !isSaving, let item = selected else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await viewModel.inventory.consume(item.id, quantity: consumedQuantity)
        } catch {
            errorMessage = "Consumo non salvato. Controlla la quantità disponibile e riprova."
            return
        }
        await viewModel.refreshAfterConsumption()
        dismiss()
    }

    private enum EntryMode: String, CaseIterable, Identifiable {
        case quantity
        case fraction

        var id: Self { self }

        var label: String {
            switch self {
            case .quantity: "Grammi / ml"
            case .fraction: "Frazione"
            }
        }
    }
}
