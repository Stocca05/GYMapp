import SwiftUI

struct FoodLocationTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Selettore di collocazione con icona, nome e stato accessibile.
struct FoodLocationTile: View {
    let location: StorageLocation
    let isSelected: Bool
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: location.foodSymbol)
                    .font(.title3)
                    .imageScale(.large)
                    .accessibilityHidden(true)
                Text(location.shortName)
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle).font(.caption).monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .foregroundStyle(isSelected ? location.foodTint : Color.secondary)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(
                            colors: [location.foodTint.opacity(0.15), location.foodTint.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.04), radius: 5, x: 0, y: 2)
                }
            }
            .overlay { 
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? location.foodTint : .clear, lineWidth: 1.5) 
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .animation(.spring(), value: isSelected)
        }
        .buttonStyle(FoodLocationTileButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension StorageLocation {
    /// Etichetta compatta per i selettori.
    var shortName: String { switch self { case .fridge: "Frigo"; case .freezer: "Freezer"; case .pantry: "Dispensa" } }
    /// Simbolo della collocazione nell'interfaccia Cibo.
    var foodSymbol: String { switch self { case .fridge: "refrigerator"; case .freezer: "snowflake"; case .pantry: "cabinet" } }
    /// Accento cromatico accompagnato sempre da un'etichetta.
    var foodTint: Color { switch self { case .fridge: .teal; case .freezer: .blue; case .pantry: .orange } }
}
