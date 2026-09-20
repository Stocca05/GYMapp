import SwiftUI

/// Componente riutilizzabile: la singola riga di un esercizio per la vista di dettaglio della scheda.
///
/// Mettendo il layout in moduli piccolini come `ExerciseRowView`, ci assicuriamo 
/// prestazioni SwiftUI eccezionali in fase di scroll, visto che ogni riga è a sé stante e valuta
/// lo stato proprio strettamente necessario per disegnare le sue informazioni!
struct ExerciseRowView: View {
    
    /// Peschiamo sempre il ThemeManager globale e universale
    @Environment(ThemeManager.self) private var themeManager
    
    /// Il modello Dati in input, strettamente in let. Questo componente legge e renderizza, non modifica!
    let exercise: WorkoutExercise
    
    var body: some View {
        HStack(spacing: 16) {
            // 1. Blocco grafico di testa
            muscleIcon
            
            // 2. Info nucleari centrali
            textContent
            
            // Costringe i precedenti ad allinearsi a Sinistra ("leading") spingendoli via.
            Spacer()
            
            // 3. Indicatore visivo di "puoi tappare per andare nel dettaglio!"
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                // Diamo un colore spento per dire "sono un interattabile timido, l'azione è qua ma non sono la star"
                .foregroundColor(themeManager.currentTheme.secondaryColor.opacity(0.4))
        }
        // Il padding verticale mantiene ogni cella ariosa in un ipotetico List ()
        .padding(.vertical, 8)
    }
}

// MARK: - Rendering Logics (Sub-Views)
extension ExerciseRowView {
    
    /// Costruiamo il quadratino iconico che rappresenta con colore e disegno la tipologia di muscolo.
    private var muscleIcon: some View {
        ZStack {
            // Fondo pastello molto figo e contemporaneo.
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(themeManager.currentTheme.primaryColor.opacity(0.12))
                .frame(width: 48, height: 48)
            
            // Mappatura fantastica ai simboli integrati di Apple, gli "SF Symbols"
            Image(systemName: iconName(for: exercise.baseExercise.primaryMuscle))
                .font(.body.weight(.semibold))
                .foregroundColor(themeManager.currentTheme.primaryColor)
        }
    }
    
    /// Informazioni testuali.
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Nome vigoroso dell'esercizio
            Text(exercise.baseExercise.name)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            // Una pillola di informazione tecnica sotto.
            Text("\(exercise.sets.count) serie previste")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryColor)
        }
    }
}

// MARK: - Helpers
extension ExerciseRowView {
    
    /// Sceglie un'icona ad-hoc fornita gratuitamente dal sistema (SF Symbols) per ogni distretto.
    /// Potremmo salvarlo anche a livello Modello, ma se è un mero decoro testuale ha senso
    /// gestirlo interamente nella logica della View.
    private func iconName(for muscle: MuscleGroup) -> String {
        switch muscle {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.core.training" // Una schienata?
        case .legs: return "figure.walk" // Gambe in movimento!
        case .shoulders: return "figure.mixed.cardio"
        case .arms: return "hand.raised.fill"
        case .core: return "figure.mind.and.body" // Il centro di gravità
        case .fullBody: return "figure.highintensity.intervaltraining"
        case .cardio: return "heart.fill"
        }
    }
}

// MARK: - Render Preview (Spingiamo in Canvas)
#Preview {
    // Prepariamo 2-3 mock per far renderizzare questa chicca.
    let mockEx = ExerciseModel(name: "Lento Avanti Seduto", primaryMuscle: .shoulders)
    let set1 = WorkoutSet(targetReps: 8, targetWeight: 40.0)
    let set2 = WorkoutSet(targetReps: 8, targetWeight: 42.5)
    
    let mockWorkEx = WorkoutExercise(baseExercise: mockEx, sets: [set1, set2])
    
    // Inseriamo in List per vedere come si comporta nel suo habitat naturale
    return List {
        ExerciseRowView(exercise: mockWorkEx)
        ExerciseRowView(exercise: mockWorkEx)
    }
    .listStyle(.plain)
    .environment(ThemeManager())
}
