import re

with open("FrigoWidget/FrigoWidget.swift", "r") as f:
    text = f.read()

old_trailing = """            } compactTrailing: {
                Text(timerInterval: context.state.startTime...context.state.restingEndTime, countsDown: true)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 40)
                    .font(.caption2.monospacedDigit())
            } minimal: {"""

new_trailing = """            } compactTrailing: {
                Text(timerInterval: context.state.startTime...context.state.restingEndTime, countsDown: true)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .font(.body)
                    .foregroundColor(.orange)
                    .padding(.trailing, 4)
            } minimal: {"""

text = text.replace(old_trailing, new_trailing)

with open("FrigoWidget/FrigoWidget.swift", "w") as f:
    f.write(text)

