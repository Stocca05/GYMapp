import re

with open("Frigo/Allenamento/Views/Screens/WorkoutActiveView.swift", "r") as f:
    text = f.read()

# 1. Update startOrUpdateLiveActivity
old_start = """  private func startOrUpdateLiveActivity(restSeconds: Int, ongoing: OngoingWorkoutState) {
    let futureEnd = Date().addingTimeInterval(TimeInterval(restSeconds))
    let nextExerciseTitle = peekNextSet(ongoing: ongoing) ?? "Fine Allenamento"

    let state = WorkoutTimerAttributes.ContentState(
      startTime: Date(), restingEndTime: futureEnd, exerciseName: nextExerciseTitle)"""

new_start = """  private func startOrUpdateLiveActivity(ongoing: OngoingWorkoutState) {
    let restSeconds = ongoing.isResting ? ongoing.remainingRestSeconds : 0
    let futureEnd = ongoing.isResting ? Date().addingTimeInterval(TimeInterval(restSeconds)) : Date()
    let nextExerciseTitle = peekNextSet(ongoing: ongoing) ?? "Fine Allenamento"

    let state = WorkoutTimerAttributes.ContentState(
      startTime: Date(), restingEndTime: futureEnd, exerciseName: nextExerciseTitle, isResting: ongoing.isResting)"""

text = text.replace(old_start, new_start)

# 2. Fix the caller in completeCurrentSetAndRest
text = text.replace("startOrUpdateLiveActivity(restSeconds: restSeconds, ongoing: ongoing)", "startOrUpdateLiveActivity(ongoing: ongoing)")

# 3. Fix the callers inside onReceive for RestFinishedGlobally (advanceWorkoutState doesn't pass the timer usually, let's see)
# oh wait, inside onReceive:
# But we need to call startOrUpdateLiveActivity(ongoing: ongoing) inside advanceWorkoutState!
old_advance = """    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
      workoutManager.ongoingWorkout = ongoing
    }
  }"""
new_advance = """    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
      workoutManager.ongoingWorkout = ongoing
    }
    startOrUpdateLiveActivity(ongoing: ongoing)
  }"""
text = text.replace(old_advance, new_advance)

# Wait, advanceWorkoutState calls endLiveActivity! We must remove endLiveActivity from advanceWorkoutState.
# Let's search advanceWorkoutState
old_adv2 = """  private func advanceWorkoutState() {
    workoutManager.registerInteraction()
    endLiveActivity()

    guard var ongoing = workoutManager.ongoingWorkout else { return }"""

new_adv2 = """  private func advanceWorkoutState() {
    workoutManager.registerInteraction()

    guard var ongoing = workoutManager.ongoingWorkout else { return }"""
text = text.replace(old_adv2, new_adv2)


# 4. In onAppear, we need to call startOrUpdateLiveActivity to launch it immediately
old_onappear = """      .onAppear {
        if let o = workoutManager.ongoingWorkout, o.isResting, o.remainingRestSeconds <= 0 {
          advanceWorkoutState()
        }
      }"""
new_onappear = """      .onAppear {
        if let o = workoutManager.ongoingWorkout {
          if o.isResting && o.remainingRestSeconds <= 0 {
            advanceWorkoutState()
          } else {
            startOrUpdateLiveActivity(ongoing: o)
          }
        }
      }"""
text = text.replace(old_onappear, new_onappear)

with open("Frigo/Allenamento/Views/Screens/WorkoutActiveView.swift", "w") as f:
    f.write(text)

