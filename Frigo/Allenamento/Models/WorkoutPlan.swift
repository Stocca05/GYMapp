import Foundation

/// La "Scheda di Allenamento", ovvero il contenitore root per la sessione. 
/// Raggruppa tutte le scelte strutturate dell'utente (Esercizi -> Serie) sotto un'unica vista aerea.
/// 
/// Siccome abbiamo reso tutti i sottonodi (`WorkoutExercise`, `WorkoutSet` e `ExerciseModel`) conformi 
/// a `Codable`, anche `WorkoutPlan` diventa magicamente e a costo zero pienamente serializzabile!
/// Quando vorrai salvare tutto su File, UserDefaults o iCloud, il motore interno di Swift si smazzerà
/// ogni cosa automaticamente per l'intero albero! Fantastico!
struct WorkoutPlan: Identifiable, Codable, Hashable {
    
    /// L'identificatore univoco globale dell'intera scheda di allenamento.
    let id: UUID
    
    /// Il nome personalizzabile dall'utente per la scheda (es. "Giorno A", "Petto Pesante").
    var title: String
    
    /// La collezione completa di esercizi previsti in questa scheda. 
    /// Qui l'ordine dell'array determina esplicitamente l'ordine di esecuzione, 
    /// che l'utente potrà eventualmente manipolare muovendo gli elementi (`var`).
    var exercises: [WorkoutExercise]
    
    /// Il potenziale salvataggio del tema grafico associato alla scheda. 
    /// In SwiftUI si tende erroneamente e ingenuamente a salvare un tipo "Color" nei modelli... Sbagliato!
    /// L'architettura software robusta ci insegna a disaccoppiare UI (SwiftUI) dai Dati logici.
    /// Salvare il *nome/identificativo* del colore come `String` è una best practice solidissima:
    /// sarà la vista a prendere la stringa "red_theme" tradurla a momento del render visivo.
    var colorTheme: String
    
    init(id: UUID = UUID(), title: String, exercises: [WorkoutExercise] = [], colorTheme: String = "blue") {
        self.id = id
        self.title = title
        self.exercises = exercises
        self.colorTheme = colorTheme
    }
}
