import Foundation
import SwiftData

@Model final class StockItemRecord {
    @Attribute(.unique) var id: UUID
    var initialQuantity: Int = 0
    var currentQuantity: Int = 0
    var statusRaw: String = ""

    init(id: UUID) { self.id = id }
}

func testPredicate() {
    let activeStatus = "active"
    let _ = #Predicate<StockItemRecord> { $0.statusRaw == activeStatus && $0.currentQuantity > 0 }
}
