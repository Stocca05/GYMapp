import SwiftUI

struct WorkoutNavigationBar: View {
    let ongoing: OngoingWorkoutState
    let onShowExercises: () -> Void
    let onDefer: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onShowExercises) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Da completare: \(ongoing.remainingExerciseIndices.count)", systemImage: "list.bullet")
                        .font(.subheadline.weight(.semibold))
                    Text("Vedi esercizi e scegli il prossimo")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button(action: onDefer) {
                Label("Rimanda", systemImage: "arrow.turn.down.right")
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .disabled(ongoing.nextAlternativeExerciseID == nil)
            .accessibilityHint("Passa a un altro esercizio. Quello attuale resta da completare.")
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}
