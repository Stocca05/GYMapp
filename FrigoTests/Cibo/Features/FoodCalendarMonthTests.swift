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
        #expect(cells.prefix(3).map { calendar.component(.day, from: $0) } == [29, 30, 31])
        #expect(cells.prefix(3).allSatisfy { calendar.component(.month, from: $0) == 1 })
        let february = cells.filter { calendar.component(.month, from: $0) == 2 }
        #expect(february.map { calendar.component(.day, from: $0) } == Array(1...29))
        #expect(calendar.component(.day, from: try #require(cells.last)) == 3)
        #expect(calendar.component(.month, from: try #require(cells.last)) == 3)
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
        #expect(mondayFirst.prefix(6).map { calendar.component(.day, from: $0) } == Array(26...31))
        #expect(mondayFirst.prefix(6).allSatisfy { calendar.component(.month, from: $0) == 1 })
        #expect(calendar.component(.weekday, from: try #require(mondayFirst.first)) == 2)
        #expect(mondayFirst.count == 35)
    }

    @Test func daylightSavingDoesNotSkipOrDuplicateDays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Rome"))
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 15)))
        let days = FoodCalendarMonth.days(containing: date, calendar: calendar)
        let march = days.filter { calendar.component(.month, from: $0) == 3 }
        #expect(march.map { calendar.component(.day, from: $0) } == Array(1...31))
        #expect(Set(days).count == days.count)
        #expect(days.count.isMultiple(of: 7))
        for (previous, next) in zip(days, days.dropFirst()) {
            #expect(calendar.date(byAdding: .day, value: 1, to: previous) == next)
        }
        #expect(days.allSatisfy { calendar.component(.hour, from: $0) == 0 })
    }
}
