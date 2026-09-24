import Foundation

/// Espone i dati immutabili di un prodotto al di fuori della persistenza.
nonisolated struct ProductSnapshot: Sendable, Hashable, Identifiable, Codable {
    /// Identificatore del prodotto.
    let id: ProductID

    /// Nome non localizzato del prodotto.
    let name: String

    /// Categoria merceologica del prodotto.
    let category: ProductCategory

    /// Unità base delle quantità del prodotto.
    let baseUnit: UnitOfMeasure

    /// Durata predefinita, in giorni, per una confezione chiusa.
    let defaultShelfLifeDays: Int?

    /// Durata predefinita, in giorni, dopo l'apertura.
    let openShelfLifeDays: Int?

    /// Quantità contenuta nella confezione standard del prodotto.
    let defaultQuantityPerPackage: Int

    /// Scala di visualizzazione dell'immagine, nell'intervallo da 0,5 a 3,0.
    let displayScale: Double

    /// Rapporto larghezza-altezza dell'immagine.
    let imageAspectRatio: Double

    /// PNG della miniatura; l'immagine full-size viene caricata su richiesta.
    let thumbnailPNG: Data?
}
