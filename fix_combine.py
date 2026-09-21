import re

with open("Frigo/ContentView.swift", "r") as f:
    text = f.read()

text = text.replace("import SwiftUI", "import SwiftUI\nimport Combine")

with open("Frigo/ContentView.swift", "w") as f:
    f.write(text)
