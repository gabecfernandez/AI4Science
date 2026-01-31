import Foundation
import CoreML
import CoreImage
import Vision
import UIKit
import os.log

/// Service for preprocessing images before ML inference
/// Handles resizing, normalization, and pixel buffer conversion
actor ImagePreprocessor {
    static let shared = ImagePreprocessor()

    private let logger = Logger(subsystem: "com.ai4science.ml", category: "ImagePreprocessor")
    private let ciContext = CIContext()

    private init() {}

    // MARK: - Image Preparation

    /// Prepare an image for ML model inference
    /// - Parameters:
    ///   - image: UIImage to prepare
    ///   - model: MLModel to determine input requirements
    /// - Returns: CVPixelBuffer ready for inference
    /// - Throws: MLModelError if preparation fails
    func prepareImage(_ image: UIImage, for model: CoreML.MLModel) async throws -> CVPixelBuffer {
        // Get model input dimensions
        let modelInputDimensions = try getModelInputDimensions(model)

        // Resize image
        let resized = try await resizeImage(image, to: modelInputDimensions)

        // Convert to pixel buffer
        let pixelBuffer = try imageToPixelBuffer(resized)

        return pixelBuffer
    }

    /// Prepare images for batch inference
    /// - Parameters:
    ///   - images: Array of UIImage to prepare
    ///   - model: MLModel for dimension requirements
    /// - Returns: Array of CVPixelBuffer
    /// - Throws: MLModelError if any preparation fails
    func prepareImages(_ images: [UIImage], for model: CoreML.MLModel) async throws -> [CVPixelBuffer] {
        let modelInputDimensions = try getModelInputDimensions(model)

        var pixelBuffers: [CVPixelBuffer] = []

        for image in images {
            let resized = try await resizeImage(image, to: modelInputDimensions)
            let pixelBuffer = try imageToPixelBuffer(resized)
            pixelBuffers.append(pixelBuffer)
        }

        return pixelBuffers
    }

    // MARK: - Image Resizing

    /// Resize image to target dimensions
    /// - Parameters:
    ///   - image: UIImage to resize
    ///   - targetSize: Target dimensions
    /// - Returns: Resized UIImage
    private func resizeImage(
        _ image: UIImage,
        to targetSize: CGSize
    ) async throws -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)

        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        logger.debug("Resized image from \(image.size.width)x\(image.size.height) to \(targetSize.width)x\(targetSize.height)")

        return resizedImage
    }

    /// Resize image with aspect ratio preservation
    /// - Parameters:
    ///   - image: UIImage to resize
    ///   - maxSize: Maximum width/height
    /// - Returns: Resized UIImage preserving aspect ratio
    func resizeImagePreservingAspect(_ image: UIImage, maxSize: CGFloat) async throws -> UIImage {
        let scale = min(maxSize / image.size.width, maxSize / image.size.height)
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        return try await resizeImage(image, to: newSize)
    }

    // MARK: - Pixel Buffer Conversion

    /// Convert UIImage to CVPixelBuffer
    /// - Parameter image: UIImage to convert
    /// - Returns: CVPixelBuffer in BGRA format
    /// - Throws: MLModelError if conversion fails
    func imageToPixelBuffer(_ image: UIImage) throws -> CVPixelBuffer {
        guard let cgImage = image.cgImage else {
            throw MLModelError.invalidInput
        }

        let width = cgImage.width
        let height = cgImage.height

        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer = pixelBuffer else {
            throw MLModelError.invalidInput
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerPixel = 4
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            throw MLModelError.invalidInput
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        logger.debug("Converted image to pixel buffer: \(width)x\(height)")

        return pixelBuffer
    }

    /// Convert CVPixelBuffer to UIImage
    /// - Parameter pixelBuffer: CVPixelBuffer to convert
    /// - Returns: UIImage representation
    func pixelBufferToImage(_ pixelBuffer: CVPixelBuffer) throws -> UIImage {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            throw MLModelError.invalidOutput
        }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Image Normalization

    /// Normalize image pixel values
    /// - Parameters:
    ///   - image: UIImage to normalize
    ///   - mean: Mean values for each channel
    ///   - std: Standard deviation for each channel
    /// - Returns: Normalized CVPixelBuffer
    /// - Throws: MLModelError if normalization fails
    func normalizeImage(
        _ image: UIImage,
        mean: [Float] = [0.485, 0.456, 0.406],
        std: [Float] = [0.229, 0.224, 0.225]
    ) async throws -> CVPixelBuffer {
        let pixelBuffer = try imageToPixelBuffer(image)
        return try normalizePixelBuffer(pixelBuffer, mean: mean, std: std)
    }

    /// Normalize a pixel buffer
    /// - Parameters:
    ///   - pixelBuffer: CVPixelBuffer to normalize
    ///   - mean: Mean values for normalization
    ///   - std: Standard deviation for normalization
    /// - Returns: Normalized CVPixelBuffer
    private func normalizePixelBuffer(
        _ pixelBuffer: CVPixelBuffer,
        mean: [Float],
        std: [Float]
    ) throws -> CVPixelBuffer {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw MLModelError.invalidInput
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        let pixelCount = width * height
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        for i in 0..<pixelCount {
            let pixelIndex = i * 4
            let r = Float(buffer[pixelIndex]) / 255.0
            let g = Float(buffer[pixelIndex + 1]) / 255.0
            let b = Float(buffer[pixelIndex + 2]) / 255.0

            let normalizedR = (r - mean[0]) / std[0]
            let normalizedG = (g - mean[1]) / std[1]
            let normalizedB = (b - mean[2]) / std[2]

            buffer[pixelIndex] = UInt8(max(0, min(255, normalizedR * 255.0)))
            buffer[pixelIndex + 1] = UInt8(max(0, min(255, normalizedG * 255.0)))
            buffer[pixelIndex + 2] = UInt8(max(0, min(255, normalizedB * 255.0)))
        }

        return pixelBuffer
    }

    // MARK: - Model Input Inspection

    /// Get input dimensions from CoreML model
    /// - Parameter model: MLModel to inspect
    /// - Returns: CGSize with input dimensions
    /// - Throws: MLModelError if dimensions cannot be determined
    private func getModelInputDimensions(_ model: CoreML.MLModel) throws -> CGSize {
        guard let modelDescription = model.modelDescription.inputDescriptionsByName.first?.value else {
            throw MLModelError.configurationError("Cannot determine model input dimensions")
        }

        guard let imageConstraint = modelDescription.imageConstraint else {
            throw MLModelError.configurationError("Model input is not an image")
        }

        let width = imageConstraint.pixelsWide
        let height = imageConstraint.pixelsHigh

        return CGSize(width: width, height: height)
    }

    // MARK: - Batch Processing

    /// Preprocess images for batch inference
    /// - Parameters:
    ///   - images: Array of UIImage
    ///   - size: Target size for all images
    /// - Returns: Array of properly formatted CVPixelBuffer
    func preprocessBatch(
        _ images: [UIImage],
        to size: CGSize
    ) async throws -> [CVPixelBuffer] {
        var results: [CVPixelBuffer] = []

        for image in images {
            let resized = try await resizeImage(image, to: size)
            let pixelBuffer = try imageToPixelBuffer(resized)
            results.append(pixelBuffer)
        }

        return results
    }
}
