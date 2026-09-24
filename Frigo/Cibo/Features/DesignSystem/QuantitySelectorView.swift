import SwiftUI

/// Permette di scegliere una quantità con preset e menu coerenti con l'unità.
struct QuantitySelectorView: View {
    let title: String
    let unit: UnitOfMeasure
    let minimum: Int
    let maximum: Int
    @Binding var quantity: Int

    /// Crea un selettore con limite minimo esplicito o predefinito a uno.
    ///
    /// - Parameters:
    ///   - title: Etichetta del controllo.
    ///   - unit: Unità della quantità.
    ///   - minimum: Valore minimo ammissibile.
    ///   - maximum: Valore massimo ammissibile.
    ///   - quantity: Valore intero selezionato.
    init(title: String, unit: UnitOfMeasure, minimum: Int = 1, maximum: Int, quantity: Binding<Int>) {
        self.title = title
        self.unit = unit
        self.minimum = minimum
        self.maximum = maximum
        _quantity = quantity
    }

    private var step: Int { min(unit.defaultStep, max(maximum - minimum, 1)) }
    private var presets: [Int] {
        switch unit {
        case .grams, .milliliters:
            [50, 100, 250, 500, 750, 1_000]
        case .pieces:
            [1, 2, 4, 6, 12]
        }
    }

    /// Disegna un controllo compatto per l'immissione di quantità intere.
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                Spacer()
                Text("\(quantity) \(unit.abbreviation)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.tint)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets.filter { (minimum...maximum).contains($0) }, id: \.self) { value in
                        Button("\(value)") { quantity = value }
                            .buttonStyle(.bordered)
                            .tint(quantity == value ? .accentColor : .secondary)
                    }
                }
            }
            Slider(
                value: Binding(
                    get: { Double(quantity) },
                    set: { quantity = min(max(Int($0.rounded() / Double(step)) * step, minimum), maximum) }
                ),
                in: Double(minimum)...Double(maximum),
                step: Double(step)
            )
        }
        .padding(.vertical, 4)
    }
}
