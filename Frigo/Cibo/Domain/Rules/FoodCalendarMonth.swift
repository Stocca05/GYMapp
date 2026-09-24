import Foundation

/// Calcola le celle del mese rispettando calendario, fuso orario e primo giorno della settimana.

nonisolated enum FoodCalendarMonth {
    /// Restituisce la griglia completa del mese (inclusi i giorni del mese precedente e successivo per riempire la griglia).
    static func days(containing date: Date, calendar: Calendar) -> [Date] {
        guard let month = calendar.dateInterval(of: .month, for: date),
              let range = calendar.range(of: .day, in: .month, for: date) else { return [] }
        
        let weekday = calendar.component(.weekday, from: month.start)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        
        var cells = [Date]()
        
        // Giorni del mese precedente
        for i in (0..<leading).reversed() {
            if let prevDate = calendar.date(byAdding: .day, value: -(i + 1), to: month.start) {
                cells.append(prevDate)
            }
        }
        
        // Giorni del mese corrente
        cells += range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: month.start) }
        
        // Giorni del mese successivo (per completare la settimana)
        let trailing = (7 - cells.count % 7) % 7
        if trailing > 0, let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: month.start) {
            for i in 0..<trailing {
                if let nextDate = calendar.date(byAdding: .day, value: i, to: nextMonthStart) {
                    cells.append(nextDate)
                }
            }
        }
        
        return cells
    }
}
