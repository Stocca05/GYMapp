import Foundation

/// Rappresenta un soggetto estratto e serializzato in PNG.
nonisolated struct ExtractedSubject: Sendable, Hashable, Codable {
    /// PNG completo con lato lungo limitato.
    let fullPNG: Data
    /// PNG miniatura con lato lungo limitato.
    let thumbnailPNG: Data
    /// Dimensione in pixel dell'immagine completa.
    let pixelSize: PixelSize
    /// Rapporto larghezza-altezza dell'immagine completa.
    let aspectRatio: Double
    /// Indica se lo sfondo è stato rimosso.
    let backgroundRemoved: Bool
}

/// Rappresenta una dimensione in pixel trasferibile tra layer.
nonisolated struct PixelSize: Sendable, Hashable, Codable {
    /// Larghezza in pixel.
    let width: Int
    /// Altezza in pixel.
    let height: Int
}

/// Descrive gli errori tipizzati dell'estrazione soggetto.
nonisolated enum SubjectExtractionError: Error, Sendable, Equatable {
    case unreadableImage, noSubjectFound, unsupportedOnThisDevice, processingFailed(String), cancelled
}

/// Estrae un soggetto da dati immagine senza esporre tipi UIKit.
nonisolated protocol SubjectExtracting: Sendable {
    /// Estrae e prepara il soggetto dall'immagine.
    func extractSubject(from data: Data) async throws -> ExtractedSubject
}
