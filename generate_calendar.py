new_code = """import SwiftUI

struct GymCalendarView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(\\.dismiss) private var dismiss
    
    @State private var selectedDate = Date()
    @State private var currentMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let daysInWeek = ["L", "M", "M", "G", "V", "S", "D"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    customCalendar
                    
                    Divider().padding(.horizontal)
                    
                    Text("Allenamenti del \\(selectedDate, format: .dateTime.day().month(.wide).year())")
                        .font(.headline)
                        .foregroundStyle(themeManager.currentTheme.textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    
                    ScrollView {
                        if workoutsForSelectedDate.isEmpty {
                            Text("Giorno di Rest! Nessun allenamento registrato.")
                                .font(.subheadline)
                                .foregroundStyle(themeManager.currentTheme.secondaryColor)
                                .padding(.top, 24)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(workoutsForSelectedDate) { session in
                                    sessionCard(session)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Calendario Storico")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { closeButton } }
        }
    }
    
    // MARK: - Components
    
    private var customCalendar: some View {
        VStack(spacing: 16) {
            // Header Mese
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                }
                Spacer()
                Text(currentMonth, format: .dateTime.month(.wide).year())
                    .font(.title3.weight(.bold))
                    .foregroundStyle(themeManager.currentTheme.textColor)
                    .textCase(.uppercase)
                Spacer()
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                }
            }
            .foregroundStyle(themeManager.currentTheme.primaryColor)
            .padding(.horizontal, 24)
            
            // Griglia 7xN
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 16) {
                // Giorni settimana
                ForEach(daysInWeek, id: \\.self) { d in
                    Text(d)
                        .font(.caption2.bold())
                        .foregroundStyle(themeManager.currentTheme.secondaryColor)
                }
                
                // Spazi vuoti iniziali
                ForEach(0..<firstWeekdayOfMonth(), id: \\.self) { _ in
                    Text("")
                }
                
                // Giorni reali
                ForEach(daysInMonth(), id: \\.self) { date in
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    let isToday = calendar.isDateInToday(date)
                    let hasWorkout = hasWorkoutOn(date: date)
                    
                    VStack(spacing: 4) {
                        Text("\\(calendar.component(.day, from: date))")
                            .font(.system(size: 16, weight: isSelected || isToday ? .black : .medium))
                            .foregroundStyle(
                                isSelected ? themeManager.currentTheme.backgroundColor :
                                (isToday ? themeManager.currentTheme.primaryColor : themeManager.currentTheme.textColor)
                            )
                            .frame(width: 36, height: 36)
                            .background(
                                Circle().fill(isSelected ? themeManager.currentTheme.primaryColor : .clear)
                            )
                        
                        Circle()
                            .fill(hasWorkout ? (isSelected ? themeManager.currentTheme.backgroundColor : themeManager.currentTheme.primaryColor) : .clear)
                            .frame(width: 6, height: 6)
                    }
                    .onTapGesture {
                        withAnimation { selectedDate = date }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private func sessionCard(_ session: WorkoutManager.WorkoutSession) -> some View {
        let plan = workoutManager.myPlans.first(where: { $0.id == session.planId })
        let planName = plan?.title ?? "Scheda Rimossa"
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(planName)
                    .font(.headline.bold())
                    .foregroundStyle(themeManager.currentTheme.textColor)
                Spacer()
                Text(session.date, format: .dateTime.hour().minute())
                    .font(.caption.bold())
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
            }
            
            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("Volume")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.gray)
                    Text("\\(session.totalVolume) KG")
                        .font(.system(.title3, design: .rounded).weight(.black))
                        .foregroundStyle(themeManager.currentTheme.textColor)
                }
                
                VStack(alignment: .leading) {
                    Text("Durata")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.gray)
                    Text("\\(session.durationSeconds / 60) Minuti")
                        .font(.system(.title3, design: .rounded).weight(.black))
                        .foregroundStyle(themeManager.currentTheme.textColor)
                }
            }
            
            // Mostra gli esercizi eseguiti nella scheda (se la scheda esiste ancora)
            if let plan = plan {
                Divider()
                Text("Esercizi Eseguiti:")
                    .font(.caption2.bold())
                    .foregroundStyle(themeManager.currentTheme.secondaryColor)
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(plan.exercises, id: \\.id) { ex in
                        HStack {
                            Circle().fill(themeManager.currentTheme.primaryColor).frame(width: 4, height: 4)
                            Text(ex.baseExercise.name)
                                .font(.caption)
                                .foregroundStyle(themeManager.currentTheme.secondaryColor)
                        }
                    }
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.primaryColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(themeManager.currentTheme.primaryColor.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Logic Helpers
    
    private var workoutsForSelectedDate: [WorkoutManager.WorkoutSession] {
        workoutManager.completedSessions.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    private func hasWorkoutOn(date: Date) -> Bool {
        workoutManager.completedSessions.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            withAnimation { currentMonth = newMonth }
        }
    }
    
    private func daysInMonth() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        var dates: [Date] = []
        var currentDate = monthInterval.start
        
        while currentDate < monthInterval.end {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return dates
    }
    
    /// Trasla l'inizio mese sulla griglia considerando Lunedì come primo giorno (0-6)
    private func firstWeekdayOfMonth() -> Int {
        guard let firstDay = calendar.dateInterval(of: .month, for: currentMonth)?.start else { return 0 }
        let weekday = calendar.component(.weekday, from: firstDay) // 1=Dom, 2=Lun, ...
        // Trasliamo a 0=Lun, 1=Mar ... 6=Dom
        let adjusted = weekday - 2
        return adjusted < 0 ? 6 : adjusted
    }
    
    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(themeManager.currentTheme.secondaryColor)
                .font(.title3)
        }
    }
}
"""

with open("Frigo/Allenamento/Views/GymCalendarView.swift", "w") as f:
    f.write(new_code)
