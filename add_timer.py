import re

with open("Frigo/ContentView.swift", "r") as f:
    text = f.read()

# Add timer var
timer_decl = """    // Variabile per mostrare l'allenamento in corso in full screen
    @State private var showActiveWorkout = false
    
    // Timer per inattività
    let inactivityTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
"""
text = text.replace("    // Variabile per mostrare l'allenamento in corso in full screen\n    @State private var showActiveWorkout = false\n", timer_decl)

# Add onReceive to TabView
tab_view_old = """            .onAppear { UITabBar.appearance().isHidden = true }
            .onDisappear { UITabBar.appearance().isHidden = false }"""

tab_view_new = """            .onAppear { UITabBar.appearance().isHidden = true }
            .onDisappear { UITabBar.appearance().isHidden = false }
            .onReceive(inactivityTimer) { _ in
                workoutManager.checkInactivityAndCancelIfNeeded()
            }"""

text = text.replace(tab_view_old, tab_view_new)

with open("Frigo/ContentView.swift", "w") as f:
    f.write(text)
