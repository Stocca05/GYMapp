import Foundation

/// Fornisce l'istante corrente alle regole di dominio.
nonisolated protocol DateProviding: Sendable {
    /// Istante corrente fornito dall'implementazione.
    var now: Date { get }
}

/// Fornisce la data di sistema corrente.
nonisolated struct SystemDateProvider: DateProviding {
    /// Crea un provider basato sull'orologio di sistema.
    init() {}

    /// Restituisce l'istante corrente di sistema.
    var now: Date { Date() }
}

/// Fornisce una data fissa, utile per regole e test deterministici.
nonisolated struct FixedDateProvider: DateProviding {
    /// Istante fisso restituito dal provider.
    let now: Date

    /// Crea un provider che restituisce sempre lo stesso istante.
    ///
    /// - Parameter now: Istante fisso da restituire.
    init(now: Date) {
        self.now = now
    }
}
