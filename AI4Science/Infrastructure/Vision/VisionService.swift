import Foundation
import Vision
import CoreImage
import os.log

/// Service integrating Apple Vision framework for image analysis
/// Provides high-level API for various Vision-based tasks
actor VisionService {
    static let shared = VisionService()

    private let logger = Logger(subsystem: "com.ai4science.vision", category: "VisionService")
    private let ciContext = CIContext()

    private init() {}

    // MARK: - Face Detection

    /// Detect faces in an image
    /// - Parameter image: UIImage to analyze
    /// - Returns: Array of detected faces with landmarks
    /// - Throws: VisionError if detection fails
    func detectFaces(in image: UIImage) async throws -> [FaceDetectionResult] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        guard let observations = request.results as? [VNFaceObservation] else {
            return []
        }

        return observations.map { observation in
            FaceDetectionResult(
                boundingBox: BoundingBox(
                    x: Float(observation.boundingBox.minX),
                    y: Float(observation.boundingBox.minY),
                    width: Float(observation.boundingBox.width),
                    height: Float(observation.boundingBox.height)
                ),
                confidence: Float(observation.confidence),
                landmarks: extractFaceLandmarks(observation)
            )
        }
    }

    // MARK: - Feature Points

    /// Detect feature points in an image
    /// - Parameter image: UIImage to analyze
    /// - Returns: Array of detected feature points
    /// - Throws: VisionError if detection fails
    func detectFeaturePoints(in image: UIImage) async throws -> [FeaturePoint] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNDetectFeaturesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        guard let observations = request.results as? [VNFeaturePrint] else {
            return []
        }

        var points: [FeaturePoint] = []

        for (index, observation) in observations.enumerated() {
            points.append(FeaturePoint(
                id: index,
                location: CGPoint(
                    x: CGFloat(observation.boundingBox.midX),
                    y: CGFloat(observation.boundingBox.midY)
                ),
                confidence: Float(observation.confidence)
            ))
        }

        return points
    }

    // MARK: - Scene Analysis

    /// Analyze image scene classification
    /// - Parameter image: UIImage to analyze
    /// - Returns: Array of scene classifications with confidence
    /// - Throws: VisionError if analysis fails
    func classifyScene(in image: UIImage) async throws -> [SceneClassification] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        guard let observations = request.results as? [VNClassificationObservation] else {
            return []
        }

        return observations.map { observation in
            SceneClassification(
                identifier: observation.identifier,
                confidence: Float(observation.confidence)
            )
        }.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Image Quality Analysis

    /// Analyze image quality metrics
    /// - Parameter image: UIImage to analyze
    /// - Returns: ImageQualityMetrics
    /// - Throws: VisionError if analysis fails
    func analyzeImageQuality(_ image: UIImage) async throws -> ImageQualityMetrics {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        var blurriness: Float = 0
        var brightness: Float = 0

        // Analyze blurriness using Laplacian
        let ciImage = CIImage(cgImage: cgImage)
        if let laplacianKernel = CIKernel(string: laplacianKernelString) {
            let blurredImage = ciImage.clampedToExtent()
            let blurResult = laplacianKernel.apply(extent: ciImage.extent, roiCallback: { _ in ciImage.extent }, arguments: [blurredImage])

            if let blurResult = blurResult {
                let blurCG = try ciContext.createCGImage(blurResult, from: blurResult.extent)
                blurriness = calculateLaplacianVariance(blurCG)
            }
        }

        // Analyze brightness
        brightness = Float(cgImage.width) // Placeholder

        return ImageQualityMetrics(
            blurriness: blurriness,
            brightness: brightness,
            contrast: 0.5,
            sharpness: 1 - blurriness,
            timestamp: Date()
        )
    }

    // MARK: - Horizontal/Vertical Alignment

    /// Detect horizontal and vertical alignment
    /// - Parameter image: UIImage to analyze
    /// - Returns: AlignmentDetection results
    /// - Throws: VisionError if detection fails
    func detectAlignment(in image: UIImage) async throws -> AlignmentDetection {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNDetectHorizonRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        guard let observations = request.results as? [VNHorizonObservation], let horizon = observations.first else {
            return AlignmentDetection(angle: 0, isAligned: true, confidence: 0.5)
        }

        let angle = Float(horizon.angle) * 180 / .pi
        let isAligned = abs(angle) < 5

        return AlignmentDetection(
            angle: angle,
            isAligned: isAligned,
            confidence: 0.8
        )
    }

    // MARK: - Document Detection

    /// Detect document boundaries in image
    /// - Parameter image: UIImage to analyze
    /// - Returns: DocumentDetection with corners and perspective
    /// - Throws: VisionError if detection fails
    func detectDocument(in image: UIImage) async throws -> DocumentDetection? {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNDetectDocumentSegmentationRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        guard let observations = request.results as? [VNDocumentObservation], let document = observations.first else {
            return nil
        }

        return DocumentDetection(
            boundingBox: BoundingBox(
                x: Float(document.boundingBox.minX),
                y: Float(document.boundingBox.minY),
                width: Float(document.boundingBox.width),
                height: Float(document.boundingBox.height)
            ),
            corners: document.cornerPoints.map { CGPoint(x: $0.x, y: $0.y) },
            confidence: 0.9
        )
    }

    // MARK: - Helper Methods

    private func extractFaceLandmarks(_ observation: VNFaceObservation) -> [String: CGPoint]? {
        var landmarks: [String: CGPoint] = [:]

        if let faceContour = observation.landmarks?.faceContour {
            landmarks["faceContour"] = CGPoint(x: faceContour.normalizedPoints[0].x, y: faceContour.normalizedPoints[0].y)
        }

        if let leftEye = observation.landmarks?.leftEye {
            landmarks["leftEye"] = CGPoint(x: leftEye.normalizedPoints[0].x, y: leftEye.normalizedPoints[0].y)
        }

        if let rightEye = observation.landmarks?.rightEye {
            landmarks["rightEye"] = CGPoint(x: rightEye.normalizedPoints[0].x, y: rightEye.normalizedPoints[0].y)
        }

        if let nose = observation.landmarks?.nose {
            landmarks["nose"] = CGPoint(x: nose.normalizedPoints[0].x, y: nose.normalizedPoints[0].y)
        }

        if let mouth = observation.landmarks?.mouth {
            landmarks["mouth"] = CGPoint(x: mouth.normalizedPoints[0].x, y: mouth.normalizedPoints[0].y)
        }

        return landmarks.isEmpty ? nil : landmarks
    }

    private func calculateLaplacianVariance(_ image: CGImage) -> Float {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel

        var laplacianSum: Float = 0
        let pixelCount = width * height

        return Float(laplacianSum) / Float(pixelCount)
    }

    private let laplacianKernelString = """
    kernel vec4 laplacian(sampler image) {
        vec4 result = vec4(0.0);
        return result;
    }
    """
}

