import re

file_path = "Frigo/Allenamento/Manager/WorkoutManager.swift"
with open(file_path, "r") as f:
    content = f.read()

# I will define a mapping from exercise name to imageName.
# Those that have an image will get it, the remaining will get a generic placeholder that user can add later or I just leave them missing.
# Wait, I'll just assign `imageName: "placeholder_anim"` to others so it doesn't break?
# The property is Optional: `let imageName: String?`

image_map = {
    "Trazioni alla Sbarra": "pull_ups_anim",
    "Military Press": "military_press_anim",
    "Curl Bicipiti con Manubri": "bicep_curl_anim",
    "Spinte con manubri su panca piana": "dumbbell_bench_press_anim",
    "Chest Press macchinario": "chest_press_anim",
    "Lento avanti con manubri da seduti": "seated_press_anim",
    "Alzate laterali con manubri": "lateral_raises_anim",
    "Lat machine avanti": "lat_pulldown_anim",
    "Pushdown ai cavi": "tricep_pushdown_anim",
    "Leg Press a 45 gradi": "leg_press_anim",
    "Leg Extension": "leg_extension_anim",
    "Leg Curl da seduto": "seated_leg_curl_anim",
    "Calf alla pressa": "calf_press_anim",
    "Bird-Dog": "bird_dog_anim"
}

def replacer(match):
    block = match.group(0)
    name_match = re.search(r'name:\s*"([^"]+)"', block)
    if name_match:
        name = name_match.group(1)
        if name in image_map:
            img_name = image_map[name]
            # check if imageName already exists
            if "imageName:" not in block:
                # Add it before the closing parenthesis
                block = re.sub(r'(\s*)\)$', f',\n        imageName: "{img_name}"\\1)', block)
    return block

# Find all ExerciseModel(...) calls in the setupExerciseDatabase method.
pattern = r'ExerciseModel\([\s\S]*?(?=\n      \),|\n      \)\n    \])'
def overall_replacer(match):
    block = match.group(0)
    return replacer(match)

# Actually, it's safer to just split by 'ExerciseModel(' and process each
parts = content.split("ExerciseModel(")
new_content = parts[0]
for part in parts[1:]:
    name_match = re.search(r'name:\s*"([^"]+)"', part)
    if name_match:
        name = name_match.group(1)
        if name in image_map and "imageName:" not in part:
            # We want to insert imageName just before the first closing parenthesis of this ExerciseModel call.
            # A bit tricky because part might contain other things, but inside setupExerciseDatabase, it's pretty simple.
            # We can find the closing parenthesis of the initialization.
            # Since it's formatted well, let's just use string replace.
            if "equipmentRequirement:" in part: # we know it's always before the closing ) in the list
                part = re.sub(r'(equipmentRequirement:\s*"[^"]*")', r'\1,\n        imageName: "' + image_map[name] + '"', part, count=1)
    new_content += "ExerciseModel(" + part

with open(file_path, "w") as f:
    f.write(new_content)

print("Updated WorkoutManager.swift")
