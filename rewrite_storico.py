import re

with open("Frigo/Allenamento/Views/StoricoView.swift", "r") as f:
    text = f.read()

# Trovare tutto fino a logbookSection per fixare il body
body_fix = """    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if workoutManager.completedSessions.isEmpty {
                    emptyStateView
                } else {
                    vanityMetricsPanel
                    chartSection
                    logbookSection
                }
            }
            .padding(.vertical, 24)
        }
    }"""
text = re.sub(r'    var body: some View \{.*?// MARK: - Components', body_fix + '\n\n    // MARK: - Components', text, flags=re.DOTALL)

with open("Frigo/Allenamento/Views/StoricoView.swift", "w") as f:
    f.write(text)
