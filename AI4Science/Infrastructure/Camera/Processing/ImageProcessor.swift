import UIKit
import CoreImage
import os.log

/// Service for processing captured images (crop, rotate, enhance)
actor ImageProcessor {
    static let shared = ImageProcessor()

    private let logger = Logger(subsystem: "com.ai4science.camera", category: "ImageProcessor")

    private let context = CIContext(options: [.useSoftwareRenderer: false])
    private let queue = DispatchQueue(label: "com.ai4science.image.processing", attributes: .concurrent)

    enum ImageProcessingError: LocalizedError {
        case invalidImage
        case processingFailed(String)
        case unsupportedFormat

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Invalid image data"
            case .processingFailed(let reason):
                return "Image processing failed: \(reason)"
            case .unsupportedFormat:
                return "Unsupported image format"
            }
        }
    }

    struct ProcessingOptions {
        let cropRect: CGRect?
        let rotationAngle: CGFloat
        let brightness: CGFloat
        let contrast: CGFloat
        let saturation: CGFloat
        let targetSize: CGSize?
        let cornerRadius: CGFloat?

        init(
            cropRect: CGRect? = nil,
            rotationAngle: CGFloat = 0,
            brightness: CGFloat = 0,
            contrast: CGFloat = 1,
            saturation: CGFloat = 1,
            targetSize: CGSize? = nil,
            cornerRadius: CGFloat? = nil
        ) {
            self.cropRect = cropRect
            self.rotationAngle = rotationAngle
            self.brightness = brightness
            self.contrast = contrast
            self.saturation = saturation
            self.targetSize = targetSize
            self.cornerRadius = cornerRadius
        }
    }

    nonisolated init() {
        // Empty init for actor
    }

    /// Process image from data
    func processImage(from data: Data, options: ProcessingOptions = ProcessingOptions()) async throws -> UIImage {
        guard let originalImage = UIImage(data: data) else {
            throw ImageProcessingError.invalidImage
        }

        return try await processImage(originalImage, options: options)
    }

    /// Process UIImage
    func processImage(_ image: UIImage, options: ProcessingOptions = ProcessingOptions()) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw ImageProcessingError.invalidImage
        }

        let ciImage = CIImage(cgImage: cgImage)

        // Apply transformations
        var processedImage = ciImage

        // Crop if specified
        if let cropRect = options.cropRect {
            processedImage = processedImage.cropped(to: cropRect)
        }

        // Apply adjustments
        if options.brightness != 0 || options.contrast != 1 || options.saturation != 1 {
            processedImage = try applyColorAdjustments(
                processedImage,
                brightness: options.brightness,
                contrast: options.contrast,
                saturation: options.saturation
            )
        }

        // Rotate if specified
        if options.rotationAngle != 0 {
            processedImage = processedImage.transformed(by: CGAffineTransform(rotationAngle: options.rotationAngle))
        }

        // Render to CGImage
        guard let outputCGImage = context.createCGImage(processedImage, from: processedImage.extent) else {
            throw ImageProcessingError.processingFailed("Failed to render processed image")
        }

        var resultImage = UIImage(cgImage: outputCGImage)

        // Resize if specified
        if let targetSize = options.targetSize {
            resultImage = try resizeImage(resultImage, to: targetSize)
        }

        // Apply corner radius if specified
        if let cornerRadius = options.cornerRadius {
            resultImage = try applyCornerRadius(resultImage, radius: cornerRadius)
        }

        logger.info("Image processed successfully")
        return resultImage
    }

    /// Crop image to specified rect
    func cropImage(_ image: UIImage, to rect: CGRect) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw ImageProcessingError.invalidImage
        }

        let scaledRect = CGRect(
            x: rect.origin.x * image.scale,
            y: rect.origin.y * image.scale,
            width: rect.size.width * image.scale,
            height: rect.size.height * image.scale
        )

        guard let croppedCGImage = cgImage.cropping(to: scaledRect) else {
            throw ImageProcessingError.processingFailed("Failed to crop image")
        }

        logger.info("Image cropped to rect: \(rect)")
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    /// Rotate image
    func rotateImage(_ image: UIImage, degrees: CGFloat) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw ImageProcessingError.invalidImage
        }

        let ciImage = CIImage(cgImage: cgImage)
        let radians = degrees * .pi / 180

        let rotatedImage = ciImage.transformed(by: CGAffineTransform(rotationAngle: radians))

        guard let outputCGImage = context.createCGImage(rotatedImage, from: rotatedImage.extent) else {
            throw ImageProcessingError.processingFailed("Failed to rotate image")
        }

        logger.info("Image rotated by \(degrees) degrees")
        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    /// Enhance image (auto-adjust brightness, contrast, saturation)
    func enhanceImage(_ image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw ImageProcessingError.invalidImage
        }

        let ciImage = CIImage(cgImage: cgImage)

        // Apply enhancement filter
        let enhancementFilter = CIFilter(name: "CIColorControls")
        enhancementFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        enhancementFilter?.setValue(0.1, forKey: kCIInputBrightnessKey)
        enhancementFilter?.setValue(1.2, forKey: kCIInputContrastKey)
        enhancementFilter?.setValue(1.1, forKey: kCIInputSaturationKey)

        guard let enhancedCIImage = enhancementFilter?.outputImage else {
            throw ImageProcessingError.processingFailed("Enhancement filter failed")
        }

        guard let outputCGImage = context.createCGImage(enhancedCIImage, from: enhancedCIImage.extent) else {
            throw ImageProcessingError.processingFailed("Failed to render enhanced image")
        }

        logger.info("Image enhanced")
        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    /// Apply noise reduction
    func reduceNoise(_ image: UIImage, strength: Float = 10) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw ImageProcessingError.invalidImage
        }

        let ciImage = CIImage(cgImage: cgImage)

        let noiseReductionFilter = CIFilter(name: "CINoiseReduction")
        noiseReductionFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        noiseReductionFilter?.setValue(strength, forKey: kCIInputNoiseReductionAmountKey)

        guard let denoisedCIImage = noiseReductionFilter?.outputImage else {
            throw ImageProcessingError.processingFailed("Noise reduction filter failed")
        }

        guard let outputCGImage = context.createCGImage(denoisedCIImage, from: denoisedCIImage.extent) else {
            throw ImageProcessingError.processingFailed("Failed to render denoised image")
        }

        logger.info("Noise reduction applied with strength: \(strength)")
        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Private Methods

    private func applyColorAdjustments(
        _ image: CIImage,
        brightness: CGFloat,
        contrast: CGFloat,
        saturation: CGFloat
    ) throws -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else {
            throw ImageProcessingError.processingFailed("ColorControls filter not available")
        }

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter.setValue(contrast, forKey: kCIInputContrastKey)
        filter.setValue(saturation, forKey: kCIInputSaturationKey)

        guard let outputImage = filter.outputImage else {
            throw ImageProcessingError.processingFailed("Failed to apply color adjustments")
        }

        return outputImage
    }

    private func resizeImage(_ image: UIImage, to size: CGSize) throws -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)

        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }

        logger.info("Image resized to \(size)")
        return resizedImage
    }

    private func applyCornerRadius(_ image: UIImage, radius: CGFloat) throws -> UIImage {
        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)

        let roundedImage = renderer.image { context in
            let path = UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: size),
                cornerRadius: radius
            )
            path.addClip()
            image.draw(in: CGRect(origin: .zero, size: size))
        }

        logger.info("Corner radius applied: \(radius)")
        return roundedImage
    }
}
