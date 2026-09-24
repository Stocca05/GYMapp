import Foundation

/// Rappresenta l'unità base usata per una quantità.
nonisolated enum UnitOfMeasure: String, Codable, CaseIterable, Sendable, Identifiable {
    /// Quantità espressa in grammi.
    case grams
    /// Quantità espressa in millilitri.
    case milliliters
    /// Quantità espressa in pezzi.
    case pieces

    /// Identificatore stabile dell'unità.
    var id: Self { self }

    /// Indica se la quantità può crescere a passi continui nell'interfaccia.
    var isContinuous: Bool {
        switch self {
        case .grams, .milliliters:
            true
        case .pieces:
            false
        }
    }

    /// Passo predefinito per l'immissione della quantità.
    var defaultStep: Int {
        switch self {
        case .grams, .milliliters:
            10
        case .pieces:
            1
        }
    }

    /// Restituisce l'abbreviazione da mostrare accanto a una quantità.
    var abbreviation: String {
        switch self {
        case .grams:
            "g"
        case .milliliters:
            "ml"
        case .pieces:
            "pz"
        }
    }
}
