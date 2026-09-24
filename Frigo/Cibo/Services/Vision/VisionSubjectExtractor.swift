import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers
import Vision

/// Rimuove lo sfondo con la maschera di istanza foreground di Vision.
nonisolated struct VisionSubjectExtractor: SubjectExtracting {
    private static let ciContext = CIContext()
    private let fallback = PassthroughSubjectExtractor()

    /// Crea l'estrattore Vision.
    init() {}

    /// Genera un PNG scontornato fuori dal main actor.
    func extractSubject(from data: Data) async throws -> ExtractedSubject {
        #if targetEnvironment(simulator)
        throw SubjectExtractionError.unsupportedOnThisDevice
        #else
        return try await Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                      kCGImageSourceCreateThumbnailFromImageAlways: true,
                      kCGImageSourceCreateThumbnailWithTransform: true,
                      kCGImageSourceThumbnailMaxPixelSize: 1024
                  ] as CFDictionary) else {
                throw SubjectExtractionError.unreadableImage
            }

            guard !Task.isCancelled else { throw SubjectExtractionError.cancelled }

            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(cgImage: image)

            do {
                try handler.perform([request])
            } catch {
                throw SubjectExtractionError.unsupportedOnThisDevice
            }

            guard let result = request.results?.first, !result.allInstances.isEmpty else {
                throw SubjectExtractionError.noSubjectFound
            }

            let buffer: CVPixelBuffer
            do {
                buffer = try result.generateMaskedImage(
                    ofInstances: result.allInstances,
                    from: handler,
                    croppedToInstancesExtent: true
                )
            } catch {
                throw SubjectExtractionError.processingFailed(String(describing: error))
            }

            let masked = CIImage(cvPixelBuffer: buffer)

            guard let output = Self.ciContext.createCGImage(masked, from: masked.extent),
                  let png = Self.png(output) else {
                throw SubjectExtractionError.processingFailed("Unable to encode mask")
            }

            let preview = try await fallback.extractSubject(from: png)

            return ExtractedSubject(
                fullPNG: png,
                thumbnailPNG: preview.thumbnailPNG,
                pixelSize: PixelSize(width: output.width, height: output.height),
                aspectRatio: Double(output.width) / Double(max(output.height, 1)),
                backgroundRemoved: true
            )
        }.value
        #endif
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
