import Foundation
import CoreML
import Vision
import os.log

/// Service for image classification tasks
/// Classifies images into predefined categories
actor ImageClassificationService {
    private let modelManager: MLModelManager
    private let preprocessor: ImagePreprocessor
    private let postprocessor: ResultPostprocessor
    private let logger = Logger(subsystem: "com.ai4science.ml", category: "ImageClassificationService")

    private var classificationModel: MLModel?
    private let modelName = "ImageClassificationModel"

    init(modelManager: MLModelManager = .shared,
         preprocessor: ImagePreprocessor = .shared,
         postprocessor: ResultPostprocessor = .shared) {
        self.modelManager = modelManager
        self.preprocessor = preprocessor
        self.postprocessor = postprocessor
    }

    // MARK: - Initialization

    /// Initialize the image classification service and load the model
    /// - Throws: MLModelError if model loading fails
    func initialize() async throws {
        guard classificationModel == nil else {
            logger.debug("Classification model already loaded")
            return
        }

        classificationModel = try await modelManager.loadModel(named: modelName)
        logger.debug("Image classification model initialized")
    }

    // MARK: - Classification

    /// Classify a single image
    /// - Parameters:
    ///   - image: UIImage to classify
    ///   - topK: Number of top predictions to return (default 5)
    /// - Returns: Array of Classification results sorted by confidence
    /// - Throws: MLModelError if classification fails
    func classify(image: UIImage, topK: Int = 5) async throws -> [Classification] {
        guard let classificationModel else {
            logger.error("Classification model not initialized")
            throw MLModelError.configurationError("Model not initialized")
        }

        // Preprocess image
        let pixelBuffer = try await preprocessor.prepareImage(image, for: classificationModel)

        // Run inference
        let input = try createModelInput(pixelBuffer: pixelBuffer)
        let output = try classificationModel.prediction(from: input)

        // Postprocess results
        let classifications = try await postprocessor.parseClassificationOutput(output)

        // Sort by confidence and return top K
        let topClassifications = Array(classifications.prefix(topK))

        logger.debug("Classified image with top class: \(topClassifications.first?.label ?? "unknown")")

        return topClassifications
    }

    /// Classify multiple images
    /// - Parameters:
    ///   - images: Array of UIImage to classify
    ///   - topK: Number of top predictions to return per image
    /// - Returns: Array of ImageClassificationResult
    /// - Throws: MLModelError if any classification fails
    func classify(images: [UIImage], topK: Int = 5) async throws -> [ImageClassificationResult] {
        var results: [ImageClassificationResult] = []

        for (index, image) in images.enumerated() {
            let classifications = try await classify(image: image, topK: topK)
            let result = ImageClassificationResult(
                imageIndex: index,
                image: image,
                classifications: classifications,
                timestamp: Date()
            )
            results.append(result)
        }

        return results
    }

    /// Stream classification results from video frames
    /// - Parameters:
    ///   - frameStream: AsyncStream of CVPixelBuffer frames
    ///   - topK: Number of top predictions per frame
    /// - Returns: AsyncStream of ClassificationFrame results
    func streamClassification(
        from frameStream: AsyncStream<CVPixelBuffer>,
        topK: Int = 5
    ) -> AsyncStream<ClassificationFrame> {
        AsyncStream { continuation in
            Task {
                guard let classificationModel else {
                    logger.error("Classification model not initialized")
                    continuation.finish()
                    return
                }

                for await pixelBuffer in frameStream {
                    do {
                        let input = try createModelInput(pixelBuffer: pixelBuffer)
                        let output = try classificationModel.prediction(from: input)
                        let classifications = try await postprocessor.parseClassificationOutput(output)
                        let topClasses = Array(classifications.prefix(topK))

                        let frame = ClassificationFrame(
                            pixelBuffer: pixelBuffer,
                            classifications: topClasses,
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

    /// Get top classification with confidence threshold
    /// - Parameters:
    ///   - image: UIImage to classify
    ///   - confidenceThreshold: Minimum confidence (0-1)
    /// - Returns: Single top Classification or nil if below threshold
    /// - Throws: MLModelError if classification fails
    func getTopClassification(
        image: UIImage,
        confidenceThreshold: Float = 0.5
    ) async throws -> Classification? {
        let classifications = try await classify(image: image, topK: 1)
        guard let topClass = classifications.first,
              topClass.confidence >= confidenceThreshold else {
            logger.debug("Top classification below confidence threshold")
            return nil
        }
        return topClass
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

    /// Unload the classification model
    nonisolated func unload() {
        Task {
            await unloadInternal()
        }
    }

    private func unloadInternal() {
        classificationModel = nil
        logger.debug("Image classification model unloaded")
    }
}

// MARK: - Result Models

/// Single classification result
struct Classification: Codable, Sendable, Comparable {
    let label: String
    let confidence: Float
    let probability: Float?

    static func < (lhs: Classification, rhs: Classification) -> Bool {
        lhs.confidence < rhs.confidence
    }

    static func == (lhs: Classification, rhs: Classification) -> Bool {
        lhs.label == rhs.label && abs(lhs.confidence - rhs.confidence) < 0.001
    }
}

/// Complete classification result for an image
struct ImageClassificationResult: Sendable {
    let imageIndex: Int
    let image: UIImage
    let classifications: [Classification]
    let timestamp: Date

    var topClassification: Classification? {
        classifications.first
    }

    var hasResults: Bool {
        !classifications.isEmpty
    }
}

/// Real-time classification frame result
struct ClassificationFrame: Sendable {
    let pixelBuffer: CVPixelBuffer
    let classifications: [Classification]
    let timestamp: Date

    var topClassification: Classification? {
        classifications.first
    }
}
