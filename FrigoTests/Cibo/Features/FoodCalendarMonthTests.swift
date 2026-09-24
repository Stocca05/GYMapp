import Foundation
import Testing
@testable import Frigo

/// Verifica mesi bisestili, inizio settimana e cambio dell'ora nel calendario Cibo.
struct FoodCalendarMonthTests {
    @Test func leapFebruaryUsesCompleteWeeks() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let date = try #require(calendar.date(from: DateComponents(year: 2024, month: 2, day: 18)))
        let cells = FoodCalendarMonth.days(containing: date, calendar: calendar)
        #expect(cells.count == 35)
        #expect(cells.prefix(3).allSatisfy { $0 == nil })
        #expect(cells.compactMap { $0 }.count == 29)
        #expect(calendar.component(.day, from: try #require(cells.compactMap { $0 }.last)) == 29)
    }

    @Test func firstWeekdayFollowsCalendarSettings() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 2, day: 1)))
        let sundayFirst = FoodCalendarMonth.days(containing: date, calendar: calendar)
        #expect(sundayFirst.first != nil)
        #expect(sundayFirst.count == 28)
        calendar.firstWeekday = 2
        let mondayFirst = FoodCalendarMonth.days(containing: date, calendar: calendar)
        #expect(mondayFirst.prefix(6).allSatisfy { $0 == nil })
        #expect(mondayFirst.count == 35)
    }

    @Test func daylightSavingDoesNotSkipOrDuplicateDays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Rome"))
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 15)))
        let days = FoodCalendarMonth.days(containing: date, calendar: calendar).compactMap { $0 }
        #expect(days.map { calendar.component(.day, from: $0) } == Array(1...31))
        #expect(days.allSatisfy { calendar.component(.hour, from: $0) == 0 })
    }
}
