import re

file_path = "Frigo/Allenamento/Models/WorkoutExercise.swift"
with open(file_path, "r") as f:
    content = f.read()

content = content.replace("try container.decode([WorkoutSet].self, forKey: .sets)", "try container.decodeIfPresent([WorkoutSet].self, forKey: .sets) ?? []")
content = content.replace("try container.decode(UUID.self, forKey: .id)", "try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()")

with open(file_path, "w") as f:
    f.write(content)
