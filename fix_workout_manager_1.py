import re

with open("Frigo/Allenamento/Manager/WorkoutManager.swift", "r") as f:
    text = f.read()

# Add lastInteractionDate
text = text.replace(
    "var ongoingWorkout: OngoingWorkoutState?",
    "var ongoingWorkout: OngoingWorkoutState?\n\n  /// Traccia l'ultima interazione dell'utente per terminare automaticamente dopo 15m\n  var lastInteractionDate: Date = Date()"
)

# Add helper methods around startGlobalRestTimer
new_methods = """
  // MARK: - Inactivity Tracking
  
  func registerInteraction() {
    lastInteractionDate = Date()
  }

  func checkInactivityAndCancelIfNeeded() {
    guard ongoingWorkout != nil else { return }
    let elapsed = Date().timeIntervalSince(lastInteractionDate)
    if elapsed >= 900 { // 15 minuti = 15 * 60 = 900s
      cancelWorkoutGlobally()
    }
  }

  @MainActor
  func cancelWorkoutGlobally() {
    stopGlobalRestTimer()
    ongoingWorkout = nil
    NotificationCenter.default.post(name: Notification.Name("ForceCloseActivity"), object: nil)
  }

  private var restTask: Task<Void, Never>?
"""

text = text.replace("  private var restTask: Task<Void, Never>?", new_methods)


with open("Frigo/Allenamento/Manager/WorkoutManager.swift", "w") as f:
    f.write(text)

