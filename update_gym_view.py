import re

with open("Frigo/Allenamento/GymView.swift", "r") as f:
    text = f.read()

# Refactor the switch selected tab block
content_view_replacement = """    @ViewBuilder private var contentView: some View {
        switch selectedTab {
        case .storico:
            StoricoView()
        case .schede:
            ScrollView {
                startZone
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
            }
        case .mieSchede:
            ScrollView {
                eserciziZone
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
            }
        }
    }"""
text = re.sub(r'    @ViewBuilder private var contentView: some View \{.*?\n    \}', content_view_replacement, text, flags=re.DOTALL)

# Refactor HeroWorkoutBanner call
start_zone_replacement = """    private var startZone: some View {
        VStack(spacing: 24) {
            // Il banner logico
            HeroWorkoutBanner(
                onCreate: { showCreator = true },
                onPlay: { plan in
                    workoutManager.startOrResumeWorkout(plan: plan)
                    planToPlay = plan
                }
            )"""

text = re.sub(r'    private var startZone: some View \{\s*VStack\(spacing: 24\) \{\s*// Il banner logico che abbiamo appena creato\s*HeroWorkoutBanner\(\)', start_zone_replacement, text)

with open("Frigo/Allenamento/GymView.swift", "w") as f:
    f.write(text)

