with open("Frigo/Cibo/Features/Calendar/FoodCalendarView.swift", "r") as f:
    text = f.read()

# Add itemToDiscard state
text = text.replace("@State private var location: StorageLocation?", "@State private var location: StorageLocation?\n    @State private var itemToDiscard: StockItemSnapshot?")

# Update swipeActions in expirationRow
old_actions = """                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Butta", systemImage: "trash") {
                        Task { 
                            if let exactItem = (viewModel.snapshot?.items ?? []).first(where: { $0.id == item.id }) {
                                try? await viewModel.inventory.consume(exactItem.id, quantity: exactItem.currentQuantity)
                                await viewModel.refreshAfterConsumption()
                            }
                        }
                    }.tint(.red)
                    Button("Usa", systemImage: "checkmark") {
                        Task { 
                            if let exactItem = (viewModel.snapshot?.items ?? []).first(where: { $0.id == item.id }) {
                                try? await viewModel.inventory.consume(exactItem.id, quantity: min(exactItem.currentQuantity, exactItem.key.unit.defaultStep))
                                await viewModel.refreshAfterConsumption()
                            }
                        }
                    }.tint(.orange)
                }"""

new_actions = """                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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
                }"""

if old_actions in text:
    text = text.replace(old_actions, new_actions)
else:
    print("Could not find old actions")

# Add alert
old_alert = """.navigationTitle("Calendario Cibo")"""

new_alert = """.navigationTitle("Calendario Cibo")
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
            }"""

if old_alert in text:
    text = text.replace(old_alert, new_alert)
else:
    print("Could not find alert anchor")

with open("Frigo/Cibo/Features/Calendar/FoodCalendarView.swift", "w") as f:
    f.write(text)
