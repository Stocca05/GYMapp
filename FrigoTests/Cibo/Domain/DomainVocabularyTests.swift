import Foundation
import Testing
@testable import Frigo

/// Verifica il vocabolario value type del dominio Cibo.
struct DomainVocabularyTests {
    /// Verifica che gli identificatori mantengano il valore dopo un roundtrip Codable.
    ///
    /// - Throws: Propaga gli errori di codifica o decodifica.
    @Test func identifiersRoundTripThroughCodable() throws {
        let original = ProductID(rawValue: UUID(uuidString: "E21C5B5D-14A4-4C3F-9371-407D01873E90") ?? UUID())
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ProductID.self, from: encoded)

        #expect(decoded == original)
    }

    /// Verifica che uno snapshot conservi tutti i suoi value type dopo Codable.
    ///
    /// - Throws: Propaga gli errori di codifica o decodifica.
    @Test func productSnapshotRoundTripsThroughCodable() throws {
        let original = ProductSnapshot(
            id: ProductID(rawValue: UUID(uuidString: "064EEA47-0DB7-4EF5-9AD6-4D805608379E") ?? UUID()),
            name: "Milk",
            category: .dairy,
            baseUnit: .milliliters,
            defaultShelfLifeDays: 7,
            openShelfLifeDays: 3,
            defaultQuantityPerPackage: 1_000,
            displayScale: 1,
            imageAspectRatio: 1.5,
            thumbnailPNG: Data([0, 1, 2])
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ProductSnapshot.self, from: encoded)

        #expect(decoded == original)
    }

    /// Verifica uguaglianza e hashing degli identificatori tipizzati.
    @Test func identifiersUseTheirWrappedUUIDForEqualityAndHashing() {
        let uuid = UUID(uuidString: "D07393D3-A483-4B10-A6A3-451D1FFB0E0E") ?? UUID()
        let first = StockItemID(rawValue: uuid)
        let second = StockItemID(rawValue: uuid)

        #expect(first == second)
        #expect(Set([first, second]).count == 1)
    }

    /// Verifica il fallback della categoria per valori persistiti sconosciuti.
    @Test func unknownStoredCategoryFallsBackToOther() {
        #expect(ProductCategory(storedRawValue: "future-category") == .other)
        #expect(ProductCategory(storedRawValue: ProductCategory.dairy.rawValue) == .dairy)
    }

    /// Verifica le caratteristiche di tutte le unità di misura.
    @Test func unitsExposeExpectedContinuityAndSteps() {
        #expect(UnitOfMeasure.grams.isContinuous)
        #expect(UnitOfMeasure.milliliters.isContinuous)
        #expect(!UnitOfMeasure.pieces.isContinuous)
        #expect(UnitOfMeasure.grams.defaultStep == 10)
        #expect(UnitOfMeasure.milliliters.defaultStep == 10)
        #expect(UnitOfMeasure.pieces.defaultStep == 1)
    }

    /// Verifica che un draft prodotto valido non presenti violazioni.
    @Test func validProductDraftHasNoValidationIssues() {
        let draft = makeProductDraft()

        #expect(draft.validationIssues.isEmpty)
    }

    /// Verifica le violazioni del nome per un draft prodotto.
    @Test func productDraftValidatesEmptyAndLongNames() {
        let empty = makeProductDraft(name: "   ")
        let long = makeProductDraft(name: String(repeating: "a", count: 121))

        #expect(empty.validationIssues.contains(.emptyName))
        #expect(long.validationIssues.contains(.nameTooLong))
    }

    /// Verifica le violazioni di durata per un draft prodotto.
    @Test func productDraftValidatesEveryShelfLifeField() {
        let closed = makeProductDraft(shelfLifeDays: 0)
        let opened = makeProductDraft(openShelfLifeDays: -1)

        #expect(closed.validationIssues.contains(.nonPositiveShelfLife))
        #expect(opened.validationIssues.contains(.nonPositiveShelfLife))
    }

    /// Verifica i limiti della scala di visualizzazione.
    @Test func productDraftValidatesDisplayScaleBounds() {
        let tooSmall = makeProductDraft(displayScale: 0.49)
        let tooLarge = makeProductDraft(displayScale: 3.01)

        #expect(tooSmall.validationIssues.contains(.invalidScale))
        #expect(tooLarge.validationIssues.contains(.invalidScale))
    }

    /// Crea un draft prodotto valido, modificabile nei singoli campi del test.
    ///
    /// - Parameters:
    ///   - name: Nome del prodotto.
    ///   - defaultShelfLifeDays: Durata del prodotto chiuso.
    ///   - openShelfLifeDays: Durata del prodotto aperto.
    ///   - displayScale: Scala di visualizzazione dell'immagine.
    /// - Returns: Draft prodotto configurato per il test.
    private func makeProductDraft(
        name: String = "Milk",
        shelfLifeDays: Int = 7,
        openShelfLifeDays: Int? = 3,
        displayScale: Double = 1
    ) -> NewProductDraft {
        NewProductDraft(
            name: name,
            category: .dairy,
            baseUnit: .milliliters,
            initialQuantity: 1,
            location: .fridge,
            shelfLifeDays: shelfLifeDays,
            expirationDate: nil,
            openShelfLifeDays: openShelfLifeDays,
            displayScale: displayScale,
            imageData: nil
        )
    }
}
