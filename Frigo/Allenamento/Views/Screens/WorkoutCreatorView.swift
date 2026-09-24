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
                    .onMove { source, destination in
                        planExercises.move(fromOffsets: source, toOffset: destination)
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
                        let trimmedTitle = planTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedTitle.isEmpty, !planExercises.isEmpty else { return }
                        let newPlan = WorkoutPlan(
                            id: planToEdit?.id ?? UUID(),
                            title: trimmedTitle,
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
            
            TextField("Note (es. Focus sulla discesa)", text: $exercise.notes, axis: .vertical)
                .font(.footnote)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            Divider()
            
            Grid(alignment: .center, horizontalSpacing: 8, verticalSpacing: 12) {
                ForEach($exercise.sets) { $set in
                    let setIndex = exercise.sets.firstIndex(where: { $0.id == set.id }) ?? 0
                    
                    GridRow {
                        Text("\(setIndex + 1)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .gridColumnAlignment(.leading)
                        
                        HStack(spacing: 4) {
                            TextField("Kg", value: $set.targetWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(minWidth: 40)
                            Text("Kg").font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            TextField("Reps", value: $set.targetReps, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(minWidth: 40)
                            Text("Reps").font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            TextField("Sec", value: $set.restTimeInSeconds, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(minWidth: 40)
                            Image(systemName: "timer").font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                        
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
            
            Toggle(isOn: $exercise.isLinkedToNext) {
                Label("Esegui come Superset con il prossimo", systemImage: "link")
                    .font(.footnote)
                    .foregroundStyle(.purple)
            }
            .tint(.purple)
            .padding(.top, 8)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    WorkoutCreatorView()
        .environment(WorkoutManager())
        .environment(ThemeManager())
}
