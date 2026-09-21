import Foundation

struct WorkoutPlan: Identifiable, Codable, Hashable {
    
    let id: UUID
    var title: String
    var exercises: [WorkoutExercise]
    // TODO: Collegare colorTheme a un colore reale nella UI (attualmente non utilizzato)
    var colorTheme: String
    
    var estimatedDurationInMinutes: Int {
        var totalSeconds = 0
        let averageSecondsPerSetExecution = 30 // Stimiamo 30 secondi esecutivi puri per ogni serie
        
        for (exIndex, exercise) in exercises.enumerated() {
            for (setIndex, set) in exercise.sets.enumerated() {
                // Aggiungo il tempo di performance vivo (le ripetizioni fisiche)
                totalSeconds += averageSecondsPerSetExecution
                
                // Aggiungo il tempo di recupero della serie (anche l'ultima serie dell'esercizio, 
                // così funge da recupero prima di passare all'attrezzo successivo).
                // Ignoriamo solo il primissimo set o, in modo più preciso, ignoriamo il riposo dell'ultimissima serie della scheda intera!
                let isVeryLastSetOfWorkout = (exIndex == exercises.count - 1) && (setIndex == exercise.sets.count - 1)
                if !isVeryLastSetOfWorkout {
                    totalSeconds += set.restTimeInSeconds
                }
            }
        }
        
        return totalSeconds / 60
    }
    
    init(id: UUID = UUID(), 
         title: String, 
         exercises: [WorkoutExercise] = [], 
         colorTheme: String = "blue") {
        self.id = id
        self.title = title
        self.exercises = exercises
        self.colorTheme = colorTheme
    }
}
