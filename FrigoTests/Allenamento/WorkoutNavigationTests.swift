import Foundation
import Testing
@testable import Frigo

@MainActor
struct WorkoutNavigationTests {
    @Test func reorderPreservesExerciseDataAndOnlyRetainsOriginalSupersetPartners() {
        var exercises = makeExercises([1, 2, 3, 1])
        exercises[0].isLinkedToNext = true
        exercises[2].isLinkedToNext = true
        exercises[1].notes = "Keep my settings"
        let moved = WorkoutExerciseOrder.move(exercises[1].id, by: -1, in: exercises)
        #expect(moved.map(\.id) == [exercises[1].id, exercises[0].id, exercises[2].id, exercises[3].id])
        #expect(moved[0].sets == exercises[1].sets)
        #expect(moved[0].notes == "Keep my settings")
        #expect(!moved[1].isLinkedToNext)
        #expect(moved[2].isLinkedToNext)
        let down = WorkoutExerciseOrder.move(moved[0].id, by: 1, in: moved)
        #expect(down.map(\.id) == exercises.map(\.id))
        #expect(WorkoutExerciseOrder.move(exercises[0].id, by: -1, in: exercises) == exercises)
        #expect(WorkoutExerciseOrder.move(exercises[3].id, by: 1, in: exercises) == exercises)
    }

