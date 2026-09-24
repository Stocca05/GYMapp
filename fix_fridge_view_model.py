with open("Frigo/Cibo/Features/Fridge/FridgeViewModel.swift", "r") as f:
    content = f.read()

helper = """
    private func firstAvailableItem(for group: StockGroup) -> StockItemSnapshot? {
        (snapshot?.items(in: group.id.location) ?? [])
            .filter { $0.productID == group.id.productID && $0.currentQuantity > 0 }
            .sorted(by: ShelfGrouping.isOrderedBefore)
            .first
    }
"""

if "firstAvailableItem" not in content:
    # insert before clearNotice()
    content = content.replace("    /// Chiude il riscontro dell'ultimo trasferimento.", helper + "\n    /// Chiude il riscontro dell'ultimo trasferimento.")

old_qco = """    func quickConsumeOne(from group: StockGroup) async -> Bool {
        guard !isMoving else { return false }
        let items = (snapshot?.items(in: group.id.location) ?? [])
            .filter { $0.productID == group.id.productID && $0.currentQuantity > 0 }
            .sorted(by: ShelfGrouping.isOrderedBefore)
        
        guard let item = items.first else { return false }
"""
new_qco = """    func quickConsumeOne(from group: StockGroup) async -> Bool {
        guard !isMoving else { return false }
        guard let item = firstAvailableItem(for: group) else { return false }
"""

old_dw = """    func discardWhole(from group: StockGroup) async -> Bool {
        guard !isMoving else { return false }
        let items = (snapshot?.items(in: group.id.location) ?? [])
            .filter { $0.productID == group.id.productID && $0.currentQuantity > 0 }
            .sorted(by: ShelfGrouping.isOrderedBefore)
        
        guard let item = items.first else { return false }
"""
new_dw = """    func discardWhole(from group: StockGroup) async -> Bool {
        guard !isMoving else { return false }
        guard let item = firstAvailableItem(for: group) else { return false }
"""

content = content.replace(old_qco, new_qco)
content = content.replace(old_dw, new_dw)

with open("Frigo/Cibo/Features/Fridge/FridgeViewModel.swift", "w") as f:
    f.write(content)
