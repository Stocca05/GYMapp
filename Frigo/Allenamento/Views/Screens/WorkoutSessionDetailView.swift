import SwiftUI

struct WorkoutSessionDetailView: View {
  let session: WorkoutSession

  var body: some View {
    List {
      Section {
        Text(session.date, format: .dateTime.day().month(.wide).year().hour().minute())
          .font(.headline)
        LabeledContent("Durata", value: "\(session.durationSeconds / 60) min")
        LabeledContent("Volume", value: "\(session.totalVolume.formatted()) kg × rip.")
      }
      if session.completedExercises.isEmpty {
        Section {
          Label("Questa seduta non contiene il dettaglio degli esercizi.", systemImage: "info.circle")
            .foregroundStyle(.secondary)
        }
      }
      ForEach(session.completedExercises) { exercise in
        Section(exercise.baseExercise.name) {
          if !exercise.notes.isEmpty {
            Text("Note: \(exercise.notes)")
              .font(.footnote)
              .foregroundColor(.secondary)
              .italic()
          }
          WorkoutSetHistoryRows(sets: exercise.sets)
        }
      }
    }
    .navigationTitle("Dettaglio seduta")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct WorkoutSetHistoryRows: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  let sets: [WorkoutSet]

  var body: some View {
    ForEach(Array(sets.enumerated()), id: \.offset) { index, set in
      let layout = dynamicTypeSize.isAccessibilitySize
        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6)) : AnyLayout(HStackLayout())
      layout {
        Text("Serie \(index + 1)").foregroundStyle(.secondary)
        if !dynamicTypeSize.isAccessibilitySize { Spacer() }
        Text(set.targetWeight.map { ProgressMetric.maxWeight.formatted($0) } ?? "Carico non registrato")
        Text("× \(set.targetReps) rip.")
      }
      .font(.subheadline.monospacedDigit())
      .accessibilityElement(children: .combine)
    }
  }
}
