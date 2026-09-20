import SwiftUI

/// Componente riutilizzabile: la singola riga di un esercizio.
/// Totalmente ridisegnata in chiave minimal e lussuosa!
struct ExerciseRowView: View {
    
    @Environment(ThemeManager.self) private var themeManager
    
    let exercise: WorkoutExercise
    
    var body: some View {
        HStack(spacing: 16) {
            // 1. Immagine reale o Icona Placeholder Decorata
            if let imageName = exercise.baseExercise.imageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                muscleIcon
            }
            
            // 2. Info nucleari centrali
            textContent
            
            Spacer()
            
            // 3. Indicatore minimale
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundColor(themeManager.currentTheme.secondaryColor.opacity(0.3))
        }
        // Niente padding verticale eccessivo qui, perché la Card ospitante o la ScrollView globale
        // si occuperà di gestire il respiro del contesto circostante.
    }
}

// MARK: - Rendering Logics (Sub-Views)
extension ExerciseRowView {
    
    /// Il quadratino grafico sostitutivo se l'immagine fotografica non è disponibile.
    /// Bello, arrotondato e "pastello", super pulito!
    private var muscleIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(themeManager.currentTheme.primaryColor.opacity(0.12))
                .frame(width: 64, height: 64) // Esattamente dimensionato come le potenziali foto!
            
            Image(systemName: iconName(for: exercise.baseExercise.primaryMuscle))
                .font(.title2.weight(.medium))
                .foregroundColor(themeManager.currentTheme.primaryColor)
        }
    }
    
    /// Informazioni testuali eleganti, dirette, senza distrazioni.
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(exercise.baseExercise.name)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            // "Pillola" compatta per il gruppo muscolare
            Text(exercise.baseExercise.primaryMuscle.rawValue)
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                // Sfondo morbido per esaltare il testo
                .background(themeManager.currentTheme.secondaryColor.opacity(0.1))
                .clipShape(Capsule())
                .foregroundColor(themeManager.currentTheme.secondaryColor)
        }
    }
}

// MARK: - Helpers
extension ExerciseRowView {
    
    /// Sceglie un'icona ad-hoc fornita gratuitamente dal sistema (SF Symbols) per ogni distretto.
    private func iconName(for muscle: MuscleGroup) -> String {
        switch muscle {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.core.training"
        case .legs: return "figure.walk"
        case .shoulders: return "figure.mixed.cardio"
        case .arms: return "hand.raised.fill"
        case .core: return "figure.mind.and.body"
        case .fullBody: return "figure.highintensity.intervaltraining"
        case .cardio: return "heart.fill"
        }
    }
}

// MARK: - Render Preview (Spingiamo in Canvas)
#Preview {
    let mockEx = ExerciseModel(name: "Lento Avanti Seduto", primaryMuscle: .shoulders)
    let set1 = WorkoutSet(targetReps: 8, targetWeight: 40.0)
    let set2 = WorkoutSet(targetReps: 8, targetWeight: 42.5)
    
    let mockWorkEx = WorkoutExercise(baseExercise: mockEx, sets: [set1, set2])
    
    return ExerciseRowView(exercise: mockWorkEx)
        .padding()
        .environment(ThemeManager())
}
