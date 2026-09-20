import SwiftUI

/// Il "Cervello Globale" della sezione Allenamento (Manager / Data Controller).
///
/// Abbiamo fatto un upgrade notevole! Sfruttiamo le nuove macro di Apple `@Observable`.
/// In passato usavamo `ObservableObject` e mettevamo `@Published` davanti a ogni variabile.
/// Ora, con `@Observable` (introdotto in iOS 17), Swift fa tutto il tracciamento delle dipendenze
/// sotto il cofano, automaticamente. Si scrive meno codice, ci sono meno bug, ed è molto più
/// performante nel ri-disegnare la UI!
@Observable
class WorkoutManager {
    
    /// Il catalogo globale di tutti gli esercizi conosciuti dall'app.
    var exerciseDatabase: [ExerciseModel] = []
    
    /// Le schede di allenamento create e salvate (per ora in memoria) dall'utente.
    var myPlans: [WorkoutPlan] = []
    
    /// Inizializzatore del Manager.
    /// In un'app vera qui andremo a caricare i dati da una memoria persistente
    /// (SwiftData, CoreData o UserDefaults). Per questa primissima fase, lo usiamo 
    /// per "iniettare" dei dati finti (Mock Data) di modo da poter vedere la UI funzionare subito.
    init() {
        setupMockData()
    }
    
    /// Prepariamo dei dati spalla-a-spalla con i nostri nuovi modelli senza inquinare l'init principale.
    private func setupMockData() {
        // 1. Popoliamo l'exercise database con le informazioni enciclopediche.
        let panca = ExerciseModel(
            name: "Panca Piana con Bilanciere", 
            description: "Esercizio multiarticolare per la costruzione del gran pettorale.", 
            primaryMuscle: .chest, 
            equipmentRequirement: "Panca e Bilanciere"
        )
        let squat = ExerciseModel(
            name: "Squat", 
            description: "Il re della parte inferiore. Sviluppa quadricipiti e glutei potenti.", 
            primaryMuscle: .legs, 
            equipmentRequirement: "Rack e Bilanciere"
        )
        let trazioni = ExerciseModel(
            name: "Trazioni alla Sbarra", 
            description: "Esercizio base a corpo libero per l'ipertrofia del gran dorsale.", 
            primaryMuscle: .back, 
            equipmentRequirement: "Sbarra per Trazioni"
        )
        let military = ExerciseModel(
            name: "Military Press", 
            description: "Spinte verticali con bilanciere per rinforzare i deltoidi.", 
            primaryMuscle: .shoulders, 
            equipmentRequirement: "Bilanciere"
        )
        let curl = ExerciseModel(
            name: "Curl Bicipiti con Manubri", 
            description: "Classico esercizio di isolamento delle braccia.", 
            primaryMuscle: .arms, 
            equipmentRequirement: "Manubri"
        )
        let crunch = ExerciseModel(
            name: "Crunch a terra", 
            description: "Flessioni del busto per stimolare il retto dell'addome.", 
            primaryMuscle: .core, 
            equipmentRequirement: "Tappetino"
        )
        
        // Salviamo gli esercizi nel database di app
        exerciseDatabase = [panca, squat, trazioni, military, curl, crunch]
        
        // 2. Prepariamo una Scheda (WorkoutPlan) iniziale per evitare uno schermo vuoto all'avvio.
        
        // Serie per la Panca
        let setPanca1 = WorkoutSet(targetReps: 10, targetWeight: 60.0, restTimeInSeconds: 90)
        let setPanca2 = WorkoutSet(targetReps: 8, targetWeight: 65.0, restTimeInSeconds: 90)
        let setPanca3 = WorkoutSet(targetReps: 5, targetWeight: 72.5, restTimeInSeconds: 120)
        let exPanca = WorkoutExercise(baseExercise: panca, sets: [setPanca1, setPanca2, setPanca3])
        
        // Serie per le Trazioni (A corpo libero, weight rimane nil o omesso grazie agli Optionals)
        let setTrazioni1 = WorkoutSet(targetReps: 8, targetWeight: nil, restTimeInSeconds: 90)
        let setTrazioni2 = WorkoutSet(targetReps: 7, targetWeight: nil, restTimeInSeconds: 90)
        let exTrazioni = WorkoutExercise(baseExercise: trazioni, sets: [setTrazioni1, setTrazioni2])
        
        // Creazione finale della scheda che verrà mostrata sulla Home della Palestra
        let planMock = WorkoutPlan(
            title: "Petto e Dorso (Forza)", 
            exercises: [exPanca, exTrazioni], 
            colorTheme: "blue" // Poi questo diventerà un colore vero nella UI
        )
        
        // Inseriamo la scheda finta in memoria
        myPlans.append(planMock)
    }
    
    // MARK: - Funzioni di Utilità (Helpers)
    
    /// Salva o aggiorna una scheda utente in memoria.
    ///
    /// Se la scheda esiste già (cerchiamo il suo `id` in `myPlans`), SwiftUI e la logica se ne accorgono,
    /// e andiamo a rimpiazzarla. Se il match `.firstIndex(where:)` ritorna nil, si tratta di 
    /// una scheda appena creata, e invochiamo fieri un semplice `.append`. Pulitissimo!
    func savePlan(_ plan: WorkoutPlan) {
        if let index = myPlans.firstIndex(where: { $0.id == plan.id }) {
            // Aggiorna l'esistente
            myPlans[index] = plan
        } else {
            // Aggiungi una nuova scheda
            myPlans.append(plan)
        }
    }
    
    /// Rimuove comodamente le schede dalla struttura dati, ideale per l'integrazione
    /// col modifier `.onDelete(perform:)` della SwiftUI List, che restituisce appunto un IndexSet.
    func deletePlan(at offsets: IndexSet) {
        myPlans.remove(atOffsets: offsets)
    }
    
    /// Analizza logicamente una Scheda per estrarne i gruppi muscolari allenati, senza duplicati.
    ///
    /// Utilissima ad esempio per scrivere sulle Card esterne della Home "Petto, Gambe".
    /// Utilizzando un Array preserviamo l'ordine in cui i muscoli vengono attaccati
    /// (cosa che un Set, ad esempio, ci farebbe perdere).
    func extractTargetMuscleGroups(from plan: WorkoutPlan) -> [MuscleGroup] {
        var unqiueGroups: [MuscleGroup] = []
        
        for element in plan.exercises {
            let targetMuscle = element.baseExercise.primaryMuscle
            // Selezioniamo solo i muscoli non ancora inseriti
            if !unqiueGroups.contains(targetMuscle) {
                unqiueGroups.append(targetMuscle)
            }
        }
        
        return unqiueGroups
    }
}
