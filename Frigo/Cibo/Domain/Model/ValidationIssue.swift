import Foundation

/// Descrive una violazione di validazione condivisa da interfaccia e store.
nonisolated enum ValidationIssue: Hashable, Sendable, Codable {
    /// Il nome è vuoto o contiene solo spazi.
    case emptyName
    /// Il nome supera la lunghezza massima consentita.
    case nameTooLong
    /// Una quantità richiesta è zero o negativa.
    case nonPositiveQuantity
    /// Una durata in giorni è zero o negativa.
    case nonPositiveShelfLife
    /// La scala di visualizzazione non appartiene all'intervallo consentito.
    case invalidScale
    /// Un piatto deve contenere almeno un ingrediente.
    case missingIngredients
    /// Un ingrediente può comparire una sola volta nel piatto.
    case duplicateIngredient
}
