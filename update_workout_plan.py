import re

file_path = "Frigo/Allenamento/Models/WorkoutPlan.swift"
with open(file_path, "r") as f:
    content = f.read()

# Replace estimatedDurationInMinutes implementation
new_duration_logic = """    var estimatedDurationInMinutes: Int {
        var totalSeconds = 0
        let averageSecondsPerSetExecution = 30
        
        for exercise in exercises {
            for set in exercise.sets {
                totalSeconds += averageSecondsPerSetExecution + set.restTimeInSeconds
            }
        }
        
        // Remove the rest time of the absolute last set if it exists,
        // but using a simpler approach
        if let lastEx = exercises.last, let lastSet = lastEx.sets.last {
            totalSeconds -= lastSet.restTimeInSeconds
        }
        
        // Prevent negative in weird cases
        return max(0, totalSeconds / 60)
    }"""

# Use regex to replace the variable
pattern = r"    var estimatedDurationInMinutes: Int \{.*?\n    \}"
content = re.sub(pattern, new_duration_logic, content, flags=re.DOTALL)

with open(file_path, "w") as f:
    f.write(content)
