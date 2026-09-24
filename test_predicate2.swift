import Foundation
import SwiftData

@Model final class ProductRecord {
    @Attribute(.unique) var id: UUID
    init(id: UUID) { self.id = id }
}

@Model final class StockItemRecord {
    @Attribute(.unique) var id: UUID
    var product: ProductRecord?
    var statusRaw: String = ""

    init(id: UUID) { self.id = id }
}

func testPredicate() {
    let activeStatus = "active"
    let targetProductID = UUID()
    let _ = #Predicate<StockItemRecord> { item in 
        item.statusRaw == activeStatus && item.product?.id == targetProductID 
    }
}
