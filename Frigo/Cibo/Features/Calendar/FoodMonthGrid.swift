import SwiftUI

/// Calendario mensile con indicatori distinti per scadenze e piatti cucinati.
struct FoodMonthGrid: View {
    @Binding var selectedDate: Date
    @Binding var visibleMonth: Date
    let expirationCounts: [Date: Int]
    let mealCounts: [Date: Int]
    @Environment(\.calendar) private var calendar

    /// Il calendario contiene al massimo sei settimane: renderizzarle tutte evita che una
    /// griglia lazy, annidata nella `List` della schermata, ricalcoli le sue celle mentre
    /// la lista viene riutilizzata durante lo scroll.
    private var weeks: [[Date]] {
        let days = FoodCalendarMonth.days(containing: visibleMonth, calendar: calendar)
        return stride(from: 0, to: days.count, by: 7).map { start in
            Array(days[start..<min(start + 7, days.count)])
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button { changeMonth(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    .accessibilityLabel("Mese precedente")
                Spacer(minLength: 0)
                Text(visibleMonth.formatted(.dateTime.month(.wide).year())).font(.headline)
                Spacer(minLength: 0)
                Button { changeMonth(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                    .accessibilityLabel("Mese successivo")
            }
            VStack(spacing: 6) {
                HStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { index in
                        Text(calendar.veryShortStandaloneWeekdaySymbols[(calendar.firstWeekday - 1 + index) % 7])
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .accessibilityHidden(true)
                    }
                }
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 2) {
                        ForEach(week, id: \.self) { date in
                            dayCell(date)
                        }
                    }
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { legend }
                VStack(alignment: .leading, spacing: 8) { legend }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var legend: some View {
        Label("Scadenze", systemImage: "circle.fill").foregroundStyle(.orange)
        Label("Piatti cucinati", systemImage: "square.fill").foregroundStyle(.teal)
    }

    private func dayCell(_ date: Date) -> some View {
        let day = calendar.startOfDay(for: date)
        let selected = calendar.isDate(date, inSameDayAs: selectedDate)
        let expirations = expirationCounts[day, default: 0]
        let meals = mealCounts[day, default: 0]
        
        let isCurrentMonth = calendar.isDate(date, equalTo: visibleMonth, toGranularity: .month)
        return Button { 
            selectedDate = date
            if !isCurrentMonth {
                visibleMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
            }
        } label: {
            VStack(spacing: 5) {
                Text("\(calendar.component(.day, from: date))").font(.body.weight(selected ? .bold : .regular))
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .foregroundStyle(selected ? Color.white : (isCurrentMonth ? .primary : .secondary.opacity(0.5)))
                HStack(spacing: 3) {
                    if expirations > 0 { Circle().fill(selected ? .white : .orange).frame(width: 5, height: 5) }
                    if meals > 0 { Rectangle().fill(selected ? .white : .teal).frame(width: 5, height: 5) }
                }.frame(height: 5)
            }
            .frame(height: 52).frame(maxWidth: .infinity)
            .background(selected ? Color.accentColor : .clear, in: RoundedRectangle(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(calendar.isDateInToday(date) ? Color.accentColor : .clear, lineWidth: 2) }
            .contentShape(Rectangle())
        }
        .accessibilityLabel("\(date.formatted(date: .complete, time: .omitted)), \(expirations) confezioni in scadenza, \(meals) piatti cucinati")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func changeMonth(_ offset: Int) {
        guard let start = calendar.dateInterval(of: .month, for: visibleMonth)?.start,
              let next = calendar.date(byAdding: .month, value: offset, to: start) else { return }
        visibleMonth = next
        selectedDate = next
    }
}
