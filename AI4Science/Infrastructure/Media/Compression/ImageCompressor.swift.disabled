import UIKit
import ImageIO
import os.log

/// Service for compressing images for storage and upload
actor ImageCompressor {
    static let shared = ImageCompressor()

    private let logger = Logger(subsystem: "com.ai4science.media", category: "ImageCompressor")

    enum CompressionLevel {
        case low      // High quality, larger file
        case medium   // Balanced quality/size
        case high     // Lower quality, smaller file
        case maximum  // Lowest quality, smallest file

        var jpegQuality: CGFloat {
            switch self {
            case .low:
                return 0.95
            case .medium:
                return 0.80
            case .high:
                return 0.60
            case .maximum:
                return 0.40
            }
        }

        var heifQuality: Float {
            switch self {
            case .low:
                return 0.95
            case .medium:
                return 0.80
            case .high:
                return 0.60
            case .maximum:
                return 0.40
            }
        }
    }

    enum CompressionError: LocalizedError {
        case invalidImage
        case compressionFailed(String)
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Invalid image data"
            case .compressionFailed(let reason):
                return "Compression failed: \(reason)"
            case .invalidFormat:
                return "Unsupported image format"
            }
        }
    }

    nonisolated init() {
        // Empty init for actor
    }

    /// Compress image to specified level
    func compressImage(
        _ image: UIImage,
        to level: CompressionLevel = .medium
    ) async throws -> Data {
        return try await compressImage(image, quality: level.jpegQuality)
    }

    /// Compress image with custom quality
    func compressImage(
        _ image: UIImage,
        quality: CGFloat
    ) async throws -> Data {
        guard let jpegData = image.jpegData(compressionQuality: quality) else {
            throw CompressionError.invalidImage
        }

        logger.info("Image compressed, original quality: \(quality)")
        return jpegData
    }

    /// Compress image and resize
    func compressImage(
        _ image: UIImage,
        to targetSize: CGSize,
        compressionLevel: CompressionLevel = .medium
    ) async throws -> Data {
        let resizedImage = try resizeImage(image, to: targetSize)
        return try await compressImage(resizedImage, to: compressionLevel)
    }

    /// Compress image to target file size
    func compressImage(
        _ image: UIImage,
        targetFileSize: Int
    ) async throws -> Data {
        var quality: CGFloat = 0.95
        let step: CGFloat = 0.05

        var compressedData = image.jpegData(compressionQuality: quality)

        while let data = compressedData, data.count > targetFileSize, quality > 0.1 {
            quality -= step
            compressedData = image.jpegData(compressionQuality: quality)
        }

        guard let finalData = compressedData else {
            throw CompressionError.compressionFailed("Unable to reach target file size")
        }

        logger.info("Image compressed to \(finalData.count) bytes (target: \(targetFileSize))")
        return finalData
    }

    /// Batch compress images
    func batchCompressImages(
        _ images: [UIImage],
        to level: CompressionLevel = .medium
    ) async throws -> [Data] {
        var compressedImages: [Data] = []

        for (index, image) in images.enumerated() {
            let compressedData = try await compressImage(image, to: level)
            compressedImages.append(compressedData)

            logger.debug("Compressed image \(index + 1)/\(images.count)")
        }

        return compressedImages
    }

    /// Get compression ratio
    func getCompressionRatio(originalData: Data, compressedData: Data) -> Double {
        guard originalData.count > 0 else {
            return 0
        }

        let ratio = Double(compressedData.count) / Double(originalData.count)
        return ratio
    }

    /// Get compression savings in bytes
    func getCompressionSavings(originalData: Data, compressedData: Data) -> Int {
        return originalData.count - compressedData.count
    }

    /// Get compression savings formatted
    func getCompressionSavingsFormatted(originalData: Data, compressedData: Data) -> String {
        let savings = getCompressionSavings(originalData: originalData, compressedData: compressedData)
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(savings))
    }

    /// Estimate final file size for given quality
    func estimateCompressedSize(
        originalImage: UIImage,
        quality: CGFloat
    ) async throws -> Int {
        guard let estimatedData = originalImage.jpegData(compressionQuality: quality) else {
            throw CompressionError.invalidImage
        }

        return estimatedData.count
    }

    /// Convert image to more efficient format
    func convertToEfficientFormat(_ image: UIImage) async throws -> Data {
        // HEIF is more efficient than JPEG for most cases
        if #available(iOS 11.0, *) {
            if let heifData = image.heicData() {
                logger.info("Image converted to HEIF format")
                return heifData
            }
        }

        // Fallback to compressed JPEG
        return try await compressImage(image, to: .medium)
    }

    // MARK: - Private Methods

    private func resizeImage(_ image: UIImage, to targetSize: CGSize) throws -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)

        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        logger.debug("Image resized to \(targetSize)")
        return resizedImage
    }
}

extension UIImage {
    /// HEIF encoding (iOS 11+)
    func heicData() -> Data? {
        guard #available(iOS 11.0, *) else {
            return nil
        }

        guard let cgImage = cgImage else {
            return nil
        }

        let data = NSMutableData()

        guard let imageDestination = CGImageDestinationCreateWithData(
            data,
            AVFileType.heic.rawValue as CFString,
            1,
            nil
        ) else {
            return nil
        }

        CGImageDestinationAddImage(imageDestination, cgImage, nil)

        guard CGImageDestinationFinalize(imageDestination) else {
            return nil
        }

        return data as Data
    }
}
