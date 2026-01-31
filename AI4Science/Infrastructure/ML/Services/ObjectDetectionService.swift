import Foundation
import CoreML
import Vision
import os.log

/// Service for object detection with bounding boxes
/// Detects and localizes objects in images
actor ObjectDetectionService {
    private let modelManager: MLModelManager
    private let preprocessor: ImagePreprocessor
    private let postprocessor: ResultPostprocessor
    private let logger = Logger(subsystem: "com.ai4science.ml", category: "ObjectDetectionService")

    private var detectionModel: MLModel?
    private let modelName = "ObjectDetectionModel"

    init(modelManager: MLModelManager = .shared,
         preprocessor: ImagePreprocessor = .shared,
         postprocessor: ResultPostprocessor = .shared) {
        self.modelManager = modelManager
        self.preprocessor = preprocessor
        self.postprocessor = postprocessor
    }

    // MARK: - Initialization

    /// Initialize the object detection service and load the model
    /// - Throws: MLModelError if model loading fails
    func initialize() async throws {
        guard detectionModel == nil else {
            logger.debug("Object detection model already loaded")
            return
        }

        detectionModel = try await modelManager.loadModel(named: modelName)
        logger.debug("Object detection model initialized")
    }

    // MARK: - Object Detection

    /// Detect objects in an image
    /// - Parameters:
    ///   - image: UIImage to analyze
    ///   - confidenceThreshold: Minimum confidence score (0-1)
    /// - Returns: Array of ObjectDetection results
    /// - Throws: MLModelError if detection fails
    func detect(in image: UIImage, confidenceThreshold: Float = 0.5) async throws -> [ObjectDetection] {
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
        let detections = try await postprocessor.parseObjectDetectionOutput(output)

        // Filter by confidence
        let filtered = detections.filter { $0.confidence >= confidenceThreshold }

        logger.debug("Detected \(filtered.count) objects")

        return filtered
    }

    /// Detect objects in multiple images
    /// - Parameters:
    ///   - images: Array of UIImage to analyze
    ///   - confidenceThreshold: Minimum confidence score
    /// - Returns: Array of ObjectDetectionResult
    /// - Throws: MLModelError if any detection fails
    func detect(in images: [UIImage], confidenceThreshold: Float = 0.5) async throws -> [ObjectDetectionResult] {
        var results: [ObjectDetectionResult] = []

        for (index, image) in images.enumerated() {
            let detections = try await detect(in: image, confidenceThreshold: confidenceThreshold)
            let result = ObjectDetectionResult(
                imageIndex: index,
                image: image,
                detections: detections,
                timestamp: Date()
            )
            results.append(result)
        }

        return results
    }

    /// Stream object detection from video frames
    /// - Parameters:
    ///   - frameStream: AsyncStream of CVPixelBuffer frames
    ///   - confidenceThreshold: Minimum confidence score
    /// - Returns: AsyncStream of ObjectDetectionFrame results
    func streamDetection(
        from frameStream: AsyncStream<CVPixelBuffer>,
        confidenceThreshold: Float = 0.5
    ) -> AsyncStream<ObjectDetectionFrame> {
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
                        let detections = try await postprocessor.parseObjectDetectionOutput(output)
                        let filtered = detections.filter { $0.confidence >= confidenceThreshold }

                        let frame = ObjectDetectionFrame(
                            pixelBuffer: pixelBuffer,
                            detections: filtered,
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

    /// Detect specific object classes
    /// - Parameters:
    ///   - image: UIImage to analyze
    ///   - objectClasses: Array of class names to detect
    ///   - confidenceThreshold: Minimum confidence score
    /// - Returns: Array of ObjectDetection filtered by class
    /// - Throws: MLModelError if detection fails
    func detect(
        in image: UIImage,
        objectClasses: [String],
        confidenceThreshold: Float = 0.5
    ) async throws -> [ObjectDetection] {
        let allDetections = try await detect(in: image, confidenceThreshold: confidenceThreshold)
        return allDetections.filter { objectClasses.contains($0.className) }
    }

    /// Get detection statistics for an image
    /// - Parameters:
    ///   - image: UIImage to analyze
    ///   - confidenceThreshold: Minimum confidence score
    /// - Returns: DetectionStatistics object
    /// - Throws: MLModelError if detection fails
    func getDetectionStats(
        in image: UIImage,
        confidenceThreshold: Float = 0.5
    ) async throws -> DetectionStatistics {
        let detections = try await detect(in: image, confidenceThreshold: confidenceThreshold)

        let classGroups = Dictionary(grouping: detections) { $0.className }
        let classCounts = classGroups.mapValues { $0.count }

        return DetectionStatistics(
            totalObjectCount: detections.count,
            uniqueClasses: Set(detections.map { $0.className }),
            classCount: classCounts,
            averageConfidence: detections.isEmpty ? 0 : Float(detections.map { Double($0.confidence) }.reduce(0, +)) / Float(detections.count),
            detections: detections
        )
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
        logger.debug("Object detection model unloaded")
    }
}

// MARK: - Result Models

/// Single object detection result with bounding box
struct ObjectDetection: Codable, Sendable {
    let className: String
    let confidence: Float
    let boundingBox: BoundingBox
    let identifier: String?

    enum CodingKeys: String, CodingKey {
        case className = "class"
        case confidence
        case boundingBox = "box"
        case identifier = "id"
    }
}

/// Complete object detection result for an image
struct ObjectDetectionResult: Sendable {
    let imageIndex: Int
    let image: UIImage
    let detections: [ObjectDetection]
    let timestamp: Date

    var objectCount: Int {
        detections.count
    }

    var classNames: Set<String> {
        Set(detections.map { $0.className })
    }
}

/// Real-time object detection frame result
struct ObjectDetectionFrame: Sendable {
    let pixelBuffer: CVPixelBuffer
    let detections: [ObjectDetection]
    let timestamp: Date

    var objectCount: Int {
        detections.count
    }
}

/// Statistics about detected objects
struct DetectionStatistics: Sendable {
    let totalObjectCount: Int
    let uniqueClasses: Set<String>
    let classCount: [String: Int]
    let averageConfidence: Float
    let detections: [ObjectDetection]

    var dominantClass: String? {
        classCount.max { $0.value < $1.value }?.key
    }

    var confidencePercentile: Float {
        averageConfidence * 100
    }
}
