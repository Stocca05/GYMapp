import Foundation

/// Classifica lo stato di freschezza rispetto a una data di riferimento.
nonisolated enum FreshnessState: Sendable, Hashable {
    /// Il prodotto non è prossimo alla scadenza.
    case fresh
    /// Il prodotto scade entro la soglia definita.
    case expiringSoon(daysLeft: Int)
    /// Il prodotto è già scaduto.
    case expired(daysAgo: Int)
}
