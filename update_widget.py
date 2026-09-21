import re

with open("FrigoWidget/FrigoWidget.swift", "r") as f:
    text = f.read()

# Replace block starting from the ActivityConfiguration HStack
old_activity = """        ActivityConfiguration(for: WorkoutTimerAttributes.self) { context in
            // Lock screen / banner presentation
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Recupero \(context.attributes.planName)")
                        .font(.headline)
                    Text("Prossimo: \(context.state.exerciseName)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                Text(timerInterval: context.state.startTime...context.state.restingEndTime, countsDown: true)
                    .multilineTextAlignment(.trailing)
                    .font(.system(.title, design: .rounded).monospacedDigit().weight(.bold))
            }
            .padding()
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "dumbbell.fill")
                            .foregroundColor(.orange)
                        Text("Recupero")
                            .font(.headline)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.startTime...context.state.restingEndTime, countsDown: true)
                        .multilineTextAlignment(.trailing)
                        .font(.system(.title2, design: .rounded).monospacedDigit().weight(.bold))
                        .foregroundColor(.orange)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Prossimo: \(context.state.exerciseName)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
            } compactTrailing: {
                Text(timerInterval: context.state.startTime...context.state.restingEndTime, countsDown: true)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .font(.body)
                    .foregroundColor(.orange)
                    .padding(.trailing, 4)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
            }
        }"""

new_activity = """        ActivityConfiguration(for: WorkoutTimerAttributes.self) { context in
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
        }"""

text = text.replace(old_activity, new_activity)
with open("FrigoWidget/FrigoWidget.swift", "w") as f:
    f.write(text)
