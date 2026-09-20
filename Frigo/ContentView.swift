import SwiftUI

struct ContentView: View {
    @Environment(ThemeManager.self) private var themeManager
    
    // MARK: - LOGICA DI STATO
    // Variabile che tiene traccia della scheda aperta (0, 1 o 2).
    @State private var selectedTab = 1
    
    init() {
        // Nasconde la tab bar standard di iOS per mostrare la nostra custom
        UITabBar.appearance().isHidden = true
    }
    
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
            
            // MARK: - COMPONENTE TAB BAR CUSTOM
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private var customTabBar: some View {
        // MARK: - BOTTONI DELLA TAB BAR (LOGICA ORDINAMENTO E SCELTA ICONE)
        // Per aggiungere una schermata: metti un tabButton qui, assicurandoti 
        // di agganciarlo a un nuovo index, e aggiungi la view corrispondente nel TabView in alto col nuovo .tag().
        HStack {
            tabButton(icon: "fork.knife", title: "Cibo", index: 0)
            Spacer() // Mantiene le icone equamente distanziate
            tabButton(icon: "house.circle.fill", title: "Home", index: 1)
            Spacer()
            tabButton(icon: "dumbbell.fill", title: "Palestra", index: 2)
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
    private func tabButton(icon: String, title: String, index: Int) -> some View {
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
                // Seleziona fra la variante "piena" (.fill) se selezionata, e toglie .fill se deselezionata
                Image(systemName: isSelected ? icon : icon.replacingOccurrences(of: ".fill", with: ""))
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
}