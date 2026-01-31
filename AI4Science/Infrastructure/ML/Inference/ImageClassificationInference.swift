import Foundation
import CoreML
import Vision
import os.log

/// Image classification result
public struct ClassificationResult: InferenceResultProtocol, Sendable {
    public let resultId: UUID
    public let timestamp: Date
    public let inferenceTimeMs: Double
    public let modelIdentifier: String
    public let inputImageSize: CGSize
    public let confidence: Float
    public let isValid: Bool
    public let errorMessage: String?

    public let classLabel: String
    public let classIndex: Int
    public let scores: [String: Float]

    public init(
        classLabel: String,
        classIndex: Int,
        scores: [String: Float],
        confidence: Float,
        inferenceTimeMs: Double,
        modelIdentifier: String,
        inputImageSize: CGSize,
        isValid: Bool = true,
        errorMessage: String? = nil
    ) {
        self.resultId = UUID()
        self.timestamp = Date()
        self.classLabel = classLabel
        self.classIndex = classIndex
        self.scores = scores
        self.inferenceTimeMs = inferenceTimeMs
        self.modelIdentifier = modelIdentifier
        self.inputImageSize = inputImageSize
        self.confidence = confidence
        self.isValid = isValid
        self.errorMessage = errorMessage
    }
}

/// Defect type enumeration
public enum InferenceDefectType: String, Sendable, Codable {
    case noDefect = "no_defect"
    case scratch = "scratch"
    case crack = "crack"
    case dent = "dent"
    case discoloration = "discoloration"
    case foreign = "foreign_object"
    case unknown = "unknown"

    public init?(from label: String) {
        let normalized = label.lowercased().trimmingCharacters(in: .whitespaces)
        self = InferenceDefectType(rawValue: normalized) ?? .unknown
    }
}

/// Image classification inference actor
public actor ImageClassificationInference {
    private let logger = Logger(subsystem: "com.ai4science.ml", category: "ImageClassificationInference")

    /// Inference engine
    private let inferenceEngine: InferenceEngine

    /// Image preprocessor
    private let preprocessor: ImagePreprocessor

    /// Confidence threshold
    private let confidenceThreshold: Float

    /// Class labels mapping
    private let classLabels: [Int: String]

    public init(
        inferenceEngine: InferenceEngine,
        preprocessor: ImagePreprocessor,
        confidenceThreshold: Float = 0.5,
        classLabels: [Int: String] = [
            0: "no_defect",
            1: "scratch",
            2: "crack",
            3: "dent",
            4: "discoloration",
            5: "foreign_object"
        ]
    ) {
        self.inferenceEngine = inferenceEngine
        self.preprocessor = preprocessor
        self.confidenceThreshold = confidenceThreshold
        self.classLabels = classLabels

        logger.info("ImageClassificationInference initialized")
    }

    /// Classify defects in an image
    public func classifyImage(_ image: UIImage) async throws -> ClassificationResult {
        let startTime = Date()

        do {
            // Preprocess image
            let featureProvider = try await preprocessor.preprocess(image)

            // Run inference
            let outputProvider = try await inferenceEngine.predict(featureProvider: featureProvider)

            // Get image size for metrics
            let imageSize = image.size

            // Process output
            let result = try processOutput(
                outputProvider: outputProvider,
                imageSize: imageSize,
                startTime: startTime
            )

            logger.info(
                "Classification completed: \(result.classLabel) (confidence: \(String(format: "%.2f", result.confidence)))"
            )

            return result
        } catch {
            logger.error("Classification failed: \(error.localizedDescription)")
            return createErrorResult(
                image: image,
                error: error,
                startTime: startTime
            )
        }
    }

    /// Classify multiple images
    public func classifyImages(_ images: [UIImage]) async throws -> [ClassificationResult] {
        var results: [ClassificationResult] = []

        for image in images {
            let result = try await classifyImage(image)
            results.append(result)
        }

        return results
    }

    /// Classify image from pixel buffer
    public func classifyPixelBuffer(_ pixelBuffer: CVPixelBuffer) async throws -> ClassificationResult {
        let startTime = Date()

        do {
            // Preprocess from pixel buffer
            let featureProvider = try await preprocessor.preprocessPixelBuffer(pixelBuffer)

            // Run inference
            let outputProvider = try await inferenceEngine.predict(featureProvider: featureProvider)

            // Get dimensions
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let imageSize = CGSize(width: width, height: height)

            // Process output
            let result = try processOutput(
                outputProvider: outputProvider,
                imageSize: imageSize,
                startTime: startTime
            )

            return result
        } catch {
            logger.error("Classification from pixel buffer failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Private Methods

    private func processOutput(
        outputProvider: MLFeatureProvider,
        imageSize: CGSize,
        startTime: Date
    ) throws -> ClassificationResult {
        let endTime = Date()
        let inferenceTimeMs = endTime.timeIntervalSince(startTime) * 1000

        // Try to get class predictions from output
        var scores: [String: Float] = [:]
        var maxScore: Float = 0
        var maxIndex: Int = 0

        // Extract scores from output features
        if let classifierOutput = outputProvider.featureDictionary["classifierOutput"] {
            // Handle different output formats
            if let multiArrayValue = classifierOutput.multiArrayValue {
                let flattenedValues = flatten(multiArray: multiArrayValue)

                for (index, value) in flattenedValues.enumerated() {
                    if let label = classLabels[index] {
                        scores[label] = Float(truncating: value)

                        if value.floatValue > maxScore {
                            maxScore = value.floatValue
                            maxIndex = index
                        }
                    }
                }
            }
        }

        let classLabel = classLabels[maxIndex] ?? "unknown"
        let confidence = max(0, min(1, maxScore))

        return ClassificationResult(
            classLabel: classLabel,
            classIndex: maxIndex,
            scores: scores,
            confidence: confidence,
            inferenceTimeMs: inferenceTimeMs,
            modelIdentifier: inferenceEngine.modelId,
            inputImageSize: imageSize,
            isValid: confidence >= confidenceThreshold
        )
    }

    private func flatten(multiArray: MLMultiArray) -> [NSNumber] {
        var result: [NSNumber] = []

        for i in 0..<multiArray.count {
            result.append(multiArray[i])
        }

        return result
    }

    private func createErrorResult(
        image: UIImage,
        error: Error,
        startTime: Date
    ) -> ClassificationResult {
        let inferenceTimeMs = Date().timeIntervalSince(startTime) * 1000

        return ClassificationResult(
            classLabel: "unknown",
            classIndex: -1,
            scores: [:],
            confidence: 0,
            inferenceTimeMs: inferenceTimeMs,
            modelIdentifier: inferenceEngine.modelId,
            inputImageSize: image.size,
            isValid: false,
            errorMessage: error.localizedDescription
        )
    }
}
