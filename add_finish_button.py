import re

with open("Frigo/Allenamento/Views/Screens/WorkoutActiveView.swift", "r") as f:
    text = f.read()

# ADD THE STATE
text = text.replace(
    "@State private var progressExercise: ExerciseModel?",
    "@State private var progressExercise: ExerciseModel?\n  @State private var showConcludeAlert = false"
)

# ADD THE ALERT
alert_code = """      }
      .alert("Termina Allenamento", isPresented: $showConcludeAlert) {
        Button("Termina", role: .destructive) {
          if let ongoing = workoutManager.ongoingWorkout {
            concludeWorkout(ongoing: ongoing)
          }
        }
        Button("Annulla", role: .cancel) {}
      } message: {
        Text("Vuoi concludere l'allenamento in anticipo? Le serie completate verranno salvate nello storico.")
      }
      .onReceive("""

text = text.replace("      }\n      .onReceive(", alert_code)

# MODIFY THE HEADER
header_search = """      Button {
        progressExercise = ongoing.activeExercises[ongoing.currentExIndex].baseExercise
      } label: {
        Image(systemName: "chart.xyaxis.line")
          .font(.title2)
          .frame(width: 44, height: 44)
          .foregroundStyle(themeManager.currentTheme.primaryColor)
      }
      .accessibilityLabel("Progressi dell’esercizio")"""

header_replace = """      Button {
        progressExercise = ongoing.activeExercises[ongoing.currentExIndex].baseExercise
      } label: {
        Image(systemName: "chart.xyaxis.line")
          .font(.title2)
          .frame(width: 44, height: 44)
          .foregroundStyle(themeManager.currentTheme.primaryColor)
      }
      .accessibilityLabel("Progressi dell’esercizio")
      
      Button(action: {
        showConcludeAlert = true
      }) {
        Text("Fine")
          .font(.headline)
          .foregroundColor(.red)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(Color.red.opacity(0.15))
          .clipShape(Capsule())
      }"""

text = text.replace(header_search, header_replace)

with open("Frigo/Allenamento/Views/Screens/WorkoutActiveView.swift", "w") as f:
    f.write(text)
