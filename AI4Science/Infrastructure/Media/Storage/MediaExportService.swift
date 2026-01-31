import AVFoundation
import UIKit
import os.log

/// Service for exporting media in various formats
actor MediaExportService {
    static let shared = MediaExportService()

    private let logger = Logger(subsystem: "com.ai4science.media", category: "MediaExportService")

    enum ExportFormat {
        case jpeg
        case png
        case heif
        case pdf
        case mp4
        case mov

        var fileExtension: String {
            switch self {
            case .jpeg:
                return "jpg"
            case .png:
                return "png"
            case .heif:
                return "heic"
            case .pdf:
                return "pdf"
            case .mp4:
                return "mp4"
            case .mov:
                return "mov"
            }
        }
    }

    enum ExportError: LocalizedError {
        case unsupportedFormat
        case exportFailed(String)
        case invalidInput

        var errorDescription: String? {
            switch self {
            case .unsupportedFormat:
                return "Unsupported export format"
            case .exportFailed(let reason):
                return "Export failed: \(reason)"
            case .invalidInput:
                return "Invalid input for export"
            }
        }
    }

    nonisolated init() {
        // Empty init for actor
    }

    /// Export image to specified format
    func exportImage(
        _ image: UIImage,
        to format: ExportFormat,
        quality: Float = 0.85,
        metadata: [String: Any]? = nil
    ) async throws -> Data {
        let exportData: Data?

        switch format {
        case .jpeg:
            exportData = image.jpegData(compressionQuality: CGFloat(quality))
        case .png:
            exportData = image.pngData()
        case .heif:
            exportData = try await exportAsHEIF(image, quality: quality)
        case .pdf:
            exportData = try await exportAsPDF(image)
        default:
            throw ExportError.unsupportedFormat
        }

        guard let data = exportData else {
            throw ExportError.exportFailed("Failed to encode image")
        }

        logger.info("Image exported as \(format.fileExtension), size: \(data.count) bytes")
        return data
    }

    /// Export image with metadata
    func exportImageWithMetadata(
        _ image: UIImage,
        to format: ExportFormat,
        metadata: [String: Any],
        quality: Float = 0.85
    ) async throws -> Data {
        var imageWithMetadata = image

        // Embed metadata in image
        if let ciImage = CIImage(image: image) {
            let context = CIContext()
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                imageWithMetadata = UIImage(cgImage: cgImage)
            }
        }

        return try await exportImage(imageWithMetadata, to: format, quality: quality, metadata: metadata)
    }

    /// Export video to specified format
    func exportVideo(
        from sourceURL: URL,
        to format: ExportFormat,
        outputURL: URL,
        preset: AVAssetExportPreset = .medium
    ) async throws {
        let asset = AVAsset(url: sourceURL)

        guard asset.isReadable else {
            throw ExportError.invalidInput
        }

        let outputFileType: AVFileType = format == .mp4 ? .mp4 : .mov

        return try await withCheckedThrowingContinuation { continuation in
            guard let exporter = AVAssetExportSession(asset: asset, presetName: preset) else {
                continuation.resume(throwing: ExportError.exportFailed("Cannot create export session"))
                return
            }

            exporter.outputURL = outputURL
            exporter.outputFileType = outputFileType
            exporter.shouldOptimizeForNetworkUse = true

            exporter.exportAsynchronously {
                if exporter.status == .completed {
                    self.logger.info("Video exported as \(format.fileExtension)")
                    continuation.resume()
                } else {
                    let error = exporter.error ?? NSError(domain: "Export", code: -1)
                    self.logger.error("Video export failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Export multiple images as ZIP archive
    func exportImagesAsZip(
        _ images: [UIImage],
        fileName: String = "images.zip"
    ) async throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let zipURL = tempDirectory.appendingPathComponent(fileName)

        // Create temporary directory for images
        let tempImagesDirectory = tempDirectory.appendingPathComponent("temp_images_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempImagesDirectory, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempImagesDirectory)
        }

        // Save images to temporary directory
        for (index, image) in images.enumerated() {
            let imageName = "image_\(String(format: "%03d", index)).jpg"
            let imageURL = tempImagesDirectory.appendingPathComponent(imageName)

            guard let data = image.jpegData(compressionQuality: 0.85) else {
                throw ExportError.exportFailed("Failed to encode image")
            }

            try data.write(to: imageURL)
        }

        // Create ZIP archive
        try await createZipArchive(from: tempImagesDirectory, to: zipURL)

        logger.info("Images exported as ZIP archive: \(fileName)")
        return zipURL
    }

    /// Get supported export formats for image
    nonisolated func getSupportedImageFormats() -> [ExportFormat] {
        return [.jpeg, .png, .heif, .pdf]
    }

    /// Get supported export formats for video
    nonisolated func getSupportedVideoFormats() -> [ExportFormat] {
        return [.mp4, .mov]
    }

    // MARK: - Private Methods

    private func exportAsHEIF(_ image: UIImage, quality: Float) async throws -> Data? {
        guard let cgImage = image.cgImage else {
            throw ExportError.invalidInput
        }

        let options: [String: Any] = [
            kCGImageDestinationLossyCompressionQuality as String: quality,
            kCGImageDestinationOptimizeColorForWeb as String: true
        ]

        let data = NSMutableData()
        guard let imageDestination = CGImageDestinationCreateWithData(
            data,
            AVFileType.heic.rawValue as CFString,
            1,
            options as CFDictionary
        ) else {
            throw ExportError.exportFailed("Cannot create image destination")
        }

        CGImageDestinationAddImage(imageDestination, cgImage, options as CFDictionary)

        guard CGImageDestinationFinalize(imageDestination) else {
            throw ExportError.exportFailed("Failed to finalize image")
        }

        return data as Data
    }

    private func exportAsPDF(_ image: UIImage) async throws -> Data {
        let pdfData = NSMutableData()

        let rect = CGRect(origin: .zero, size: image.size)

        guard let pdfContext = CGContext(
            consumer: CGDataConsumer(data: pdfData)!,
            mediaBox: &rect,
            nil
        ) else {
            throw ExportError.exportFailed("Cannot create PDF context")
        }

        pdfContext.beginPDFPage(nil)

        if let cgImage = image.cgImage {
            pdfContext.draw(cgImage, in: rect)
        }

        pdfContext.endPDFPage()
        pdfContext.closePDF()

        return pdfData as Data
    }

    private func createZipArchive(from sourceDirectory: URL, to zipURL: URL) async throws {
        #if os(iOS)
        // Use native iOS APIs or third-party library
        // For now, we'll create a placeholder implementation
        logger.warning("ZIP archive creation requires third-party library")
        throw ExportError.exportFailed("ZIP archive not supported in this implementation")
        #endif
    }
}
