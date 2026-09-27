import SwiftUI

/// Reads live workout state so progress stays current if recovery ends while open.
struct WorkoutExerciseListView: View {
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(\.dismiss) private var dismiss
    let onSelect: (UUID) -> Bool

    var body: some View {
        NavigationStack {
            List {
                if let ongoing = workoutManager.ongoingWorkout {
                    Section {
                        ForEach(ongoing.remainingExerciseIndices, id: \.self) { index in
                            Button {
                                if onSelect(ongoing.activeExercises[index].id) { dismiss() }
                            } label: {
                                exerciseRow(at: index, ongoing: ongoing)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Da completare · \(ongoing.remainingExerciseIndices.count)")
                    } footer: {
                        Text(ongoing.isResting
                            ? "Scegli un esercizio per interrompere il recupero e iniziarlo. Le serie già fatte restano registrate."
                            : "Macchinario occupato? Scegli un altro esercizio. Quello attuale resta da fare e verrà riproposto.")
                    }
                    let completed = ongoing.activeExercises.indices.filter {
                        !ongoing.activeExercises[$0].sets.isEmpty && ongoing.pendingSetIndex(for: $0) == nil
                    }
                    if !completed.isEmpty {
                        Section("Completati · \(completed.count)") {
                            ForEach(completed, id: \.self) { index in
                                exerciseRow(at: index, ongoing: ongoing)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Il tuo allenamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func exerciseRow(at index: Int, ongoing: OngoingWorkoutState) -> some View {
        let exercise = ongoing.activeExercises[index]
        let completed = exercise.sets.filter { ongoing.completedSetIDs.contains($0.id) }.count
        let finished = completed == exercise.sets.count
        let current = index == ongoing.currentExIndex && !finished
        let deferred = (ongoing.deferredExerciseIDs ?? []).contains(exercise.id) && !finished
        return HStack(spacing: 12) {
            Image(systemName: finished ? "checkmark.circle.fill" : (current ? "play.circle.fill" : "circle"))
                .font(.title2)
                .foregroundStyle(finished ? Color.green : Color.accentColor)
            VStack(alignment: .leading, spacing: 5) {
                Text(exercise.baseExercise.name).font(.headline)
                Text("\(completed)/\(exercise.sets.count) serie completate")
                    .font(.subheadline).foregroundStyle(.secondary)
                if current {
                    Text(ongoing.isResting ? "Attuale · in recupero" : "In corso")
                        .font(.caption.weight(.semibold)).foregroundStyle(.tint)
                } else if deferred {
                    Text("Rimandato · da recuperare").font(.caption).foregroundStyle(.orange)
                }
            }
            Spacer(minLength: 0)
            if !finished { Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary) }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
