import re

with open("Frigo/Cibo/Features/AddProduct/AddProductView.swift", "r") as f:
    content = f.read()

# Replace the complicated knownProduct and normalizedName with a cleaner version
old_code = """
    private var normalizedName: String {
        name
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private var knownProduct: ProductSnapshot? {
        guard normalizedName.isEmpty == false else { return nil }
        return catalog.first { product in
            product.name
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .split(whereSeparator: \.isWhitespace)
                .joined(separator: " ") == normalizedName
        }
    }
"""

new_code = """
    private var normalizedName: String {
        name.normalizedForSearch
    }

    private var knownProduct: ProductSnapshot? {
        let search = normalizedName
        guard !search.isEmpty else { return nil }
        return catalog.first { $0.name.normalizedForSearch == search }
    }
"""

if old_code.strip() in content:
    content = content.replace(old_code, "\n" + new_code + "\n")
else:
    print("Could not find old code")

# Add String extension if it doesn't exist
string_ext = """
fileprivate extension String {
    var normalizedForSearch: String {
        self.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split(whereSeparator: \\.isWhitespace)
            .joined(separator: " ")
    }
}
"""

if "normalizedForSearch" not in content:
    content = content + "\n" + string_ext

with open("Frigo/Cibo/Features/AddProduct/AddProductView.swift", "w") as f:
    f.write(content)

print("Done")
