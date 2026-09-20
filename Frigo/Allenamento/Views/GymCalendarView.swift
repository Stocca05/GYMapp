import SwiftUI

struct GymCalendarView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Mock Data
    private let weekDays = ["L", "M", "M", "G", "V", "S", "D"]
    private let daysInMonth = Array(1...30)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    monthHeader
                    calendarGrid
                    Divider().padding(.vertical, 8)
                    summaryBox
                }
                .padding(.vertical)
            }
            .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Calendario").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { closeButton } }
        }
    }
    
    // MARK: - UI Components
    
    private var monthHeader: some View {
        HStack {
            Text("Settembre 2026").font(.title2).bold().foregroundStyle(themeManager.currentTheme.textColor)
            Spacer()
            HStack(spacing: 16) {
                Button(action: {}) { Image(systemName: "chevron.left") }
                Button(action: {}) { Image(systemName: "chevron.right") }
            }
            .font(.headline).foregroundStyle(themeManager.currentTheme.primaryColor)
        }
        .padding(.horizontal)
    }
    
    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 16) {
            ForEach(weekDays, id: \.self) { Text($0).font(.subheadline).bold().foregroundStyle(themeManager.currentTheme.secondaryColor) }
            ForEach(daysInMonth, id: \.self) { dayCell(for: $0) }
        }
        .padding(.horizontal)
    }
    
    private func dayCell(for day: Int) -> some View {
        let hasWorkout = day % 5 == 0
        let isToday = day == 19
        return VStack(spacing: 4) {
            Text("\(day)")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? themeManager.currentTheme.backgroundColor : themeManager.currentTheme.textColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(isToday ? themeManager.currentTheme.primaryColor : .clear))
            Circle().fill(hasWorkout ? themeManager.currentTheme.primaryColor : .clear).frame(width: 6, height: 6)
        }
    }
    
    private var summaryBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Riepilogo Mese").font(.headline).foregroundStyle(themeManager.currentTheme.textColor)
            Text("Hai completato 6 allenamenti questo mese. Ottimo lavoro per mantenere la costanza!").font(.subheadline).foregroundStyle(themeManager.currentTheme.secondaryColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(themeManager.currentTheme.primaryColor.opacity(0.1)))
        .padding(.horizontal)
    }
    
    private var closeButton: some View {
        Button(action: { dismiss() }) { Image(systemName: "xmark.circle.fill").foregroundStyle(themeManager.currentTheme.secondaryColor) }
    }
}

#Preview { GymCalendarView().environment(ThemeManager()) }
