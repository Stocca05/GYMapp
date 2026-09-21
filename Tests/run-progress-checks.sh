#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
check_dir=$(mktemp -d "${TMPDIR:-/tmp}/frigo-progress-checks.XXXXXX")
trap 'rm -rf "$check_dir"' EXIT HUP INT TERM
xcrun swiftc -parse-as-library -swift-version 5 -default-isolation MainActor \
  Frigo/Allenamento/Models/ExerciseModel.swift \
  Frigo/Allenamento/Models/WorkoutSet.swift \
  Frigo/Allenamento/Models/WorkoutExercise.swift \
  Frigo/Allenamento/Models/WorkoutPlan.swift \
  Frigo/Allenamento/Models/OngoingWorkoutState.swift \
  Frigo/Allenamento/Models/WorkoutSession.swift \
  Frigo/Allenamento/Manager/WorkoutManager.swift \
  Frigo/Allenamento/Manager/WorkoutProgressAnalytics.swift \
  Tests/WorkoutProgressAnalyticsChecks.swift -o "$check_dir/checks"
"$check_dir/checks"
