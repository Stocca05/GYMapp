import WidgetKit
import SwiftUI
import ActivityKit

// L'Isola Dinamica mostrerà un timer quando ti riposi
struct FrigoWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutTimerAttributes.self) { context in
            // Lock screen / banner presentation
            HStack {
                Image(systemName: context.state.isResting ? "timer" : "figure.strengthtraining.traditional")
                    .foregroundColor(context.state.isResting ? .orange : .green)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(context.state.isResting ? "Recupero \(context.attributes.planName)" : "Allenamento in corso")
                        .font(.headline)
                    Text(context.state.isResting ? "Prossimo: \(context.state.exerciseName)" : "\(context.state.exerciseName)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                if context.state.isResting {
                    Text(timerInterval: context.state.startTime...context.state.restingEndTime, countsDown: true)
                        .multilineTextAlignment(.trailing)
                        .font(.system(.title, design: .rounded).monospacedDigit().weight(.bold))
                } else {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.red)
                }
            }
            .padding()
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: context.state.isResting ? "timer" : "figure.strengthtraining.traditional")
                            .foregroundColor(context.state.isResting ? .orange : .green)
                        Text(context.state.isResting ? "Recupero" : "In corso")
                            .font(.headline)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isResting {
                        Text(timerInterval: context.state.startTime...context.state.restingEndTime, countsDown: true)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.title2, design: .rounded).monospacedDigit().weight(.bold))
                            .foregroundColor(.orange)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.isResting ? "Prossimo: \(context.state.exerciseName)" : "\(context.state.exerciseName)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } compactLeading: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(context.state.isResting ? .orange : .green)
                    .padding(.leading, 4)
            } compactTrailing: {
                if context.state.isResting {
                    Text(timerInterval: context.state.startTime...context.state.restingEndTime, countsDown: true)
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                        .font(.body)
                        .foregroundColor(.orange)
                        .padding(.trailing, 4)
                } else {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.red)
                        .padding(.trailing, 4)
                }
            } minimal: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(context.state.isResting ? .orange : .green)
            }
        }
    }
}
