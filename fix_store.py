import re

with open('Frigo/Cibo/Data/SwiftData/Store/SwiftDataInventoryStore.swift', 'r') as f:
    content = f.read()

content = content.replace(
'''            let items = try modelContext.fetch(FetchDescriptor<StockItemRecord>()).compactMap(InventoryMapper.itemSnapshot(from:))''',
'''            let activeStatus = StockStatus.active.rawValue
            let itemDescriptor = FetchDescriptor<StockItemRecord>(predicate: #Predicate { $0.statusRaw == activeStatus && $0.currentQuantity > 0 })
            let items = try modelContext.fetch(itemDescriptor).compactMap(InventoryMapper.itemSnapshot(from:))'''
)

content = content.replace(
'''    private func availableQuantity(for productID: ProductID) throws -> Int {
        try itemRecords()
            .filter { $0.statusRaw == StockStatus.active.rawValue && $0.product?.id == productID.rawValue }
            .reduce(0) { $0 + $1.currentQuantity }
    }''',
'''    private func availableQuantity(for productID: ProductID) throws -> Int {
        let activeStatus = StockStatus.active.rawValue
        let targetID = productID.rawValue
        let descriptor = FetchDescriptor<StockItemRecord>(predicate: #Predicate { $0.statusRaw == activeStatus && $0.product?.id == targetID })
        return try modelContext.fetch(descriptor).reduce(0) { $0 + $1.currentQuantity }
    }'''
)

content = content.replace(
'''    private func consume(quantity: Int, of productID: ProductID, at date: Date) throws {
        var remaining = quantity
        let records = try itemRecords()
            .filter { $0.statusRaw == StockStatus.active.rawValue && $0.product?.id == productID.rawValue }
            .sorted {''',
'''    private func consume(quantity: Int, of productID: ProductID, at date: Date) throws {
        var remaining = quantity
        let activeStatus = StockStatus.active.rawValue
        let targetID = productID.rawValue
        let descriptor = FetchDescriptor<StockItemRecord>(predicate: #Predicate { $0.statusRaw == activeStatus && $0.product?.id == targetID })
        let records = try modelContext.fetch(descriptor).sorted {'''
)

content = content.replace(
'''    private func occupiedPlacements(in location: StorageLocation) throws -> [ShelfPlacement] {
        try itemRecords().compactMap { record -> ShelfPlacement? in
            guard record.statusRaw == StockStatus.active.rawValue, record.locationRaw == location.rawValue else { return nil }
            return ShelfPlacement(shelfIndex: record.shelfIndex, xFraction: record.xFraction, depth: record.depth)
        }
    }''',
'''    private func occupiedPlacements(in location: StorageLocation) throws -> [ShelfPlacement] {
        let activeStatus = StockStatus.active.rawValue
        let locationRaw = location.rawValue
        let descriptor = FetchDescriptor<StockItemRecord>(predicate: #Predicate { $0.statusRaw == activeStatus && $0.locationRaw == locationRaw })
        return try modelContext.fetch(descriptor).compactMap { record in
            ShelfPlacement(shelfIndex: record.shelfIndex, xFraction: record.xFraction, depth: record.depth)
        }
    }'''
)

with open('Frigo/Cibo/Data/SwiftData/Store/SwiftDataInventoryStore.swift', 'w') as f:
    f.write(content)
