import Foundation

/// Raccoglie i dati immutabili necessari per creare un prodotto di catalogo.
nonisolated struct NewProductDraft: Sendable, Hashable, Codable {
    private static let maximumNameLength = 120
    private static let minimumDisplayScale = 0.5
    private static let maximumDisplayScale = 3.0

    /// Nome proposto per il prodotto.
    let name: String

    /// Categoria merceologica proposta.
    let category: ProductCategory

    /// Unità base proposta per le quantità.
    let baseUnit: UnitOfMeasure

    /// Numero di confezioni uguali aggiunte insieme.
    let packageCount: Int

    /// Quantità contenuta in ogni confezione.
    let quantityPerPackage: Int

    /// Quantità iniziale totale della prima registrazione.
    var initialQuantity: Int { packageCount * quantityPerPackage }

    /// Collocazione della prima confezione.
    let location: StorageLocation

    /// Durata predefinita, in giorni, per il prodotto chiuso.
    let shelfLifeDays: Int

    /// Scadenza esplicita della prima confezione, se scelta.
    let expirationDate: Date?

    /// Durata predefinita, in giorni, dopo l'apertura.
    let openShelfLifeDays: Int?

    /// Scala di visualizzazione proposta per l'immagine.
    let displayScale: Double

    /// Dati immagine originali, se scelti dall'utente.
    let imageData: Data?
    /// PNG miniatura già ridotto dalla pipeline immagini.
    let thumbnailData: Data?

    /// Crea un draft per un prodotto.
    ///
    /// - Parameters:
    ///   - name: Nome proposto per il prodotto.
    ///   - category: Categoria merceologica proposta.
    ///   - baseUnit: Unità base proposta.
    ///   - packageCount: Numero di confezioni uguali.
    ///   - quantityPerPackage: Quantità contenuta in ogni confezione.
    ///   - location: Collocazione della prima confezione.
    ///   - shelfLifeDays: Durata predefinita per il prodotto chiuso.
    ///   - expirationDate: Scadenza esplicita opzionale della prima confezione.
    ///   - openShelfLifeDays: Durata predefinita dopo l'apertura.
    ///   - displayScale: Scala di visualizzazione dell'immagine.
    ///   - imageData: Dati immagine originali opzionali.
    init(
        name: String,
        category: ProductCategory,
        baseUnit: UnitOfMeasure,
        packageCount: Int,
        quantityPerPackage: Int,
        location: StorageLocation,
        shelfLifeDays: Int,
        expirationDate: Date?,
        openShelfLifeDays: Int?,
        displayScale: Double,
        imageData: Data?,
        thumbnailData: Data? = nil
    ) {
        self.name = name
        self.category = category
        self.baseUnit = baseUnit
        self.packageCount = packageCount
        self.quantityPerPackage = quantityPerPackage
        self.location = location
        self.shelfLifeDays = shelfLifeDays
        self.expirationDate = expirationDate
        self.openShelfLifeDays = openShelfLifeDays
        self.displayScale = displayScale
        self.imageData = imageData
        self.thumbnailData = thumbnailData
    }

    /// Crea un draft compatibile con una singola confezione.
    ///
    /// - Parameters:
    ///   - name: Nome proposto per il prodotto.
    ///   - category: Categoria merceologica proposta.
    ///   - baseUnit: Unità base proposta.
    ///   - initialQuantity: Quantità iniziale totale.
    ///   - location: Collocazione della prima confezione.
    ///   - shelfLifeDays: Durata predefinita per prodotto chiuso.
    ///   - expirationDate: Scadenza esplicita opzionale.
    ///   - openShelfLifeDays: Durata predefinita dopo l'apertura.
    ///   - displayScale: Scala di visualizzazione dell'immagine.
    ///   - imageData: Dati immagine originali opzionali.
    ///   - thumbnailData: PNG opzionale della miniatura.
    init(name: String, category: ProductCategory, baseUnit: UnitOfMeasure, initialQuantity: Int, location: StorageLocation, shelfLifeDays: Int, expirationDate: Date?, openShelfLifeDays: Int?, displayScale: Double, imageData: Data?, thumbnailData: Data? = nil) {
        self.init(name: name, category: category, baseUnit: baseUnit, packageCount: 1, quantityPerPackage: initialQuantity, location: location, shelfLifeDays: shelfLifeDays, expirationDate: expirationDate, openShelfLifeDays: openShelfLifeDays, displayScale: displayScale, imageData: imageData, thumbnailData: thumbnailData)
    }

    /// Restituisce tutte le violazioni deterministiche del draft.
    var validationIssues: [ValidationIssue] {
        var issues: [ValidationIssue] = []

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyName)
        }
        if name.count > Self.maximumNameLength {
            issues.append(.nameTooLong)
        }
        if packageCount <= 0 || quantityPerPackage <= 0 {
            issues.append(.nonPositiveQuantity)
        }
        if shelfLifeDays <= 0 {
            issues.append(.nonPositiveShelfLife)
        }
        if let openShelfLifeDays, openShelfLifeDays <= 0 {
            issues.append(.nonPositiveShelfLife)
        }
        if !(Self.minimumDisplayScale...Self.maximumDisplayScale).contains(displayScale) {
            issues.append(.invalidScale)
        }

        return issues
    }
}
