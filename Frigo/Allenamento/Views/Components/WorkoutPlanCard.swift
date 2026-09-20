import SwiftUI

/// Componente riutilizzabile che mostra l'anteprima di una scheda di allenamento (es. a mo' di banner).
///
/// Ciao! In SwiftUI una delle best-practice assolute è mantenere il `body` principale
/// piccolo e snello, come fosse l'indice di un libro. Se la view cresce in complessità
/// (e di solito lo fa in fretta!), estraiamo i suoi mattoncini logici in `extension` (vedi `textContent`
/// qui sotto). Questo rende il codice iper-leggibile per il team.
///
/// Inoltre sfruttiamo l'`@Environment` per "pescare" il nostro TEMA INIETTATO in cima (all'avvio dell'app),
/// senza doverlo instanziare o passare manualmente in ogni rigo. (The magic of `@Observable`!)
struct WorkoutPlanCard: View {
    
    /// Il ThemeManager scende silenzioso dall'alto dell'albero dell'app.
    @Environment(ThemeManager.self) private var themeManager
    
    /// Il modello dati che nutre visivamente questa Card.
    let plan: WorkoutPlan
    
    var body: some View {
        HStack(spacing: 16) {
            textContent
            
            Spacer()
            
            playButton
        }
        // Il padding interno isola e fa "respirare" i contenuti all'interno del riquadro.
        .padding(16)
        // Creiamo un elegantissimo sfondo pastello in base al colore primario del tema
        .background(themeManager.currentTheme.primaryColor.opacity(0.1))
        // Angoli smussati col nuovo e morbido '.continuous' (invece del vecchio .circular).
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        // Una leggera ombra per "staccare" la card dal fondale bianco o scuro dell'app.
        .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Sub-Views Logiche
extension WorkoutPlanCard {
    
    /// Raggruppa i testi (Titolo, Sottotitolo e Muscoli) per mantenere ordinato il layout ad H.
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Nome grandicello
            Text(plan.title)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            // Info quantitative
            Text("\(plan.exercises.count) esercizi previsti")
                .font(.subheadline)
                // Coloriamo in "secondary" gli elementi visivamente di peso minore
                .foregroundColor(themeManager.currentTheme.secondaryColor)
            
            // "Pillola" testuale per far intuire a colpo d'occhio cosa stiamo per allenare
            Text(uniqueMusclesString)
                .font(.caption)
                .fontWeight(.medium) // medium dona un gran bel look al font testuale piccolo
                .foregroundColor(themeManager.currentTheme.primaryColor)
        }
    }
    
    /// Un bel pulsantone iconografico circolare classico per far capire all'utente
    /// "Premi qui per iniziare a pompare ghisa!".
    private var playButton: some View {
        Image(systemName: "play.fill")
            .font(.title3)
            .foregroundColor(.white)
            .padding(14)    // Ingombra leggermente oltre l'icona
            .background(
                Circle()
                    .fill(themeManager.currentTheme.primaryColor)
            )
            // Lavorare con le ombre dei bottoni usando il loro stesso colore regala
            // un senso di brillantezza (glow) moderno!
            .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.4), radius: 4, x: 0, y: 3)
    }
}

// MARK: - Code Helpers
extension WorkoutPlanCard {
    
    /// Proprietà computata per elaborare la stringa al volo ("Petto, Dorso" ecc).
    /// Isolandola qui non "sporchiamo" la vista.
    private var uniqueMusclesString: String {
        var unique: [String] = []
        for ex in plan.exercises {
            let label = ex.baseExercise.primaryMuscle.rawValue
            if !unique.contains(label) {
                unique.append(label)
            }
        }
        return unique.joined(separator: ", ")
    }
}

// MARK: - Preview nel Canvas
#Preview {
    // Il favoloso mondo dei Mock in fase di Design!
    // Simuliamo 3 esercizi volanti.
    let m1 = ExerciseModel(name: "Panca Piana", primaryMuscle: .chest)
    let m2 = ExerciseModel(name: "Croci", primaryMuscle: .chest)
    let m3 = ExerciseModel(name: "Squat Libero", primaryMuscle: .legs)
    
    // Ingrassiamo i finti WorkoutExercise (i Set per la View esterna non servono molto ma li mettiamo)
    let w1 = WorkoutExercise(baseExercise: m1, sets: [WorkoutSet(targetReps: 10)])
    let w2 = WorkoutExercise(baseExercise: m2, sets: [WorkoutSet(targetReps: 12)])
    let w3 = WorkoutExercise(baseExercise: m3, sets: [WorkoutSet(targetReps: 8)])
    
    // Mettiamoli in plan
    let plan = WorkoutPlan(title: "Giorno A: Forza Bruta", exercises: [w1, w2, w3])
    
    return WorkoutPlanCard(plan: plan)
        .padding()
        // Ricordati: se c'è un @Environment, la sintassi #Preview DEVE passarlo (iniettarlo).
        // Altrimenti il Mock crascerà miseramente leggendolo a nil!
        .environment(ThemeManager())
}
