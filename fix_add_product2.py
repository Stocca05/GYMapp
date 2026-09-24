with open("Frigo/Cibo/Features/AddProduct/AddProductView.swift", "a") as f:
    f.write("\nfileprivate extension String {\n")
    f.write("    var normalizedForSearch: String {\n")
    f.write("        self.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)\n")
    f.write("            .split(whereSeparator: \.isWhitespace)\n")
    f.write("            .joined(separator: \" \")\n")
    f.write("    }\n")
    f.write("}\n")
