import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(ThemeManager.self) private var themeManager
    
    @State private var searchText: String = ""
    
    var onExerciseSelected: ((ExerciseModel) -> Void)
    
    var filteredExercises: [ExerciseModel] {
        if searchText.isEmpty {
            return workoutManager.exerciseDatabase
        } else {
            return workoutManager.exerciseDatabase.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredExercises) { exercise in
                    Button {
                        onExerciseSelected(exercise)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.headline)
                                .foregroundStyle(themeManager.currentTheme.textColor)
                            
                            Text(exercise.primaryMuscle.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(themeManager.currentTheme.secondaryColor)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Cerca esercizio...")
            .navigationTitle("Seleziona Esercizio")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                    // OPZIONALE: si potrebbe utilizzare il colore primario per il bottone Annulla
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
                }
            }
        }
    }
}
