import re

with open('Frigo/Allenamento/Views/Screens/WorkoutActiveView.swift', 'r') as f:
    content = f.read()

# Replace variables and initialization
content = content.replace(
    "@Environment(WorkoutManager.self) private var workoutManager",
    "@Environment(WorkoutManager.self) private var workoutManager\n  @State private var viewModel: ActiveWorkoutViewModel?"
)

content = content.replace(
    "workoutManager.updateWorkoutLiveActivity(for: ongoing)",
    "workoutManager.updateWorkoutLiveActivity(for: ongoing)\n          if viewModel == nil { viewModel = ActiveWorkoutViewModel(workoutManager: workoutManager) }"
)

content = content.replace(
    ".onAppear {",
    ".onAppear {\n        if viewModel == nil { viewModel = ActiveWorkoutViewModel(workoutManager: workoutManager) }"
)

# We need a proper parsing for WorkoutActiveView. We are better off replacing the whole file using a python script with exact lines.
