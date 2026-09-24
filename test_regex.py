import re

part = """
        name: "Trazioni alla Sbarra",
        description: "Esercizio base a corpo libero per l'ipertrofia del gran dorsale.",
        primaryMuscle: .back,
        equipmentRequirement: "Sbarra per Trazioni"
      ),
"""

res = re.sub(r'(equipmentRequirement:\s*"[^"]*")', r'\1,\n        imageName: "pull_ups_anim"', part, count=1)
print(res)
