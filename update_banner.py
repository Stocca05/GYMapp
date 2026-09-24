import re

with open("Frigo/Allenamento/Views/Components/HeroWorkoutBanner.swift", "r") as f:
    text = f.read()

# Replace states and initializers
new_properties = """struct HeroWorkoutBanner: View {
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(ThemeManager.self) private var themeManager
    
    @State private var forceShowNext = false
    
    var onCreate: () -> Void = {}
    var onPlay: (WorkoutPlan) -> Void = { _ in }
    
    var body: some View {"""

text = re.sub(r'struct HeroWorkoutBanner: View \{.*?var body: some View \{', new_properties, text, flags=re.DOTALL)

# Delete the modifiers
# We need to delete .fullScreenCover(isPresented: $isShowingCreator) and fullScreenCover(item: $planToPlay) and onChange(of: planToPlay)
modifier_deletion = r'\.fullScreenCover\(isPresented: \$isShowingCreator\).*?\.onChange\(of: planToPlay\) \{ _, newValue in\s*if newValue == nil \{\s*forceShowNext = false\s*\}\s*\}'
# wait, since planToPlay is gone, let's just do a regex replace from .fullScreenCover(isPresented: $isShowingCreator) down to the end of the View's body property
# Actually, the problem is we want to keep some parts. Let's do it using basic string replacement.
