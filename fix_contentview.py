import re

file_path = "Frigo/ContentView.swift"
with open(file_path, "r") as f:
    content = f.read()

# Update TabView
new_tabview = """            TabView(selection: $selectedTab) {
                FoodView().tag(0)
                HomeView().tag(1)
                GymView().tag(2)
                ProfileView().tag(3)
            }"""

content = re.sub(r'TabView\(selection: \$selectedTab\) \{\n\s*FoodView[^}]*\}', new_tabview, content, flags=re.MULTILINE)

# Update customTabBar buttons
# Find: tabButton(icon: "dumbbell", iconFilled: "dumbbell.fill", title: "Palestra", index: 2)
# Append: Spacer(); tabButton(icon: "person", iconFilled: "person.fill", title: "Profilo", index: 3)

new_buttons = """            tabButton(icon: "fork.knife", iconFilled: "fork.knife", title: "Cibo", index: 0)
            Spacer() // Mantiene le icone equamente distanziate
            tabButton(icon: "house.circle", iconFilled: "house.circle.fill", title: "Home", index: 1)
            Spacer()
            tabButton(icon: "dumbbell", iconFilled: "dumbbell.fill", title: "Palestra", index: 2)
            Spacer()
            tabButton(icon: "person.crop.circle", iconFilled: "person.crop.circle.fill", title: "Profilo", index: 3)"""

content = re.sub(r'tabButton\(icon: "fork\.knife"[\s\S]*?tabButton\(icon: "dumbbell"[\s\S]*?index: 2\)', new_buttons, content)

with open(file_path, "w") as f:
    f.write(content)
