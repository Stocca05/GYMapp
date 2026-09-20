import SwiftUI

struct WorkoutCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(ThemeManager.self) private var themeManager
    
    var planToEdit: WorkoutPlan?
    
    @State private var planTitle: String
    @State private var planExercises: [WorkoutExercise]
    @State private var showPicker: Bool = false
    
    init(planToEdit: WorkoutPlan? = nil) {
        self.planToEdit = planToEdit
        _planTitle = State(initialValue: planToEdit?.title ?? "")
        _planExercises = State(initialValue: planToEdit?.exercises ?? [])
    }
    
    // DRY: Sfruttiamo la logica già presente nel modello WorkoutPlan
    private var liveEstimatedDurationInMinutes: Int {
        WorkoutPlan(title: "Temp", exercises: planExercises).estimatedDurationInMinutes
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome Scheda (es. Dorso)", text: $planTitle)
                } footer: {
                    if liveEstimatedDurationInMinutes > 0 {
                        Text("Tempo stimato: ~\(liveEstimatedDurationInMinutes) min")
                            .font(.caption)
                    }
                }
                
                Section {
                    ForEach($planExercises) { $exercise in
                        EditableExerciseRow(exercise: $exercise)
                    }
                    .onDelete { offsets in
                        planExercises.remove(atOffsets: offsets)
                    }
                } header: {
                    if !planExercises.isEmpty { Text("Esercizi") }
                }
                
                Section {
                    Button(action: { showPicker = true }) {
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
                    Button("Annulla") { dismiss() }
                        .foregroundStyle(themeManager.currentTheme.primaryColor)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        guard !planTitle.isEmpty, !planExercises.isEmpty else { return }
                        let newPlan = WorkoutPlan(
                            id: planToEdit?.id ?? UUID(),
                            title: planTitle,
                            exercises: planExercises
                        )
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
                    
                    HStack(alignment: .center, spacing: 6) {
                        Text("\(setIndex + 1)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 14, alignment: .leading)
                        
                        TextField("Kg", value: $set.targetWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 55)
                        Text("Kg").font(.system(size: 10)).foregroundStyle(.secondary)
                        
                        TextField("Reps", value: $set.targetReps, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 45)
                        Text("Reps").font(.system(size: 10)).foregroundStyle(.secondary)
                        
                        TextField("Sec", value: $set.restTimeInSeconds, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 50)
                        Image(systemName: "timer").font(.system(size: 10)).foregroundStyle(.secondary)
                        
                        Spacer(minLength: 0)
                        
                        Button(action: {
                            withAnimation {
                                if let idx = exercise.sets.firstIndex(where: { $0.id == set.id }) {
                                    exercise.sets.remove(at: idx)
                                }
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.body)
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            
            Button(action: {
                withAnimation {
                    // Imposta gli attributi copiandoli dall'ultimo set, se disponibile
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
