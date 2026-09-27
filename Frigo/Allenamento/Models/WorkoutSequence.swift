import Foundation

/// Visits each set once, alternating exercises within each linked group.
enum WorkoutSequence {
    /// Canonical order keeps supersets together, including unequal set counts.
    static func positions(in exercises: [WorkoutExercise]) -> [(Int, Int)] {
        var result: [(Int, Int)] = []
        var first = 0
        while first < exercises.count {
            var last = first
            while last + 1 < exercises.count && exercises[last].isLinkedToNext { last += 1 }
            let rounds = (first...last).map { exercises[$0].sets.count }.max() ?? 0
            for round in 0..<rounds {
                for index in first...last where exercises[index].sets.indices.contains(round) {
                    result.append((index, round))
                }
            }
            first = last + 1
        }
        return result
    }

    /// Wrap around for skipped work, prioritizing exercises that were not deferred.
    static func nextPending(afterExercise index: Int, set: Int, ongoing: OngoingWorkoutState) -> (Int, Int)? {
        let positions = positions(in: ongoing.activeExercises)
        guard let current = positions.firstIndex(where: { $0 == (index, set) }) else { return nil }
        let circular = Array(positions.dropFirst(current + 1)) + Array(positions.prefix(current))
        let pending = circular.filter {
            !ongoing.completedSetIDs.contains(ongoing.activeExercises[$0.0].sets[$0.1].id)
        }
        return pending.first {
            !(ongoing.deferredExerciseIDs ?? []).contains(ongoing.activeExercises[$0.0].id)
        } ?? pending.first
    }

    static func next(afterExercise index: Int, set: Int, exercises: [WorkoutExercise]) -> (Int, Int)? {
        guard exercises.indices.contains(index), exercises[index].sets.indices.contains(set) else { return nil }
        var first = index
        while first > 0 && exercises[first - 1].isLinkedToNext { first -= 1 }
        var last = index
        while last + 1 < exercises.count && exercises[last].isLinkedToNext { last += 1 }

        // Finish this round, including members beyond an empty/shorter exercise.
        if index < last {
            for candidate in (index + 1)...last where exercises[candidate].sets.indices.contains(set) {
                return (candidate, set)
            }
        }
        for candidate in first...last where exercises[candidate].sets.indices.contains(set + 1) {
            return (candidate, set + 1)
        }
        // Never re-enter a completed group. Old plans may contain empty exercises.
        if last + 1 < exercises.count {
            for candidate in (last + 1)..<exercises.count where !exercises[candidate].sets.isEmpty {
                return (candidate, 0)
            }
        }
        return nil
    }

    static func isSupersetTransition(
        fromExercise index: Int, set: Int, to next: (Int, Int)?, exercises: [WorkoutExercise]
    ) -> Bool {
        guard let next, exercises.indices.contains(index), exercises.indices.contains(next.0),
              next.0 > index, next.1 == set else { return false }
        return (index..<next.0).allSatisfy { exercises[$0].isLinkedToNext }
    }
}
