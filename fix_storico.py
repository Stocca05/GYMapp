with open("Frigo/Allenamento/Views/StoricoView.swift", "r") as f:
    text = f.read()

import re
text = re.sub(r'    // private var closeButton: some View \{\n        Button\(action: \{ dismiss\(\) \}\) \{\n            Image\(systemName: "xmark\.circle\.fill"\)\n                \.foregroundStyle\(themeManager\.currentTheme\.secondaryColor\)\n                \.font\(\.title3\)\n        \}\n    \}', '', text)

with open("Frigo/Allenamento/Views/StoricoView.swift", "w") as f:
    f.write(text)
