import re

file_path = "Frigo/Allenamento/Models/WorkoutSession.swift"
with open(file_path, "r") as f:
    content = f.read()

content = content.replace("try container.decode(Int.self, forKey: .totalVolume)", "try container.decodeIfPresent(Int.self, forKey: .totalVolume) ?? 0")
content = content.replace("try container.decode(Int.self, forKey: .durationSeconds)", "try container.decodeIfPresent(Int.self, forKey: .durationSeconds) ?? 0")
# For id, planId, date, it's probably best to keep decode so it throws if absent, because date and planId make no sense to be missing.

with open(file_path, "w") as f:
    f.write(content)
