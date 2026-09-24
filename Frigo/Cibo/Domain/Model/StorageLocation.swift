import Foundation

/// Indica il luogo fisico in cui è conservato un lotto.
nonisolated enum StorageLocation: String, Codable, CaseIterable, Sendable, Identifiable {
    /// Frigorifero.
    case fridge
    /// Congelatore.
    case freezer
    /// Dispensa.
    case pantry

    /// Identificatore stabile della collocazione.
    var id: Self { self }

    /// Numero predefinito di ripiani disponibili.
    var defaultShelfCount: Int {
        switch self {
        case .fridge, .pantry:
            4
        case .freezer:
            3
        }
    }

    /// Restituisce il nome italiano da mostrare all'utente.
    var displayName: String {
        switch self {
        case .fridge: "Frigorifero"
        case .freezer: "Congelatore"
        case .pantry: "Dispensa"
        }
    }
}
