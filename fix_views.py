import re

# 1. Rename GymCalendarView to StoricoView
with open("Frigo/Allenamento/Views/GymCalendarView.swift", "r") as f:
    text = f.read()

text = text.replace("struct GymCalendarView: View {", "struct StoricoView: View {")
# Rimuovere il NavigationStack e i pulsanti close visto che usiamo il tab
text = text.replace("        NavigationStack {", "        //NavigationStack rimossa perche' integrato nel Tab")
text = text.replace("            ScrollView {", "        ScrollView {")
text = text.replace("        }", "        }", 1) # Close NavigationStack? it's handled differently
# Let's just do a clean regex replacement of the outer body
body_regex = r'    var body: some View \{\n        NavigationStack \{\n            ScrollView \{\n(.*?)            \}\n            \.background\(themeManager\.currentTheme\.backgroundColor\.ignoresSafeArea\(\)\)\n            \.navigationTitle\("Analisi & Storico"\)\n            \.navigationBarTitleDisplayMode\(\.inline\)\n            \.toolbar \{ ToolbarItem\(placement: \.topBarTrailing\) \{ closeButton \} \}\n        \}\n    \}'
body_replacement = r"""    var body: some View {
        ScrollView {
\1        }
    }"""
text = re.sub(body_regex, body_replacement, text, flags=re.DOTALL)
text = text.replace("private var closeButton", "// private var closeButton")

with open("Frigo/Allenamento/Views/StoricoView.swift", "w") as f:
    f.write(text)

# 2. Update GymView
with open("Frigo/Allenamento/GymView.swift", "r") as f:
    gym = f.read()

gym = gym.replace('                    Text("Storico Allenamenti (Coming Soon)")\n                        .padding(.top, 40)\n                        .foregroundColor(.secondary)', '                    StoricoView()')

with open("Frigo/Allenamento/GymView.swift", "w") as f:
    f.write(gym)

