import Foundation

/// Applica le regole pure relative a scadenze e freschezza.
nonisolated struct ExpirationPolicy {
    /// Numero di giorni entro cui un prodotto è prossimo alla scadenza.
    static let expiringSoonThresholdDays = 2

    /// Calcola la scadenza iniziale a inizio giornata usando giorni di calendario.
    ///
    /// - Parameters:
    ///   - addedOn: Data in cui la confezione viene aggiunta.
    ///   - shelfLifeDays: Durata in giorni di calendario.
    ///   - overrideDate: Scadenza esplicita che prevale sul calcolo, se presente.
    ///   - calendar: Calendario da usare per i calcoli.
    /// - Returns: Data di scadenza normalizzata a inizio giornata.
    static func initialExpiration(
        addedOn: Date,
        shelfLifeDays: Int,
        overrideDate: Date?,
        calendar: Calendar
    ) -> Date {
        if let overrideDate {
            return calendar.startOfDay(for: overrideDate)
        }

        let start = calendar.startOfDay(for: addedOn)
        return calendar.date(byAdding: .day, value: shelfLifeDays, to: start) ?? start
    }

    /// Riduce la scadenza dopo l'apertura senza estenderla mai.
    ///
    /// - Parameters:
    ///   - current: Scadenza corrente del lotto.
    ///   - openedOn: Data di apertura del lotto.
    ///   - openShelfLifeDays: Durata dopo l'apertura, se valida.
    ///   - calendar: Calendario da usare per i calcoli.
    /// - Returns: La minore fra scadenza corrente e scadenza dopo l'apertura.
    static func expirationAfterOpening(
        current: Date,
        openedOn: Date,
        openShelfLifeDays: Int?,
        calendar: Calendar
    ) -> Date {
        guard let openShelfLifeDays, openShelfLifeDays > 0 else {
            return current
        }

        let openingDay = calendar.startOfDay(for: openedOn)
        guard let openingExpiration = calendar.date(
            byAdding: .day,
            value: openShelfLifeDays,
            to: openingDay
        ) else {
            return current
        }

        return min(current, openingExpiration)
    }

    /// Calcola i giorni di calendario fino alla scadenza; un valore negativo indica scadenza passata.
    ///
    /// - Parameters:
    ///   - expirationDate: Data di scadenza.
    ///   - referenceDate: Data da cui calcolare la distanza.
    ///   - calendar: Calendario da usare per i calcoli.
    /// - Returns: Differenza in giorni di calendario.
    static func daysRemaining(until expirationDate: Date, from referenceDate: Date, calendar: Calendar) -> Int {
        let expirationDay = calendar.startOfDay(for: expirationDate)
        let referenceDay = calendar.startOfDay(for: referenceDate)
        return calendar.dateComponents([.day], from: referenceDay, to: expirationDay).day ?? 0
    }

    /// Classifica la freschezza a partire dalla distanza in giorni di calendario.
    ///
    /// - Parameters:
    ///   - expirationDate: Data di scadenza da classificare.
    ///   - referenceDate: Data di riferimento.
    ///   - calendar: Calendario da usare per i calcoli.
    /// - Returns: Stato di freschezza deterministico.
    static func freshness(
        until expirationDate: Date,
        from referenceDate: Date,
        calendar: Calendar
    ) -> FreshnessState {
        let remaining = daysRemaining(until: expirationDate, from: referenceDate, calendar: calendar)

        if remaining < 0 {
            return .expired(daysAgo: -remaining)
        }
        if remaining <= expiringSoonThresholdDays {
            return .expiringSoon(daysLeft: remaining)
        }
        return .fresh
    }
}
