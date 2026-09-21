import re

with open("Frigo/Allenamento/Views/Screens/WorkoutActiveView.swift", "r") as f:
    text = f.read()

# Auto dismiss when workout is nil
old_else = """    } else {
      VStack(spacing: 16) {
        Text("Nessun allenamento in corso")
          .font(.headline)
        Button("Chiudi") { dismiss() }
          .buttonStyle(.borderedProminent)
      }
    }"""

new_else = """    } else {
      VStack(spacing: 16) {
        Text("Nessun allenamento in corso")
          .font(.headline)
      }
      .onAppear { dismiss() }
    }"""
text = text.replace(old_else, new_else)

# Also force close live activity in endLiveActivity globally? Wait, we do have NotificationCenter.
# Add .onReceiveForceCloseActivity to ZStack or below
receive_close = """      .onReceive(
        NotificationCenter.default.publisher(for: Notification.Name("ForceCloseActivity"))
      ) { _ in
        endLiveActivity()
        dismiss()
      }
      .onReceive("""
text = text.replace("      .onReceive(", receive_close, 1)

text = text.replace("  private func completeCurrentSetAndRest(setId: UUID, restSeconds: Int, isLast: Bool) {", "  private func completeCurrentSetAndRest(setId: UUID, restSeconds: Int, isLast: Bool) {\n    workoutManager.registerInteraction()")
text = text.replace("  private func advanceWorkoutState() {", "  private func advanceWorkoutState() {\n    workoutManager.registerInteraction()")
text = text.replace("  private func adjustWeight(by amount: Double) {", "  private func adjustWeight(by amount: Double) {\n    workoutManager.registerInteraction()")
text = text.replace("  private func adjustReps(by amount: Int) {", "  private func adjustReps(by amount: Int) {\n    workoutManager.registerInteraction()")

with open("Frigo/Allenamento/Views/Screens/WorkoutActiveView.swift", "w") as f:
    f.write(text)

