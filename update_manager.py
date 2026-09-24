import re

with open("Frigo/Allenamento/Manager/WorkoutManager.swift", "r") as f:
    text = f.read()

# Replace getDocumentsDirectory, etc.
text = re.sub(
    r"  private func getDocumentsDirectory.*?return paths\[0\]\n  }",
    "",
    text,
    flags=re.DOTALL
)
