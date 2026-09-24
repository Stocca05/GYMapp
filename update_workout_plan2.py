import re

file_path = "Frigo/Allenamento/Models/WorkoutPlan.swift"
with open(file_path, "r") as f:
    content = f.read()

new_duration_logic = """    var estimatedDurationInMinutes: Int {
        let allSets = exercises.flatMap { $0.sets }
        guard !allSets.isEmpty else { return 0 }
        
        let averageSecondsPerSetExecution = 30
        let totalExecutionTime = allSets.count * averageSecondsPerSetExecution
        let totalRestTime = allSets.dropLast().reduce(0) { $0 + $1.restTimeInSeconds }
        
        return (totalExecutionTime + totalRestTime) / 60
    }"""

pattern = r"    var estimatedDurationInMinutes: Int \{.*?\n    \}"
content = re.sub(pattern, new_duration_logic, content, flags=re.DOTALL)

with open(file_path, "w") as f:
    f.write(content)
