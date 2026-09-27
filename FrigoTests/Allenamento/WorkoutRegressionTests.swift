import Foundation
import Testing
@testable import Frigo

@MainActor
struct WorkoutRegressionTests {
    @Test func unevenSupersetsVisitEachSetOnceAndThenLeaveTheGroup() {
        for counts in [[3, 2], [1, 3], [3, 1, 3], [1, 0, 3], [0, 2, 1]] {
            var exercises = makeExercises(counts)
            exercises.append(contentsOf: makeExercises([1]))
            var position: (Int, Int)? = (counts.firstIndex(where: { $0 > 0 })!, 0)
            var visited: [String] = []
            // A bounded traversal fails on cycles instead of hanging the suite.
            for _ in 0..<(counts.reduce(0, +) + 2) {
                guard let current = position else { break }
                visited.append("\(current.0):\(current.1)")
                position = WorkoutSequence.next(afterExercise: current.0, set: current.1, exercises: exercises)
            }
            var expected: [String] = []
            for round in 0..<(counts.max() ?? 0) {
                for index in counts.indices where round < counts[index] {
                    expected.append("\(index):\(round)")
                }
            }
            expected.append("\(counts.count):0")
            #expect(visited == expected)
            #expect(position == nil)
        }
    }

    @Test func emptyExercisesPreserveSupersetRestBoundaries() {
        var exercises = makeExercises([1, 0, 1])
        let next = WorkoutSequence.next(afterExercise: 0, set: 0, exercises: exercises)
        #expect(next?.0 == 2)
        #expect(WorkoutSequence.isSupersetTransition(fromExercise: 0, set: 0, to: next, exercises: exercises))
        exercises[1].isLinkedToNext = false
        #expect(!WorkoutSequence.isSupersetTransition(fromExercise: 0, set: 0, to: next, exercises: exercises))
        #expect(!WorkoutSequence.isSupersetTransition(fromExercise: 2, set: 0, to: (0, 1), exercises: exercises))
        #expect(WorkoutSequence.next(afterExercise: -1, set: 0, exercises: exercises) == nil)
    }

    @Test func lastSetIsPresentInHistoryAndPersistedAfterConclusion() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        var exercises = makeExercises([1])
        exercises[0].sets[0].targetWeight = 50
        let plan = WorkoutPlan(title: "Test", exercises: exercises)
        fixture.manager.savePlan(plan)
        fixture.manager.startOrResumeWorkout(plan: plan)
        let viewModel = ActiveWorkoutViewModel(workoutManager: fixture.manager)
        let setID = exercises[0].sets[0].id
        var callbackSawLastSet = false
        viewModel.completeCurrentSetAndRest(setId: setID, restSeconds: 90) {
            guard let ongoing = fixture.manager.ongoingWorkout else { return }
            callbackSawLastSet = ongoing.completedSetIDs.contains(setID)
            viewModel.concludeWorkout(ongoing: ongoing, onDismiss: {})
        }
        await fixture.manager.fileWriter.flush()
        #expect(callbackSawLastSet)
        let session = try #require(fixture.manager.completedSessions.last)
        #expect(session.completedSetCount == 1)
        #expect(session.totalVolume == 500)
        #expect(fixture.manager.ongoingWorkout == nil)
        let reopened = WorkoutManager(storageDirectory: fixture.directory, defaults: fixture.defaults)
        #expect(reopened.completedSessions == [session])
    }

    @Test func invalidNewPlansAreRejectedAndLegacyEmptyExercisesAreSkipped() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let legacyPlan = WorkoutPlan(title: "Legacy", exercises: makeExercises([0, 1, 0, 1]))
        #expect(!legacyPlan.isValid)
        #expect(!WorkoutPlan(title: " ", exercises: makeExercises([1])).isValid)
        #expect(!WorkoutPlan(title: "Empty").isValid)
        #expect(WorkoutPlan(title: "Valid", exercises: makeExercises([1])).isValid)
        fixture.manager.startOrResumeWorkout(plan: legacyPlan)
        #expect(fixture.manager.ongoingWorkout?.currentExIndex == 1)
        let next = WorkoutSequence.next(afterExercise: 1, set: 0, exercises: legacyPlan.exercises)
        #expect(next?.0 == 3)
        let emptyPlan = WorkoutPlan(title: "Empty", exercises: makeExercises([0]))
        #expect(!fixture.manager.startOrResumeWorkout(plan: emptyPlan))
        #expect(fixture.manager.ongoingWorkout?.plan.id == legacyPlan.id)
        fixture.manager.ongoingWorkout = nil
        #expect(!fixture.manager.startOrResumeWorkout(plan: emptyPlan))
        #expect(fixture.manager.ongoingWorkout == nil)
    }

    @Test func rapidSavesRetainLatestSnapshotAcrossManagerInstances() async throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let other = WorkoutManager(storageDirectory: fixture.directory, defaults: fixture.defaults)
        var plan = WorkoutPlan(title: "0", exercises: makeExercises([1]))
        for revision in 0..<100 {
            plan.title = "\(revision)"
            (revision.isMultiple(of: 2) ? fixture.manager : other).savePlan(plan)
        }
        await fixture.manager.fileWriter.flush()
        let reopened = WorkoutManager(storageDirectory: fixture.directory, defaults: fixture.defaults)
        #expect(reopened.myPlans == [plan])
    }

    @Test func completedSetCountIncludesBodyweightAndWarmupWithoutInventingLegacySets() {
        var exercises = makeExercises([3])
        exercises[0].sets[0].isCompleted = true
        exercises[0].sets[1].isCompleted = true
        exercises[0].sets[1].setType = .warmup
        let session = WorkoutSession(planId: UUID(), date: .now, completedExercises: exercises)
        #expect(session.totalVolume == 0)
        #expect(session.completedSetCount == 2)
        let legacy = WorkoutSession(planId: UUID(), date: .now, totalVolume: 5000)
        #expect(legacy.completedSetCount == 0)
    }

    private func makeExercises(_ counts: [Int]) -> [WorkoutExercise] {
        counts.enumerated().map { index, count in
            WorkoutExercise(baseExercise: ExerciseModel(name: "Exercise \(index)", primaryMuscle: .chest),
                sets: (0..<count).map { _ in WorkoutSet(targetReps: 10) },
                isLinkedToNext: index < counts.count - 1)
        }
    }

    @MainActor
    private struct Fixture {
        let directory: URL
        let suite: String
        let defaults: UserDefaults
        let manager: WorkoutManager

        init() throws {
            suite = "FrigoRegression.\(UUID())"
            directory = FileManager.default.temporaryDirectory.appending(path: suite)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defaults = try #require(UserDefaults(suiteName: suite))
            manager = WorkoutManager(storageDirectory: directory, defaults: defaults)
        }

        func remove() {
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: directory)
        }
    }
}
