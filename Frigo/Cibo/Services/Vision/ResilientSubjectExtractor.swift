import Foundation

/// Prova l'estrattore primario e degrada al fallback senza interrompere l'aggiunta.
nonisolated struct ResilientSubjectExtractor: SubjectExtracting {
    private let primary: any SubjectExtracting
    private let fallback: any SubjectExtracting

    /// Crea l'adattatore resiliente con due implementazioni iniettate.
    init(primary: any SubjectExtracting, fallback: any SubjectExtracting) {
        self.primary = primary
        self.fallback = fallback
    }

    /// Estrae il soggetto o restituisce il PNG preprocessato senza sfondo rimosso.
    func extractSubject(from data: Data) async throws -> ExtractedSubject {
        do { return try await primary.extractSubject(from: data) }
        catch SubjectExtractionError.cancelled { throw SubjectExtractionError.cancelled }
        catch SubjectExtractionError.unreadableImage { throw SubjectExtractionError.unreadableImage }
        catch { return try await fallback.extractSubject(from: data) }
    }
}
