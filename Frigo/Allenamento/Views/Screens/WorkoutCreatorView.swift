import SwiftUI

struct WorkoutCreatorView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(ThemeManager.self) private var themeManager
    
    // MARK: - Properties
    var planToEdit: WorkoutPlan?
    
    // MARK: - State
    @State private var planTitle: String
    @State private var planExercises: [WorkoutExercise]
    @State private var showPicker: Bool = false
    
    init(planToEdit: WorkoutPlan? = nil) {
        self.planToEdit = planToEdit
        _planTitle = State(initialValue: planToEdit?.title ?? "")
        _planExercises = State(initialValue: planToEdit?.exercises ?? [])
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // SEZIONE 1: Info Base
                Section {
                    TextField("Nome Scheda (es. Dorso)", text: $planTitle)
                }
                
                // SEZIONE 2: Dettaglio Esercizi
                Section {
                    ForEach($planExercises) { $exercise in
                        EditableExerciseRow(exercise: $exercise)
                    }
                    .onDelete { offsets in
                        planExercises.remove(atOffsets: offsets)
                    }
                } header: {
                    if !planExercises.isEmpty {
                        Text("Esercizi")
                    }
                }
                
                // SEZIONE 3: Azioni
                Section {
                    Button(action: {
                        showPicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Aggiungi Esercizio")
                        }
                        .font(.headline)
                        .foregroundStyle(themeManager.currentTheme.primaryColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle(planToEdit == nil ? "Nuova Scheda" : "Modifica Scheda")
            .sheet(isPresented: $showPicker) {
                ExercisePickerView(onExerciseSelected: { selectedExercise in
                    let defaultSet = WorkoutSet(targetReps: 10, targetWeight: nil, restTimeInSeconds: 90)
                    let newWorkoutExercise = WorkoutExercise(baseExercise: selectedExercise, sets: [defaultSet])
                    
                    withAnimation {
                        planExercises.append(newWorkoutExercise)
                    }
                })
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        guard !planTitle.isEmpty, !planExercises.isEmpty else { return }
                        
                        // Passiamo esplicitamente l'id precedente (se stiamo modificando) o uno nuovo (se la creiamo)
                        let newPlan = WorkoutPlan(
                            id: planToEdit?.id ?? UUID(),
                            title: planTitle,
                            exercises: planExercises
                        )
                        
                        // Il manager con "savePlan" è intelligente: se l'ID esiste, sovrascrive!
                        workoutManager.savePlan(newPlan)
                        dismiss()
                    }
                    .bold()
                    .disabled(planTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || planExercises.isEmpty)
                }
            }
        }
    }
}

// MARK: - SubViews

struct EditableExerciseRow: View {
    @Binding var exercise: WorkoutExercise
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            ExerciseRowView(exercise: exercise)
            
            Divider()
            
            VStack(spacing: 12) {
                ForEach($exercise.sets) { $set in
                    let setIndex = exercise.sets.firstIndex(where: { $0.id == set.id }) ?? 0
                    
                    HStack(alignment: .center, spacing: 8) {
                        Text("Set \(setIndex + 1)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .leading)
                        
                        TextField("Kg", value: $set.targetWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 70)
                        
                        Text("Kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 4)
                        
                        TextField("Reps", value: $set.targetReps, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 60)
                        
                        Text("Reps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer(minLength: 0)
                        
                        Button(action: {
                            withAnimation {
                                if let idx = exercise.sets.firstIndex(where: { $0.id == set.id }) {
                                    exercise.sets.remove(at: idx)
                                }
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            
            Button(action: {
                withAnimation {
                    // Mantieni i kg per la prossima serie (reattività base per comodità)
                    let lastSet = exercise.sets.last
                    let newSet = WorkoutSet(
                        targetReps: lastSet?.targetReps ?? 10,
                        targetWeight: lastSet?.targetWeight,
                        restTimeInSeconds: lastSet?.restTimeInSeconds ?? 90
                    )
                    exercise.sets.append(newSet)
                }
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Aggiungi Serie")
                }
                .font(.footnote.bold())
                .foregroundStyle(themeManager.currentTheme.primaryColor)
            }
            .buttonStyle(.borderless)
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    WorkoutCreatorView()
        .environment(WorkoutManager())
        .environment(ThemeManager())
}
