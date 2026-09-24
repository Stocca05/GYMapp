import Foundation

/// Rappresenta una porzione della quantità attualmente disponibile in una confezione.
nonisolated enum ConsumptionFraction: CaseIterable, Sendable, Identifiable {
    case oneEighth
    case oneQuarter
    case oneThird
    case oneHalf
    case twoThirds
    case threeQuarters
    case sevenEighths

    var id: Self { self }

    var label: String {
        switch self {
        case .oneEighth: "1/8"
        case .oneQuarter: "1/4"
        case .oneThird: "1/3"
        case .oneHalf: "1/2"
        case .twoThirds: "2/3"
        case .threeQuarters: "3/4"
        case .sevenEighths: "7/8"
        }
    }

    private var multiplier: Double {
        switch self {
        case .oneEighth: 0.125
        case .oneQuarter: 0.25
        case .oneThird: 1.0 / 3.0
        case .oneHalf: 0.5
        case .twoThirds: 2.0 / 3.0
        case .threeQuarters: 0.75
        case .sevenEighths: 0.875
        }
    }

    var percentageLabel: String {
        "\(Int((multiplier * 100).rounded()))%"
    }

    /// Converte la frazione in unità intere, senza mai superare la disponibilità.
    func quantity(of available: Int) -> Int {
        guard available > 0 else { return 0 }
        let rounded = Int((Double(available) * multiplier).rounded(.toNearestOrAwayFromZero))
        return min(max(rounded, 1), available)
    }
}
