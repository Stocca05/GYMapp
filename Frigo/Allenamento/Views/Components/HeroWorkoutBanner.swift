import SwiftUI

/// Un Hero Banner dal design moderno ("glassmorphism", bordi arrotondati ampi, gradienti)
/// che rispecchia l'estetica nativa "Apple Fitness". 
/// Lavora come "macchina a stati" reagendo alla logica rotazionale del WorkoutManager.
struct HeroWorkoutBanner: View {
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(ThemeManager.self) private var themeManager
    
    @State private var isShowingCreator = false
    @State private var forceShowNext = false
    @State private var planToPlay: WorkoutPlan? = nil
    
    var body: some View {
        ZStack {
            // Sfondo dinamico governato dallo stato attuale
            backgroundView
            
            // Corpo e logica display in base allo stato
            VStack(alignment: .leading, spacing: 16) {
                if workoutManager.hasWorkedOutToday && !forceShowNext {
                    // STATO C: Allenamento della giornata completato.
                    stateCDoneView
                } else if let suggestedPlan = workoutManager.suggestedWorkoutForToday() {
                    // STATO B: Proposta per l'allenamento odierno.
                    stateBTodoView(plan: suggestedPlan)
                } else {
                    // STATO A: Nessuna scheda presente in memoria.
                    stateAEmptyView
                }
            }
            // "Lascia respirare" la Card con ampi padding lussuosi
            .padding(30) 
        }
        // Clip continuo per un effetto smussato senza spigoli rigidi
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: shadowColor, radius: 15, x: 0, y: 10)
        .fullScreenCover(isPresented: $isShowingCreator) {
            WorkoutCreatorView()
        }
        .fullScreenCover(item: $planToPlay) { plan in
            WorkoutActiveView()
                .onAppear {
                    if workoutManager.ongoingWorkout?.plan.id != plan.id {
                        workoutManager.startOrResumeWorkout(plan: plan)
                    }
                }
        }
        .onChange(of: planToPlay) { _, newValue in
            if newValue == nil {
                forceShowNext = false
            }
        }
    }
    
    // MARK: - Componenti di Stato (Macchina a Stati)
    
    /// STATO A: L'utente non ha memorizzato alcun piano.
    private var stateAEmptyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Benvenuto!")
                .font(.title2.weight(.heavy))
                .foregroundColor(.white)
            
            Text("Inizia il tuo percorso fitness. Crea la tua prima scheda di allenamento per cominciare.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 10)
            
            Button {
                isShowingCreator = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Crea Scheda")
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// STATO B: L'utente ha una scheda pianificata da fare oggi.
    private func stateBTodoView(plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ALLENAMENTO DI OGGI")
                .font(.caption.weight(.bold))
                .foregroundColor(.white.opacity(0.8))
                .tracking(1.5)
            
            Text(plan.title)
                .font(.title.weight(.heavy))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            Text("\(plan.exercises.count) Esercizi")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer(minLength: 24)
            
            Button {
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
                workoutManager.startOrResumeWorkout(plan: plan); planToPlay = plan
            } label: {
                Text(workoutManager.ongoingWorkout != nil ? "Riprendi Allenamento" : "Inizia l'Allenamento")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity)
                    // Barra "Glass" (ultraThinMaterial) in basso
                    .background(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark) 
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// STATO C: L'utente ha già registrato (marcato completato) un allenamento oggi.
    private var stateCDoneView: some View {
        VStack(alignment: .center, spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3)
            
            Text("Ottimo Lavoro!")
                .font(.title2.weight(.heavy))
                .foregroundColor(.white)
            
            Text("Oggi hai già dato il massimo. Goditi il meritato riposo, la muscolatura cresce quando recuperi.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                
            Button(action: {
                withAnimation { forceShowNext = true }
            }) {
                Text("Inizia un altro allenamento")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 16)
    }
    
    // MARK: - View Helpers (Design)
    
    @ViewBuilder
    private var backgroundView: some View {
        if workoutManager.hasWorkedOutToday && !forceShowNext {
            // Colori Verde/Oro Pastello per il giorno libero
            LinearGradient(
                colors: [Color.mint.opacity(0.9), Color.green.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if workoutManager.suggestedWorkoutForToday() != nil {
            // Colore principale (Theme) per la "Call To Action" sportiva
            LinearGradient(
                colors: [
                    themeManager.currentTheme.primaryColor.opacity(0.7),
                    themeManager.currentTheme.primaryColor
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Sfondo Dark per lo stato di assenza di schede
            LinearGradient(
                colors: [Color.gray.opacity(0.8), Color.black.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var shadowColor: Color {
        if workoutManager.hasWorkedOutToday && !forceShowNext {
            return Color.green.opacity(0.3)
        } else if workoutManager.suggestedWorkoutForToday() != nil {
            return themeManager.currentTheme.primaryColor.opacity(0.4)
        } else {
            return Color.black.opacity(0.2)
        }
    }
}

#Preview {
    HeroWorkoutBanner()
        .environment(WorkoutManager())
        .environment(ThemeManager())
        .padding()
}