    @Test func reorderedPlanSurvivesSavingAndReloading() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        var plan = WorkoutPlan(title: "Reorder", exercises: makeExercises([1, 2, 1]))
        fixture.manager.savePlan(plan)
        plan.exercises = WorkoutExerciseOrder.move(plan.exercises[2].id, by: -1, in: plan.exercises)
        fixture.manager.savePlan(plan)
        await fixture.manager.fileWriter.flush()
        let loaded = WorkoutManager(storageDirectory: fixture.directory, defaults: fixture.defaults)
        #expect(loaded.myPlans == [plan])
    }

    @Test func deferDuringRestPreservesProgressAndReturnsToUnfinishedExercise() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let exercises = makeExercises([2, 1, 1])
        let plan = WorkoutPlan(title: "Busy machine", exercises: exercises)
        fixture.manager.savePlan(plan)
        fixture.manager.startOrResumeWorkout(plan: plan)
        let model = ActiveWorkoutViewModel(workoutManager: fixture.manager)
        var conclusions = 0
        func complete(_ id: UUID, rest: Int = 0) {
            model.completeCurrentSetAndRest(setId: id, restSeconds: rest) {
                conclusions += 1
                if let state = fixture.manager.ongoingWorkout {
                    model.concludeWorkout(ongoing: state, onDismiss: {})
                }
            }
        }
        complete(exercises[0].sets[0].id, rest: 90)
        #expect(fixture.manager.ongoingWorkout?.isResting == true)
        #expect(model.deferCurrentExercise())
        let switched = try #require(fixture.manager.ongoingWorkout)
        #expect(switched.currentExIndex == 1)
        #expect(switched.completedSetIDs == [exercises[0].sets[0].id])
        #expect(switched.deferredExerciseIDs == [exercises[0].id])
        #expect(!switched.isResting && switched.restingEndTime == nil && switched.remainingRestSeconds == 0)
        model.advanceWorkoutState() // A delayed rest callback must do nothing.
        #expect(fixture.manager.ongoingWorkout == switched)
        complete(exercises[1].sets[0].id)
        #expect(fixture.manager.ongoingWorkout?.currentExIndex == 2)
        #expect(fixture.manager.ongoingWorkout?.remainingExerciseIndices == [0, 2])
        complete(exercises[2].sets[0].id)
        #expect(conclusions == 0)
        #expect(fixture.manager.ongoingWorkout?.currentExIndex == 0)
        #expect(fixture.manager.ongoingWorkout?.currentSetIndex == 1)
        complete(exercises[0].sets[0].id) // Reject a stale button from a completed set.
        #expect(conclusions == 0)
        complete(exercises[0].sets[1].id)
        await fixture.manager.fileWriter.flush()
        #expect(conclusions == 1)
        let session = try #require(fixture.manager.completedSessions.last)
        #expect(session.completedSetCount == 4)
        #expect(fixture.manager.myPlans.first?.exercises.map(\.id) == exercises.map(\.id))
        #expect(Set(session.completedExercises.flatMap(\.sets).map(\.id)) == Set(exercises.flatMap(\.sets).map(\.id)))
    }

    @Test func selectionResumesFirstPendingSetAndRejectsFinishedOrUnknownExercises() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let exercises = makeExercises([2, 1, 1])
        fixture.manager.startOrResumeWorkout(plan: WorkoutPlan(title: "Select", exercises: exercises))
        fixture.manager.ongoingWorkout?.completedSetIDs = [exercises[0].sets[0].id, exercises[2].sets[0].id]
        let model = ActiveWorkoutViewModel(workoutManager: fixture.manager)
        #expect(!model.selectExercise(id: exercises[2].id))
        #expect(!model.selectExercise(id: UUID()))
        #expect(model.selectExercise(id: exercises[1].id))
        #expect(model.selectExercise(id: exercises[0].id))
        #expect(fixture.manager.ongoingWorkout?.currentSetIndex == 1)
        #expect(fixture.manager.ongoingWorkout?.deferredExerciseIDs?.contains(exercises[0].id) == false)
        #expect(fixture.manager.ongoingWorkout?.completedSetIDs.count == 2)
    }

    @Test func lastRemainingExerciseCannotBeDeferred() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        fixture.manager.startOrResumeWorkout(plan: WorkoutPlan(title: "Only one", exercises: makeExercises([2])))
        let previous = fixture.manager.ongoingWorkout
        #expect(!ActiveWorkoutViewModel(workoutManager: fixture.manager).deferCurrentExercise())
        #expect(fixture.manager.ongoingWorkout == previous)
    }

    @Test func deferredSupersetMemberWaitsUntilOtherExercisesFinish() throws {
        var exercises = makeExercises([3, 2, 1])
        exercises[0].isLinkedToNext = true
        var state = makeState(exercises)
        state.currentExIndex = 1
        state.deferredExerciseIDs = [exercises[0].id]
        var visited: [String] = []
        for _ in 0..<8 {
            let current = (state.currentExIndex, state.currentSetIndex)
            visited.append("\(current.0):\(current.1)")
            state.completedSetIDs.insert(exercises[current.0].sets[current.1].id)
            guard let next = WorkoutSequence.nextPending(afterExercise: current.0, set: current.1, ongoing: state) else { break }
            state.currentExIndex = next.0
            state.currentSetIndex = next.1
        }
        #expect(visited == ["1:0", "1:1", "2:0", "0:0", "0:1", "0:2"])
        #expect(state.remainingExerciseIndices.isEmpty)
    }

    @Test func pendingPreviewWrapsAndDoesNotEndAtLastPositionalSet() {
        let exercises = makeExercises([1, 1, 1])
        var state = makeState(exercises)
        state.currentExIndex = 2
        state.deferredExerciseIDs = [exercises[0].id]
        let next = WorkoutSequence.nextPending(afterExercise: 2, set: 0, ongoing: state)
        #expect(next?.0 == 1)
        state.completedSetIDs.insert(exercises[1].sets[0].id)
        #expect(WorkoutSequence.nextPending(afterExercise: 2, set: 0, ongoing: state)?.0 == 0)
    }

    @Test func encodedStatePreservesDeferralsAndDecodesOldStateWithoutThem() throws {
        var state = makeState(makeExercises([1, 1]))
        state.deferredExerciseIDs = [state.activeExercises[0].id]
        let data = try JSONEncoder().encode(state)
        #expect(try JSONDecoder().decode(OngoingWorkoutState.self, from: data) == state)
        var legacy = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        legacy.removeValue(forKey: "deferredExerciseIDs")
        let decoded = try JSONDecoder().decode(OngoingWorkoutState.self, from: JSONSerialization.data(withJSONObject: legacy))
        #expect(decoded.deferredExerciseIDs == nil)
        #expect(decoded.activeExercises == state.activeExercises)
    }

    private func makeExercises(_ counts: [Int]) -> [WorkoutExercise] {
        counts.enumerated().map { index, count in
            WorkoutExercise(baseExercise: ExerciseModel(name: "Exercise \(index)", primaryMuscle: .chest),
                sets: (0..<count).map { _ in WorkoutSet(targetReps: 10, targetWeight: 20) })
        }
    }

    private func makeState(_ exercises: [WorkoutExercise]) -> OngoingWorkoutState {
        OngoingWorkoutState(plan: WorkoutPlan(title: "Test", exercises: exercises), activeExercises: exercises,
            completedSetIDs: [], currentExIndex: 0, currentSetIndex: 0, startTime: .now,
            isResting: false, remainingRestSeconds: 0, totalRestSeconds: 0)
    }

    @MainActor private struct Fixture {
        let directory: URL
        let suite: String
        let defaults: UserDefaults
        let manager: WorkoutManager
        init() throws {
            suite = "FrigoNavigation.\(UUID())"
            directory = FileManager.default.temporaryDirectory.appending(path: suite)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defaults = try #require(UserDefaults(suiteName: suite))
            manager = WorkoutManager(storageDirectory: directory, defaults: defaults)
        }
        func remove() {
            manager.stopGlobalRestTimer()
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: directory)
        }
    }
}
