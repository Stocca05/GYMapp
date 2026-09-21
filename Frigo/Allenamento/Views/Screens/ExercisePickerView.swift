import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(ThemeManager.self) private var themeManager
    
    @State private var searchText: String = ""
    @State private var showAddCustom: Bool = false
    var onExerciseSelected: ((ExerciseModel) -> Void)
    
    // Raggruppiamo per muscolo per rendere la UI più lussuosa
    var groupedExercises: [(muscle: MuscleGroup, exercises: [ExerciseModel])] {
        let sourceList = searchText.isEmpty 
            ? workoutManager.exerciseDatabase 
            : workoutManager.exerciseDatabase.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            
        let grouped = Dictionary(grouping: sourceList, by: { $0.primaryMuscle })
        // Ritorno ordinato alfabeticamente per nome del muscolo
        return grouped.map { (muscle: $0.key, exercises: $0.value) }
            .sorted { $0.muscle.rawValue < $1.muscle.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(groupedExercises, id: \.muscle) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            
                            // Intestazione Sezione Muscolo
                            Text(group.muscle.rawValue)
                                .font(.title3.weight(.heavy))
                                .foregroundColor(themeManager.currentTheme.textColor)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Lista di Esercizi (Griglia 1 Colonna stile Card)
                            ForEach(group.exercises) { exercise in
                                Button(action: {
                                    onExerciseSelected(exercise)
                                    dismiss()
                                }) {
                                    CatalogExerciseRow(exercise: exercise)
                                }
                                .buttonStyle(CatalogButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
            .searchable(text: $searchText, prompt: "Cerca esercizio...")
            .navigationTitle("Catalogo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                        .foregroundStyle(themeManager.currentTheme.primaryColor)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddCustom = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(themeManager.currentTheme.primaryColor)
                }
            }
            .sheet(isPresented: $showAddCustom) {
                AddCustomExerciseView()
            }
        }
    }
}

// MARK: - Add Custom Exercise View
struct AddCustomExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(ThemeManager.self) private var themeManager
    
    @State private var name = ""
    @State private var description = ""
    @State private var equipment = ""
    @State private var primaryMuscle: MuscleGroup = .chest
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Dettagli") {
                    TextField("Nome Esercizio", text: $name)
                    TextField("Equipaggiamento (es. Manubri)", text: $equipment)
                    TextField("Note / Descrizione (Opzionale)", text: $description)
                }
                
                Section("Gruppo Muscolare") {
                    Picker("Muscolo Principale", selection: $primaryMuscle) {
                        ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                            Text(muscle.rawValue).tag(muscle)
                        }
                    }
                }
            }
            .navigationTitle("Nuovo Esercizio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        let newEx = ExerciseModel(
                            name: trimmed,
                            description: description.isEmpty ? "Esercizio personalizzato" : description,
                            primaryMuscle: primaryMuscle,
                            equipmentRequirement: equipment.isEmpty ? "Nessuno" : equipment
                        )
                        workoutManager.addCustomExercise(newEx)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Row Dedicata al Catalogo

/// Una riga specifica per il catalogo, molto simile a ExerciseRowView
/// ma studiata per l'ExerciseModel nudo e crudo, con predisposizione immagini.
struct CatalogExerciseRow: View {
    @Environment(ThemeManager.self) private var themeManager
    let exercise: ExerciseModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Immagine Banner o Icona Sostitutiva
            if let imageName = exercise.imageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(themeManager.currentTheme.primaryColor.opacity(0.12))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: exercise.primaryMuscle.iconName)
                        .font(.title2.weight(.medium))
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                if let equipment = exercise.equipmentRequirement {
                    Text(equipment)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                } else {
                    Text("Equipment N/A")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryColor.opacity(0.5))
                }
            }
            
            Spacer()
            
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundColor(themeManager.currentTheme.primaryColor)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground).opacity(0.5))
        )
    }
}

// MARK: - Stile Bottone Effetto Tap
struct CatalogButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    ExercisePickerView(onExerciseSelected: { _ in })
        .environment(WorkoutManager())
        .environment(ThemeManager())
}
