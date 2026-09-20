import Foundation

/// Rappresenta il gruppo muscolare principale coinvolto in un esercizio.
///
/// Come ti accorgerai crescendo come sviluppatore, usare un Enum al posto di una semplice String
/// (es. "Petto", "Dorso") ci salva la vita. Questo perché:
/// 1. Evita errori di battitura (il compilatore ci aiuta!).
/// 2. È molto più facile da gestire in caso di traduzioni o modifiche.
/// 3. Rende il codice auto-documentato.
enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "Petto"
    case back = "Dorso"
    case legs = "Gambe"
    case shoulders = "Spalle"
    case arms = "Braccia"
    case core = "Addome"
    case fullBody = "Full Body"
    case cardio = "Cardio"
}

/// Il modello base per un esercizio del nostro catalogo.
///
/// Ciao! Benvenuto nel tuo primo modello in Swift.
/// Nota come abbiamo marcato questa struct con tre protocolli fondamentali:
/// - `Identifiable`: Assicura che ogni esercizio abbia un ID unico. Questo è vitale per SwiftUI, 
///   specialmente quando vogliamo mostrare gli esercizi in una Lista (`List` o `ForEach`).
///   Senza un ID univoco, SwiftUI andrebbe in confusione nel capire quale riga corrisponda a quale esercizio.
/// - `Codable`: Questo protocollo combina `Encodable` e `Decodable`. Ci permette di convertire (serializzare)
///   facilmente questo oggetto in altri formati (es. JSON) da salvare su disco o mandare a un server,
///   e viceversa. Magia pura con zero fatica!
/// - `Hashable`: Essendo `Identifiable`, è buona norma conformare anche ad `Hashable`. Ci permetterà
///   di usare i nostri esercizi in Set e Dizionari, o come chiavi se ce ne fosse bisogno in futuro.
struct ExerciseModel: Identifiable, Codable, Hashable {
    
    /// Perché usiamo `UUID` (Universally Unique Identifier)?
    /// Usare una semplice stringa o un intero sequenziale come ID può portare a conflitti
    /// (immagina due esercizi creati offline che prendono lo stesso ID 1!). 
    /// L'UUID ci garantisce una stringa complessa e praticamente impossibile da duplicare nell'universo,
    /// generata automaticamente per ogni nuovo esercizio.
    let id: UUID
    
    /// Il nome dell'esercizio (es. "Panca Piana").
    /// Usiamo `let` e non `var` perché, per buona pratica (immutabilità), i dati di base di un
    /// esercizio a catalogo non dovrebbero cambiare una volta creati, o verranno sostituiti integralmente.
    let name: String
    
    /// Una descrizione opzionale di come si esegue l'esercizio.
    /// È opzionale (`String?`), il che significa che l'utente o il sistema non sono forzati ad inserirla.
    /// Swift è un linguaggio sicuro: ti obbligherà sempre a scompattare questo valore in modo sicuro
    /// prima di usarlo (niente force unwrap `!`).
    let description: String?
    
    /// Il gruppo muscolare principalmente allenato dall'esercizio.
    let primaryMuscle: MuscleGroup
    
    /// Qualsiasi equipaggiamento che serve per l'esercizio (es. "Manubri", "Bilanciere", "A corpo libero").
    /// Per ora è una stringa semplice, in futuro potremmo espanderla in un altro Enum se lo ritenessimo utile!
    let equipmentRequirement: String?
    
    /// Costruttore di default.
    /// 
    /// Generiamo automaticamente l'id, così chi usa questa struct deve solo preoccuparsi
    /// di fornire le informazioni rilevanti dell'esercizio.
    init(id: UUID = UUID(), name: String, description: String? = nil, primaryMuscle: MuscleGroup, equipmentRequirement: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.primaryMuscle = primaryMuscle
        self.equipmentRequirement = equipmentRequirement
    }
}
