import sys
content = open("Frigo/Allenamento/Views/Screens/GymCalendarView.swift").read()

content = content.replace("""    // Calcola i giorni del mese visualizzato
    private var daysInMonth: [Int] {""", """    // Giorni vuoti iniziali nel mese (per far combaciare i giorni col giorno della settimana)
    private var leadingEmptyDays: Int {
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else { return 0 }
        let weekday = calendar.component(.weekday, from: firstOfMonth) // 1=Sunday, 2=Monday...
        return (weekday + 5) % 7 // Monday=0, Sunday=6
    }
    
    // Calcola i giorni del mese visualizzato
    private var daysInMonth: [Int] {""")

content = content.replace("""            // Celle dei giorni
            ForEach(daysInMonth, id: \.self) { dayCell(for: $0) }""", """            // Celle vuote per allineare il 1° giorno del mese
            ForEach(0..<leadingEmptyDays, id: \.self) { _ in
                Color.clear
            }
            // Celle dei giorni
            ForEach(daysInMonth, id: \.self) { dayCell(for: $0) }""")

open("Frigo/Allenamento/Views/Screens/GymCalendarView.swift", "w").write(content)
