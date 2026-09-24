import SwiftUI

struct GymCalendarView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var displayedMonth = Date()
    
    private var calendar: Calendar { Calendar.current }
    
    // Giorni della settimana con ID unici (per evitare duplicati con "M" per Martedì e Mercoledì)
    private let weekDayLabels: [(id: Int, label: String)] = [
        (0, "L"), (1, "Ma"), (2, "Me"), (3, "G"), (4, "V"), (5, "S"), (6, "D")
    ]
    
    // Giorni vuoti iniziali nel mese (per far combaciare i giorni col giorno della settimana)
    private var leadingEmptyDays: Int {
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else { return 0 }
        let weekday = calendar.component(.weekday, from: firstOfMonth) // 1=Sunday, 2=Monday...
        return (weekday + 5) % 7 // Monday=0, Sunday=6
    }
    
    // Calcola i giorni del mese visualizzato
    private var daysInMonth: [Int] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return Array(1...30)
        }
        return Array(range)
    }
    
    // Set di giorni con allenamento nel mese visualizzato
    private var workoutDaysInMonth: Set<Int> {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        var days = Set<Int>()
        for session in workoutManager.completedSessions {
            let sessionComponents = calendar.dateComponents([.year, .month, .day], from: session.date)
            if sessionComponents.year == components.year && sessionComponents.month == components.month {
                if let day = sessionComponents.day { days.insert(day) }
            }
        }
        return days
    }

    // Titolo del mese formattato in italiano
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth).capitalized
    }

    // Giorno odierno (nil se il mese visualizzato non è quello corrente)
    private var todayDay: Int? {
        let today = Date()
        if calendar.isDate(today, equalTo: displayedMonth, toGranularity: .month) {
            return calendar.component(.day, from: today)
        }
        return nil
    }

    private var workoutCountInMonth: Int { workoutDaysInMonth.count }

    var body: some View {
        let currentWorkoutDays = workoutDaysInMonth
        let currentToday = todayDay
        let countInMonth = currentWorkoutDays.count

        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    monthHeader

                    // Calendar Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 16) {
                        ForEach(weekDayLabels, id: \.id) { item in
                            Text(item.label)
                                .font(.subheadline).bold()
                                .foregroundStyle(themeManager.currentTheme.secondaryColor)
                        }
                        ForEach(0..<leadingEmptyDays, id: \.self) { _ in
                            Color.clear
                        }
                        ForEach(daysInMonth, id: \.self) { day in
                            dayCell(for: day, hasWorkout: currentWorkoutDays.contains(day), isToday: currentToday == day)
                        }
                    }
                    .padding(.horizontal)

                    Divider().padding(.vertical, 8)

                    // Summary Box
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Riepilogo Mese")
                            .font(.headline)
                            .foregroundStyle(themeManager.currentTheme.textColor)

                        if countInMonth > 0 {
                            Text("Hai completato \(countInMonth) allenament\(countInMonth == 1 ? "o" : "i") questo mese. \(countInMonth >= 8 ? "Ottimo lavoro per mantenere la costanza!" : "Continua così!")")
                                .font(.subheadline)
                                .foregroundStyle(themeManager.currentTheme.secondaryColor)
                        } else {
                            Text("Nessun allenamento registrato questo mese.")
                                .font(.subheadline)
                                .foregroundStyle(themeManager.currentTheme.secondaryColor)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(themeManager.currentTheme.primaryColor.opacity(0.1)))
                    .padding(.horizontal)
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
            Text(monthTitle)
                .font(.title2).bold()
                .foregroundStyle(themeManager.currentTheme.textColor)
            Spacer()
            HStack(spacing: 16) {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .font(.headline).foregroundStyle(themeManager.currentTheme.primaryColor)
        }
        .padding(.horizontal)
    }

    private func dayCell(for day: Int, hasWorkout: Bool, isToday: Bool) -> some View {
        return VStack(spacing: 4) {
            Text("\(day)")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? themeManager.currentTheme.backgroundColor : themeManager.currentTheme.textColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(isToday ? themeManager.currentTheme.primaryColor : .clear))
            Circle()
                .fill(hasWorkout ? themeManager.currentTheme.primaryColor : .clear)
                .frame(width: 6, height: 6)
        }
    }
    
    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(themeManager.currentTheme.secondaryColor)
        }
    }
    
    // MARK: - Helpers
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.2)) {
                displayedMonth = newDate
            }
        }
    }
}

#Preview {
    GymCalendarView()
        .environment(ThemeManager())
        .environment(WorkoutManager())
}
