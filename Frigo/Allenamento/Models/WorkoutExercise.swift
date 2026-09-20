import Foundation

/// Questo modello funge da "ponte" tra l'esercizio teorico e ideale del catalogo
/// e la sua effettiva esecuzione calata all'interno di una concreta scheda di allenamento.
///
/// Ti potresti chiedere: ma perché non abbiamo messo le "serie" direttamente in `ExerciseModel`? 
/// Perché `ExerciseModel` è la definizione pura (es. "Cosa è la Panca Piana").
/// `WorkoutExercise` invece rappresenta "Questa Panca Piana, NELLA TUA SCHEDA DI DOMANI,
/// con le TUE SERIE". Questa separazione dei ruoli mantiene il codice flessibile (Principio 
/// della singola responsabilità) e ci permette di aggiungere liberamente lo stesso baseExercise
/// quante volte vogliamo a una o più schede!
struct WorkoutExercise: Identifiable, Codable, Hashable {
    
    /// Un ID indipendente specifico per l'istanza dell'esercizio nella scheda. 
    /// Un utente potrebbe per errore/scelta mettere "Panca piana" sia all'inizio
    /// che alla fine della scheda. Con UUID separati, SwiftUI gestirà perfettamente le righe senza confusione!
    let id: UUID
    
    /// Sfruttiamo il tipo forte del nostro precedente `ExerciseModel`, senza reimplementare tutto.
    /// Usiamo `let` perché l'esercizio di riferimento associato a questa riga non cambia mai: 
    /// se l'utente vuole sostituirlo, eliminerà l'intero `WorkoutExercise` creandone un altro.
    let baseExercise: ExerciseModel
    
    /// L'insieme delle serie previste. 
    /// È `var` poiché l'utente deve poter liberamente manipolare l'array (append e remove)
    /// sia durante la creazione/modifica della scheda, sia in corso d'opera.
    var sets: [WorkoutSet]
    
    init(id: UUID = UUID(), baseExercise: ExerciseModel, sets: [WorkoutSet] = []) {
        self.id = id
        self.baseExercise = baseExercise
        self.sets = sets
    }
}
