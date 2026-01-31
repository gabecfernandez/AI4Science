import Foundation
import CoreML
import Vision
import os.log

/// Service for running defect detection on samples
/// Uses object detection models optimized for defect identification
actor DefectDetectionService {
    private let modelManager: MLModelManager
    private let preprocessor: ImagePreprocessor
    private let postprocessor: ResultPostprocessor
    private let logger = Logger(subsystem: "com.ai4science.ml", category: "DefectDetectionService")

    private var detectionModel: MLModel?
    private let modelName = "DefectDetectionModel"

    init(modelManager: MLModelManager = .shared,
         preprocessor: ImagePreprocessor = .shared,
         postprocessor: ResultPostprocessor = .shared) {
        self.modelManager = modelManager
        self.preprocessor = preprocessor
        self.postprocessor = postprocessor
    }

    // MARK: - Initialization

    /// Initialize the defect detection service and load the model
    /// - Throws: MLModelError if model loading fails
    func initialize() async throws {
        guard detectionModel == nil else {
            logger.debug("Defect detection model already loaded")
            return
        }

        detectionModel = try await modelManager.loadModel(named: modelName)
        logger.debug("Defect detection model initialized")
    }

    // MARK: - Defect Detection

    /// Detect defects in an image
    /// - Parameters:
    ///   - image: UIImage to analyze
    ///   - confidenceThreshold: Minimum confidence score (0-1)
    /// - Returns: Array of DefectPrediction results
    /// - Throws: MLModelError if detection fails
    func detectDefects(in image: UIImage, confidenceThreshold: Float = 0.5) async throws -> [DefectPrediction] {
        guard let detectionModel else {
            logger.error("Detection model not initialized")
            throw MLModelError.configurationError("Model not initialized")
        }

        // Preprocess image
        let pixelBuffer = try await preprocessor.prepareImage(image, for: detectionModel)

        // Run inference
        let input = try createModelInput(pixelBuffer: pixelBuffer)
        let output = try detectionModel.prediction(from: input)

        // Postprocess results
        let predictions = try await postprocessor.parseDefectDetectionOutput(output)

        // Filter by confidence
        let filteredPredictions = predictions.filter { $0.confidence >= confidenceThreshold }

        logger.debug("Detected \(filteredPredictions.count) defects")

        return filteredPredictions
    }

    /// Detect defects in multiple images
    /// - Parameters:
    ///   - images: Array of UIImage to analyze
    ///   - confidenceThreshold: Minimum confidence score
    /// - Returns: Array of DefectDetectionResult containing image and predictions
    /// - Throws: MLModelError if any detection fails
    func detectDefects(in images: [UIImage], confidenceThreshold: Float = 0.5) async throws -> [DefectDetectionResult] {
        var results: [DefectDetectionResult] = []

        for (index, image) in images.enumerated() {
            let predictions = try await detectDefects(in: image, confidenceThreshold: confidenceThreshold)
            let result = DefectDetectionResult(
                imageIndex: index,
                image: image,
                predictions: predictions,
                timestamp: Date()
            )
            results.append(result)
        }

        return results
    }

    /// Stream real-time defect detection from video frames
    /// - Parameters:
    ///   - frameStream: AsyncStream of CVPixelBuffer frames
    ///   - confidenceThreshold: Minimum confidence score
    /// - Returns: AsyncStream of DefectDetectionFrame results
    func streamDefectDetection(
        from frameStream: AsyncStream<CVPixelBuffer>,
        confidenceThreshold: Float = 0.5
    ) -> AsyncStream<DefectDetectionFrame> {
        AsyncStream { continuation in
            Task {
                guard let detectionModel else {
                    logger.error("Detection model not initialized")
                    continuation.finish()
                    return
                }

                for await pixelBuffer in frameStream {
                    do {
                        let input = try createModelInput(pixelBuffer: pixelBuffer)
                        let output = try detectionModel.prediction(from: input)
                        let predictions = try await postprocessor.parseDefectDetectionOutput(output)
                        let filtered = predictions.filter { $0.confidence >= confidenceThreshold }

                        let frame = DefectDetectionFrame(
                            pixelBuffer: pixelBuffer,
                            predictions: filtered,
                            timestamp: Date()
                        )
                        continuation.yield(frame)
                    } catch {
                        logger.error("Frame processing error: \(error.localizedDescription)")
                    }
                }

                continuation.finish()
            }
        }
    }

    // MARK: - Model Input Creation

    private func createModelInput(pixelBuffer: CVPixelBuffer) throws -> MLFeatureProvider {
        guard let input = try? MLDictionaryFeatureProvider(
            dictionary: ["image": MLFeatureValue(pixelBuffer: pixelBuffer)]
        ) else {
            throw MLModelError.invalidInput
        }
        return input
    }

    // MARK: - Cleanup

    /// Unload the detection model
    nonisolated func unload() {
        Task {
            await unloadInternal()
        }
    }

    private func unloadInternal() {
        detectionModel = nil
        logger.debug("Defect detection model unloaded")
    }
}

// MARK: - Result Models

/// Result of a single defect detection
struct DefectPrediction: Codable, Sendable {
    let defectType: String
    let confidence: Float
    let boundingBox: BoundingBox
    let severity: DetectionSeverity
    let location: String?

    enum CodingKeys: String, CodingKey {
        case defectType = "type"
        case confidence
        case boundingBox = "box"
        case severity
        case location
    }
}

/// Severity level of detected defect
enum DetectionSeverity: String, Codable, Sendable {
    case low
    case medium
    case high
    case critical
}

/// Complete defect detection result for an image
struct DefectDetectionResult: Sendable {
    let imageIndex: Int
    let image: UIImage
    let predictions: [DefectPrediction]
    let timestamp: Date

    var hasDefects: Bool {
        !predictions.isEmpty
    }

    var severityLevel: DetectionSeverity? {
        predictions.max { $0.severity.rawValue < $1.severity.rawValue }?.severity
    }
}

/// Real-time defect detection frame result
struct DefectDetectionFrame: Sendable {
    let pixelBuffer: CVPixelBuffer
    let predictions: [DefectPrediction]
    let timestamp: Date

    var hasDefects: Bool {
        !predictions.isEmpty
    }
}
