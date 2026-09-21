import Foundation

struct OngoingWorkoutState: Codable {
  var plan: WorkoutPlan

  // Lo stato attuale di carichi e reps scelti
  var activeExercises: [WorkoutExercise]

  // I set attualmente completati
  var completedSetIDs: Set<UUID>

  // Pointers navigazione
  var currentExIndex: Int
  var currentSetIndex: Int

  // Tempi Globale
  var startTime: Date

  // Tempi di riposo correnti
  var isResting: Bool
  var remainingRestSeconds: Int
  /// Data di fine riposo — usata dalla Live Activity (Dynamic Island) per il countdown.
  var restingEndTime: Date?
  var totalRestSeconds: Int
}
