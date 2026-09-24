import os

with open('Frigo/Allenamento/Views/Screens/WorkoutActiveView.swift', 'r') as f:
    text = f.read()

# Replace the beginning of the struct
text = text.replace(
"""struct WorkoutActiveView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(WorkoutManager.self) private var workoutManager
  @Environment(ThemeManager.self) private var themeManager""",
"""struct WorkoutActiveView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(WorkoutManager.self) private var workoutManager
  @Environment(ThemeManager.self) private var themeManager
  @State private var viewModel: ActiveWorkoutViewModel? """
)

# Fix onAppear
text = text.replace(
""".onAppear {
        guard let ongoing = workoutManager.ongoingWorkout else { return }""",
""".onAppear {
        if viewModel == nil { viewModel = ActiveWorkoutViewModel(workoutManager: workoutManager) }
        guard let ongoing = workoutManager.ongoingWorkout else { return }"""
)

# And now we replace the method calls inside body:
text = text.replace("changeSetType(to:", "viewModel?.changeSetType(to:")
text = text.replace("changeRPE(to:", "viewModel?.changeRPE(to:")
text = text.replace("adjustWeight(by:", "viewModel?.adjustWeight(by:")
text = text.replace("adjustReps(by:", "viewModel?.adjustReps(by:")
text = text.replace("adjustTimer(by:", "viewModel?.adjustTimer(by:")
text = text.replace("playSoundAndVibrate()", "viewModel?.playSoundAndVibrate()")
text = text.replace("advanceWorkoutState()", "viewModel?.advanceWorkoutState()")

# Special handling for notes:
note_binding_old = """      TextField("Aggiungi note (es. set up, dolore...)", text: Binding(
          get: { exercise.notes },
          set: { newValue in
              guard var ongoing = workoutManager.ongoingWorkout else { return }
              ongoing.activeExercises[ongoing.currentExIndex].notes = newValue
              workoutManager.ongoingWorkout = ongoing
          }
      ), axis: .vertical)"""
      
note_binding_new = """      TextField("Aggiungi note (es. set up, dolore...)", text: Binding(
          get: { exercise.notes },
          set: { newValue in
              guard let ongoing = workoutManager.ongoingWorkout else { return }
              viewModel?.updateNote(for: ongoing.currentExIndex, text: newValue)
          }
      ), axis: .vertical)"""

text = text.replace(note_binding_old, note_binding_new)

# Next peek
text = text.replace("peekNextSet(ongoing: ongoing)", "viewModel?.peekNextSet(ongoing: ongoing)")

# Next Sequence
text = text.replace("findNextSequencePosition(fromEx: ongoing.currentExIndex, fromSet: ongoing.currentSetIndex, ongoing: ongoing)", "(viewModel?.findNextSequencePosition(fromEx: ongoing.currentExIndex, fromSet: ongoing.currentSetIndex, ongoing: ongoing) ?? nil)")

# Complete set
complete_set_old = """completeCurrentSetAndRest(
          setId: currentSet.id, restSeconds: currentSet.restTimeInSeconds, isLast: isAbsoluteLast, isSupersetLink: isSupersetLink, nextPos: nextPos)"""
complete_set_new = """viewModel?.completeCurrentSetAndRest(
          setId: currentSet.id, restSeconds: currentSet.restTimeInSeconds, isLast: isAbsoluteLast, isSupersetLink: isSupersetLink, nextPos: nextPos, onConclude: {
              if let ongoing = workoutManager.ongoingWorkout {
                  viewModel?.concludeWorkout(ongoing: ongoing) { dismiss() }
              }
          })"""
text = text.replace(complete_set_old, complete_set_new)

conclude_old = """concludeWorkout(ongoing: ongoing)"""
conclude_new = """viewModel?.concludeWorkout(ongoing: ongoing) { dismiss() }"""
text = text.replace(conclude_old, conclude_new)

# Find where MARK: - Logic starts and truncate everything until the end of the file except the final brace.
import re
text = re.sub(r'  // MARK: - Logic(.*?)\n}$', '\n}', text, flags=re.DOTALL)

with open('Frigo/Allenamento/Views/Screens/WorkoutActiveView.swift', 'w') as f:
    f.write(text)

