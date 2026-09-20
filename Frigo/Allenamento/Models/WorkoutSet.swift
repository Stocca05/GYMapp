import Foundation

/// Modello che rappresenta una singola serie di un esercizio.
///
/// Anche qui usiamo `Identifiable`, `Codable` e `Hashable`.
/// Nota importante: a differenza di `ExerciseModel`, qui usiamo `var` invece di `let` 
/// per campi come `targetReps`, `targetWeight` e `isCompleted`. Perché?
/// Mentre i dati del catalogo (ExerciseModel) sono di sola lettura per evitare modifiche accidentali
/// (immutabilità), i dati della sessione in corso sono *vivi* e soggetti a modifiche continue
/// da parte dell'utente (ad esempio, potremmo decidere di fare più ripetizioni, o togliere ricalibrando il peso)!
struct WorkoutSet: Identifiable, Codable, Hashable {
    
    /// Identificativo univoco della serie. Necessario per aggiornare in modo ottimale 
    /// l'interfaccia SwiftUI se aggiungiamo, togliamo o riordiniamo le serie.
    let id: UUID
    
    /// Le ripetizioni prefissate come obiettivo per questa serie.
    /// È un valore che l'utente può decidere di cambiare al volo.
    var targetReps: Int
    
    /// Il peso in Kg (o libbre) da utilizzare per questa serie.
    /// È opzionale (`Double?`) perché, ad esempio, in corpo libero o per alcuni
    /// attrezzi il peso potrebbe non dover essere segnato. Nessun force unwrap in Swift,
    /// sfrutteremo il meccanismo sicuro degli Optionals.
    var targetWeight: Double?
    
    /// Tempo di recupero desiderato in secondi dopo aver completato questa serie.
    var restTimeInSeconds: Int
    
    /// Flag per segnare la serie come completata durante l'allenamento.
    /// Di base, quando creiamo la scheda (e quindi prima di inziare ad allenarci vero e proprio) 
    /// una serie è sempre "non completata", da cui il default a `false`.
    var isCompleted: Bool
    
    /// Costruttore. 
    /// Forniamo valori di default sensati come UUID per l'id, 90 secondi di riposo
    /// e false per rendere il riutilizzo della struct super conciso ed ergonomico.
    init(id: UUID = UUID(), 
         targetReps: Int, 
         targetWeight: Double? = nil, 
         restTimeInSeconds: Int = 90, 
         isCompleted: Bool = false) {
        self.id = id
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.restTimeInSeconds = restTimeInSeconds
        self.isCompleted = isCompleted
    }
}
