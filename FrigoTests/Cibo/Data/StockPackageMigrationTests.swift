import Foundation
import SwiftData
import Testing
@testable import Frigo

/// Verifica il recupero dei dati salvati quando le confezioni erano aggregate.
@MainActor struct StockPackageMigrationTests {
    @Test func legacyPackagesPreserveQuantitiesDatesAndIdentity() throws {
        let container = try CiboContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        let date = Date(timeIntervalSince1970: 1_735_689_600)
        let product = ProductRecord(id: UUID(), name: "Latte", categoryRaw: "dairy", baseUnitRaw: UnitOfMeasure.milliliters.rawValue,
            defaultShelfLifeDays: 5, openShelfLifeDays: 2, defaultQuantityPerPackage: 1_000,
            displayScale: 1, imageAspectRatio: 1, thumbnailPNG: nil, fullImagePNG: nil, createdAt: date)
        let id = UUID()
        let item = StockItemRecord(id: id, product: product, initialQuantity: 3_000, currentQuantity: 1_750,
            expirationDate: date, isOpen: true, openedDate: date, locationRaw: StorageLocation.pantry.rawValue,
            shelfIndex: 0, xFraction: 0.5, depth: 0, statusRaw: StockStatus.active.rawValue, createdAt: date, closedAt: nil)
        context.insert(product)
        context.insert(item)
        try context.save()

        try StockPackageMigration.normalize(in: context)
        let records = try context.fetch(FetchDescriptor<StockItemRecord>())
        #expect(records.count == 3)
        #expect(records.reduce(0) { $0 + $1.initialQuantity } == 3_000)
        #expect(records.reduce(0) { $0 + $1.currentQuantity } == 1_750)
        #expect(records.first { $0.id == id }?.currentQuantity == 750)
        let active = records.filter { $0.statusRaw == StockStatus.active.rawValue }
        #expect(active.count == 2)
        #expect(active.allSatisfy { $0.expirationDate == date && $0.isOpen && $0.openedDate == date })

        let reopened = ModelContext(container)
        try StockPackageMigration.normalize(in: reopened)
        let reloaded = try reopened.fetch(FetchDescriptor<StockItemRecord>())
        #expect(Set(reloaded.map(\.id)) == Set(records.map(\.id)))
        #expect(reloaded.reduce(0) { $0 + $1.currentQuantity } == 1_750)
    }
}
