import Foundation

/// Classifica merceologicamente un prodotto.
nonisolated enum ProductCategory: String, Codable, CaseIterable, Sendable, Identifiable {
    /// Categoria degli alimenti ricchi di carboidrati.
    case carbohydrates
    /// Categoria degli alimenti proteici.
    case proteins
    /// Categoria delle verdure.
    case vegetables
    /// Categoria della frutta.
    case fruits
    /// Categoria delle salse.
    case sauces
    /// Categoria dei latticini.
    case dairy
    /// Categoria degli snack.
    case snacks
    /// Categoria delle bevande.
    case beverages
    /// Categoria delle spezie.
    case spices
    /// Categoria di ripiego per valori non riconosciuti.
    case other

    /// Identificatore stabile della categoria.
    var id: Self { self }

    /// Decodifica un valore persistito, usando `other` per valori sconosciuti.
    ///
    /// - Parameter storedRawValue: Valore grezzo letto dalla persistenza.
    init(storedRawValue: String) {
        self = Self(rawValue: storedRawValue) ?? .other
    }

    /// Restituisce il nome italiano da mostrare all'utente.
    var displayName: String {
        switch self {
        case .carbohydrates: "Carboidrati"
        case .proteins: "Proteine"
        case .vegetables: "Verdure"
        case .fruits: "Frutta"
        case .sauces: "Salse"
        case .dairy: "Latticini"
        case .snacks: "Snack"
        case .beverages: "Bevande"
        case .spices: "Spezie"
        case .other: "Altro"
        }
    }
}
