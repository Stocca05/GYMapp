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
    }
    
    func findNextSequencePosition(fromEx: Int, fromSet: Int, ongoing: OngoingWorkoutState) -> (Int, Int)? {
        if ongoing.activeExercises[fromEx].isLinkedToNext {
            let nextExIndex = fromEx + 1
            if nextExIndex < ongoing.activeExercises.count {
                if fromSet < ongoing.activeExercises[nextExIndex].sets.count {
                    return (nextExIndex, fromSet)
                }
            }
        }
        
        var startGroupEx = fromEx
        while startGroupEx > 0 && ongoing.activeExercises[startGroupEx - 1].isLinkedToNext {
            startGroupEx -= 1
        }
        
        let nextSetIndex = fromSet + 1
        
        var groupHasMoreSets = false
        var curr = startGroupEx
        while curr <= fromEx {
            if nextSetIndex < ongoing.activeExercises[curr].sets.count {
                groupHasMoreSets = true
                break
            }
            curr += 1
        }
        
        if groupHasMoreSets {
            var attemptEx = startGroupEx
            while attemptEx <= fromEx {
                if nextSetIndex < ongoing.activeExercises[attemptEx].sets.count {
                    return (attemptEx, nextSetIndex)
                }
                attemptEx += 1
            }
        }
        
        let nextNormalExIndex = fromEx + 1
        if nextNormalExIndex < ongoing.activeExercises.count {
            return (nextNormalExIndex, 0)
        }
        
        return nil
    }
    
    func completeCurrentSetAndRest(setId: UUID, restSeconds: Int, isLast: Bool, isSupersetLink: Bool, nextPos: (Int, Int)?, onConclude: () -> Void) {
        workoutManager.registerInteraction()
        guard var ongoing = workoutManager.ongoingWorkout else { return }

        ongoing.completedSetIDs.insert(setId)

        if isLast {
            onConclude()
        } else if isSupersetLink {
            if let nextPos = nextPos {
                ongoing.currentExIndex = nextPos.0
                ongoing.currentSetIndex = nextPos.1
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                workoutManager.ongoingWorkout = ongoing
            }
        } else {
            ongoing.totalRestSeconds = restSeconds
            ongoing.remainingRestSeconds = restSeconds
            ongoing.isResting = true
            ongoing.restingEndTime = Date().addingTimeInterval(TimeInterval(restSeconds))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                workoutManager.ongoingWorkout = ongoing
            }
            workoutManager.startGlobalRestTimer()
            workoutManager.updateWorkoutLiveActivity(for: ongoing)
        }
    }
    
    func advanceWorkoutState() {
        workoutManager.registerInteraction()
        guard var ongoing = workoutManager.ongoingWorkout else { return }

        ongoing.isResting = false

        if let nextPos = findNextSequencePosition(fromEx: ongoing.currentExIndex, fromSet: ongoing.currentSetIndex, ongoing: ongoing) {
            ongoing.currentExIndex = nextPos.0
            ongoing.currentSetIndex = nextPos.1
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            workoutManager.ongoingWorkout = ongoing
        }
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
