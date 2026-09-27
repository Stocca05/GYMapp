import SwiftUI

@Observable
final class ActiveWorkoutViewModel {
    var workoutManager: WorkoutManager
    var healthManager: HealthManager?
    
    init(workoutManager: WorkoutManager, healthManager: HealthManager? = nil) {
        self.workoutManager = workoutManager
        self.healthManager = healthManager
    }
    
    func changeSetType(to type: SetType) {
        workoutManager.registerInteraction()
        guard var ongoing = workoutManager.ongoingWorkout else { return }
        let exIdx = ongoing.currentExIndex
        let setIdx = ongoing.currentSetIndex
        ongoing.activeExercises[exIdx].sets[setIdx].setType = type
        workoutManager.ongoingWorkout = ongoing
    }
    
    func changeRPE(to type: Int?) {
        workoutManager.registerInteraction()
        guard var ongoing = workoutManager.ongoingWorkout else { return }
        let exIdx = ongoing.currentExIndex
        let setIdx = ongoing.currentSetIndex
        ongoing.activeExercises[exIdx].sets[setIdx].rpe = type
        workoutManager.ongoingWorkout = ongoing
    }
    
    func adjustTimer(by seconds: Int) {
        guard var ongoing = workoutManager.ongoingWorkout else { return }
        let currentRemaining = max(
            0,
            Int(ceil((ongoing.restingEndTime ?? Date()).timeIntervalSinceNow))
        )
        let newTime = max(1, currentRemaining + seconds)

        ongoing.totalRestSeconds = max(ongoing.totalRestSeconds, newTime)
        ongoing.remainingRestSeconds = newTime
        ongoing.restingEndTime = Date().addingTimeInterval(TimeInterval(newTime))
        
        withAnimation(.spring()) {
            workoutManager.ongoingWorkout = ongoing
        }
        
        workoutManager.updateWorkoutLiveActivity(for: ongoing)

        if let restingEndTime = ongoing.restingEndTime {
            workoutManager.scheduleRestCompletionNotification(at: restingEndTime)
        }
    }
    
    func findNextSequencePosition(fromEx: Int, fromSet: Int, ongoing: OngoingWorkoutState) -> (Int, Int)? {
        WorkoutSequence.nextPending(afterExercise: fromEx, set: fromSet, ongoing: ongoing)
    }
    
    func completeCurrentSetAndRest(setId: UUID, restSeconds: Int, onConclude: () -> Void) {
        workoutManager.registerInteraction()
        guard var ongoing = workoutManager.ongoingWorkout,
              ongoing.activeExercises.indices.contains(ongoing.currentExIndex),
              ongoing.activeExercises[ongoing.currentExIndex].sets.indices.contains(ongoing.currentSetIndex),
              ongoing.activeExercises[ongoing.currentExIndex].sets[ongoing.currentSetIndex].id == setId,
              !ongoing.isResting, !ongoing.completedSetIDs.contains(setId) else { return }

        ongoing.completedSetIDs.insert(setId)
        let next = findNextSequencePosition(fromEx: ongoing.currentExIndex, fromSet: ongoing.currentSetIndex, ongoing: ongoing)
        guard let next else {
            workoutManager.ongoingWorkout = ongoing
            onConclude()
            return
        }
        let isSupersetLink = WorkoutSequence.isSupersetTransition(
            fromExercise: ongoing.currentExIndex, set: ongoing.currentSetIndex,
            to: next, exercises: ongoing.activeExercises)
        if isSupersetLink || restSeconds <= 0 {
            ongoing.currentExIndex = next.0
            ongoing.currentSetIndex = next.1
            ongoing.isResting = false
            ongoing.restingEndTime = nil
        } else {
            ongoing.totalRestSeconds = restSeconds
            ongoing.remainingRestSeconds = restSeconds
            ongoing.isResting = true
            ongoing.restingEndTime = Date().addingTimeInterval(TimeInterval(restSeconds))
        }
        withAnimation(.spring()) { workoutManager.ongoingWorkout = ongoing }
        if ongoing.isResting { workoutManager.startGlobalRestTimer() }
        workoutManager.updateWorkoutLiveActivity(for: ongoing)
    }

    @discardableResult
    func selectExercise(id: UUID) -> Bool {
        guard var ongoing = workoutManager.ongoingWorkout,
              let index = ongoing.activeExercises.firstIndex(where: { $0.id == id }),
              let set = ongoing.pendingSetIndex(for: index) else { return false }
        workoutManager.registerInteraction()
        workoutManager.stopGlobalRestTimer()
        var deferred = ongoing.deferredExerciseIDs ?? []
        if index != ongoing.currentExIndex, ongoing.pendingSetIndex(for: ongoing.currentExIndex) != nil {
            deferred.insert(ongoing.activeExercises[ongoing.currentExIndex].id)
        }
        deferred.remove(id)
        ongoing.deferredExerciseIDs = deferred
        ongoing.currentExIndex = index
        ongoing.currentSetIndex = set
        ongoing.isResting = false
        ongoing.restingEndTime = nil
        ongoing.remainingRestSeconds = 0
        ongoing.totalRestSeconds = 0
        withAnimation(.spring()) { workoutManager.ongoingWorkout = ongoing }
        workoutManager.updateWorkoutLiveActivity(for: ongoing)
        return true
    }

