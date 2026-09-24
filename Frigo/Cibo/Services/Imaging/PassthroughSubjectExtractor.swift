import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Prepara un'immagine PNG ridotta senza rimuoverne lo sfondo.
nonisolated struct PassthroughSubjectExtractor: SubjectExtracting {
    private static let fullSide = 1024
    private static let thumbnailSide = 384

    /// Crea l'estrattore di fallback.
    init() {}

    /// Riduce e codifica l'immagine fuori dal main actor.
    func extractSubject(from data: Data) async throws -> ExtractedSubject {
        try await Task.detached(priority: .userInitiated) {
            guard !Task.isCancelled else { throw SubjectExtractionError.cancelled }

            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let image = Self.image(from: source, side: Self.fullSide),
                  let thumbnailImage = Self.image(from: source, side: Self.thumbnailSide) else {
                throw SubjectExtractionError.unreadableImage
            }

            guard let full = Self.png(image),
                  let thumbnail = Self.png(thumbnailImage) else {
                throw SubjectExtractionError.processingFailed("PNG encoding failed")
            }

            return ExtractedSubject(
                fullPNG: full,
                thumbnailPNG: thumbnail,
                pixelSize: PixelSize(width: image.width, height: image.height),
                aspectRatio: Double(image.width) / Double(max(image.height, 1)),
                backgroundRemoved: false
            )
        }.value
    }

    private static func image(from source: CGImageSource, side: Int) -> CGImage? {
        CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: side
        ] as CFDictionary)
    }

    private static func png(_ image: CGImage) -> Data? {
        let result = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(result, UTType.png.identifier as CFString, 1, nil) else {
            return nil
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }

        return result as Data
    }
}
