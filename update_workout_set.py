import re

file_path = "Frigo/Allenamento/Models/WorkoutSet.swift"
with open(file_path, "r") as f:
    content = f.read()

# Make targetReps optional fallback to 0 or something? Or keep strictly required.
# isCompleted fallback to false
content = content.replace("try container.decode(Bool.self, forKey: .isCompleted)", "try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false")
# restTimeInSeconds fallback to 90
content = content.replace("try container.decode(Int.self, forKey: .restTimeInSeconds)", "try container.decodeIfPresent(Int.self, forKey: .restTimeInSeconds) ?? 90")
# targetReps fallback to 0 or 10? Probably need to be there, but fallback to 0 is safer.
content = content.replace("try container.decode(Int.self, forKey: .targetReps)", "try container.decodeIfPresent(Int.self, forKey: .targetReps) ?? 0")

with open(file_path, "w") as f:
    f.write(content)