    @discardableResult
    func deferCurrentExercise() -> Bool {
        guard let id = workoutManager.ongoingWorkout?.nextAlternativeExerciseID else { return false }
        return selectExercise(id: id)
    }

    func advanceWorkoutState() {
        // A delayed timer event after manual selection must not skip the selected set.
        guard var ongoing = workoutManager.ongoingWorkout, ongoing.isResting else { return }
        workoutManager.registerInteraction()
        workoutManager.stopGlobalRestTimer()
        ongoing.isResting = false
        ongoing.restingEndTime = nil
        ongoing.remainingRestSeconds = 0
        if let next = findNextSequencePosition(fromEx: ongoing.currentExIndex, fromSet: ongoing.currentSetIndex, ongoing: ongoing) {
            ongoing.currentExIndex = next.0
            ongoing.currentSetIndex = next.1
        }
        withAnimation(.spring()) { workoutManager.ongoingWorkout = ongoing }
        workoutManager.updateWorkoutLiveActivity(for: ongoing)
    }

    func concludeWorkout(ongoing: OngoingWorkoutState, onDismiss: () -> Void) {
        workoutManager.stopGlobalRestTimer()
        workoutManager.endWorkoutLiveActivity()
        let completedExercises = ongoing.activeExercises.compactMap { exercise -> WorkoutExercise? in
            var completedExercise = exercise
            completedExercise.sets = exercise.sets
                .filter { ongoing.completedSetIDs.contains($0.id) }
                .map { set in
                    var completedSet = set
                    completedSet.isCompleted = true
                    return completedSet
                }
            return completedExercise.sets.isEmpty ? nil : completedExercise
        }
        
        let calcVolume = completedExercises.flatMap(\.sets).filter { $0.setType != .warmup }.reduce(0.0) { volume, set in
            volume + (set.targetWeight ?? 0) * Double(set.targetReps)
        }

        if let idx = workoutManager.myPlans.firstIndex(where: { $0.id == ongoing.plan.id }) {
            var updatedPlan = workoutManager.myPlans[idx]
            updatedPlan.exercises = ongoing.activeExercises
            workoutManager.savePlan(updatedPlan)
        }

        let durationSeconds = Int(Date().timeIntervalSince(ongoing.startTime))
        
        let session = WorkoutSession(
            planId: ongoing.plan.id,
            date: ongoing.startTime,
            totalVolume: Int(calcVolume),
            durationSeconds: durationSeconds,
            completedExercises: completedExercises
        )

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        workoutManager.addCompletedSession(session)
        workoutManager.markWorkoutAsCompleted(ongoing.plan)

        // Save to HealthKit
        if let healthManager = healthManager {
            Task {
                await healthManager.saveAppWorkout(
                    duration: TimeInterval(durationSeconds),
                    totalVolume: Int(calcVolume),
                    date: ongoing.startTime
                )
            }
        }

        workoutManager.ongoingWorkout = nil
        onDismiss()
    }
    
    func playSoundAndVibrate() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.warning)
    }

    func adjustWeight(by amount: Double) {
        workoutManager.registerInteraction()
        guard var ongoing = workoutManager.ongoingWorkout else { return }
        let exIdx = ongoing.currentExIndex
        let setIdx = ongoing.currentSetIndex
        let current = ongoing.activeExercises[exIdx].sets[setIdx].targetWeight ?? 0.0
        let newValue = max(0.0, current + amount)
        ongoing.activeExercises[exIdx].sets[setIdx].targetWeight = newValue > 0 ? newValue : nil
        workoutManager.ongoingWorkout = ongoing
    }

    func adjustReps(by amount: Int) {
        workoutManager.registerInteraction()
        guard var ongoing = workoutManager.ongoingWorkout else { return }
        let exIdx = ongoing.currentExIndex
        let setIdx = ongoing.currentSetIndex
        let current = ongoing.activeExercises[exIdx].sets[setIdx].targetReps
        ongoing.activeExercises[exIdx].sets[setIdx].targetReps = max(1, current + amount)
        workoutManager.ongoingWorkout = ongoing
    }

    func peekNextSet(ongoing: OngoingWorkoutState) -> String? {
        if let nextPos = findNextSequencePosition(fromEx: ongoing.currentExIndex, fromSet: ongoing.currentSetIndex, ongoing: ongoing) {
            if nextPos.0 == ongoing.currentExIndex {
                return "Serie \(nextPos.1 + 1)"
            } else {
                return ongoing.activeExercises[nextPos.0].baseExercise.name
            }
        }
        return nil
    }
    
    func updateNote(for exerciseIndex: Int, text: String) {
        guard var ongoing = workoutManager.ongoingWorkout else { return }
        ongoing.activeExercises[exerciseIndex].notes = text
        workoutManager.ongoingWorkout = ongoing
    }
}
