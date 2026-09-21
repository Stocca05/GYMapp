import re

with open("Frigo/Allenamento/Views/Screens/WorkoutActiveView.swift", "r") as f:
    text = f.read()

# Fix update
text = text.replace(
    'await activity.update(using: state)', 
    'await activity.update(ActivityContent(state: state, staleDate: nil))'
)

# Fix request
text = text.replace(
    'contentState: state,',
    'content: ActivityContent(state: state, staleDate: nil),'
)

# Fix end (requires a state)
text = re.sub(
    r'await activity\.end\(using: nil, dismissalPolicy: \.immediate\)',
    'await activity.end(ActivityContent(state: activity.content.state, staleDate: nil), dismissalPolicy: .immediate)',
    text
)

text = re.sub(
    r'await activity.end\(using: nil, dismissalPolicy: \.immediate\)',
    'await activity.end(ActivityContent(state: activity.content.state, staleDate: nil), dismissalPolicy: .immediate)',
    text
)

# wait there is a potential issue with `.content` properties, if `activity.content` is not available, we can just pass `nil` if we don't have it, but wait: `Activity.end` can simply dismiss the activity.
# `await activity.end(nil, dismissalPolicy: .immediate)` is valid in iOS 16.2+
with open("Frigo/Allenamento/Views/Screens/WorkoutActiveView.swift", "w") as f:
    f.write(text)

