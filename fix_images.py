import re

file_path = "Frigo/Allenamento/Manager/WorkoutManager.swift"
with open(file_path, "r") as f:
    content = f.read()

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

parts = content.split("ExerciseModel(")
new_parts = [parts[0]]

for part in parts[1:]:
    name_match = re.search(r'name:\s*"([^"]+)"', part)
    if name_match:
        name = name_match.group(1)
        if name in image_map and "imageName" not in part:
            img = image_map[name]
            part = re.sub(r'(equipmentRequirement:\s*"[^"]*")', r'\1,\n        imageName: "' + img + '"', part, count=1)
    new_parts.append(part)

new_content = "ExerciseModel(".join(new_parts)

with open(file_path, "w") as f:
    f.write(new_content)

print(f"Replaced {len(new_parts)-1} exercises")
