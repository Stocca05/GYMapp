import SwiftUI
import Combine

struct ContentView: View {
    @Environment(ThemeManager.self) private var themeManager
    
    // MARK: - LOGICA DI STATO
    @Environment(WorkoutManager.self) private var workoutManager
    
    // Variabile che tiene traccia della scheda aperta.
    @State private var selectedTab = 1
    
    // Variabile per mostrare l'allenamento in corso in full screen
    @State private var showActiveWorkout = false
    
    // Timer per inattività
    let inactivityTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // MARK: - LOGICA DI NAVIGAZIONE
            // Inserisci qui le tue schermate (View). 
            // Il numero passato in .tag() deve corrispondere all'index assegnato al tasto!
                        TabView(selection: $selectedTab) {
                FoodView().tag(0)
                HomeView().tag(1)
                GymView().tag(2)
            }
            .onAppear { UITabBar.appearance().isHidden = true }
            .onDisappear { UITabBar.appearance().isHidden = false }
            .onReceive(inactivityTimer) { _ in
                workoutManager.checkInactivityAndCancelIfNeeded()
            }
            
            // MARK: - COMPONENTE TAB BAR CUSTOM
            VStack(spacing: 0) {
                if workoutManager.ongoingWorkout != nil {
                    miniWorkoutPlayer
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                customTabBar
            }

        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showActiveWorkout) {
            WorkoutActiveView()
        }
    }
    
    
    // MARK: - MINI WORKOUT PLAYER (IN-APP BANNER)
    private var miniWorkoutPlayer: some View {
        Button(action: {
            showActiveWorkout = true
        }) {
            HStack(spacing: 12) {
                // Icona animata
                Image(systemName: workoutManager.ongoingWorkout!.isResting ? "timer" : "flame.fill")
                    .foregroundColor(workoutManager.ongoingWorkout!.isResting ? .orange : .white)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(workoutManager.ongoingWorkout!.plan.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if workoutManager.ongoingWorkout!.isResting {
                        Text("Recupero in corso...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("Esercizio in corso")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.up")
                    .foregroundColor(.white)
                    .font(.subheadline.bold())
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.orange.opacity(workoutManager.ongoingWorkout!.isResting ? 1.0 : 0.0))
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(themeManager.currentTheme.primaryColor)
                            .opacity(workoutManager.ongoingWorkout!.isResting ? 0 : 1)
                    )
                    .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(.plain)
    }

    private var customTabBar: some View {
        // MARK: - BOTTONI DELLA TAB BAR (LOGICA ORDINAMENTO E SCELTA ICONE)
        // Per aggiungere una schermata: metti un tabButton qui, assicurandoti 
        // di agganciarlo a un nuovo index, e aggiungi la view corrispondente nel TabView in alto col nuovo .tag().
        HStack {
                        tabButton(icon: "fork.knife", iconFilled: "fork.knife", title: "Cibo", index: 0)
            Spacer() // Mantiene le icone equamente distanziate
            tabButton(icon: "house.circle", iconFilled: "house.circle.fill", title: "Home", index: 1)
            Spacer()
            tabButton(icon: "dumbbell", iconFilled: "dumbbell.fill", title: "Palestra", index: 2)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 15)
        
        // MARK: - GRAFICA DELLA BARRA (SFONDO ESTERNO)
        // Modifica la forma (es. usa Rectangle() al posto di Capsule()), il colore dello sfondo (.fill) e l'ombra (.shadow).
        .background {
            Capsule()
                .fill(themeManager.currentTheme.backgroundColor)
                .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.15), radius: 15, x: 0, y: 8)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 15)
    }
    
    // MARK: - GRAFICA DEI SINGOLI TASTI
    // Funzione che gestisce e "disegna" dinamicamente ogni singolo tasto specificato nel blocco HStack sovrastante.
    private func tabButton(icon: String, iconFilled: String, title: String, index: Int) -> some View {
        let isSelected = selectedTab == index
        let themeColor = themeManager.currentTheme.primaryColor
        
        return Button {
            // LOGICA DI PRESSIONE BOTTONE: Animazione eseguita quando cambi tab
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 4) {
                // GRAFICA ICONE
                // Usa la variante "piena" se selezionata, e quella outline se deselezionata
                Image(systemName: isSelected ? iconFilled : icon)
                    .font(.system(size: isSelected ? 28 : 24, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? themeColor : themeManager.currentTheme.secondaryColor)
                
                // GRAFICA TESTO
                // Appare il nome solo se il tab è quello attivo
                if isSelected {
                    Text(title)
                        .font(.caption2.bold())
                        .foregroundStyle(themeColor)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            // Manteniamo una larghezza fissa in modo che al palesarsi del testo le icone laterali non sobbalzino
            .frame(width: 60)
        }
    }
}

#Preview {
    ContentView()
        .environment(ThemeManager())
        .environment(WorkoutManager())
}
