import re

with open("Frigo/Allenamento/Manager/WorkoutManager.swift", "r") as f:
    text = f.read()

text = text.replace("  func startOrResumeWorkout(plan: WorkoutPlan) {\n    if ongoingWorkout?.plan.id != plan.id {", "  func startOrResumeWorkout(plan: WorkoutPlan) {\n    registerInteraction()\n    if ongoingWorkout?.plan.id != plan.id {")

with open("Frigo/Allenamento/Manager/WorkoutManager.swift", "w") as f:
    f.write(text)