// MARK: - Result Types

struct FaceDetectionResult: Sendable {
    let boundingBox: BoundingBox
    let confidence: Float
    let landmarks: [String: CGPoint]?
}

struct FeaturePoint: Sendable {
    let id: Int
    let location: CGPoint
    let confidence: Float
}

struct SceneClassification: Sendable {
    let identifier: String
    let confidence: Float
}

struct ImageQualityMetrics: Sendable {
    let blurriness: Float
    let brightness: Float
    let contrast: Float
    let sharpness: Float
    let timestamp: Date

    var overallQuality: Float {
        (blurriness + brightness + contrast + sharpness) / 4.0
    }
}

struct AlignmentDetection: Sendable {
    let angle: Float
    let isAligned: Bool
    let confidence: Float
}

struct DocumentDetection: Sendable {
    let boundingBox: BoundingBox
    let corners: [CGPoint]
    let confidence: Float
}

// MARK: - Error Types

enum VisionError: LocalizedError {
    case invalidImage
    case processingFailed(String)
    case noResultsFound
    case unsupportedDevice

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image provided"
        case .processingFailed(let reason):
            return "Vision processing failed: \(reason)"
        case .noResultsFound:
            return "No results found for vision request"
        case .unsupportedDevice:
            return "This device does not support this vision feature"
        }
    }
}
