import Foundation

/// Standardized prediction result type for ML models
/// Provides unified interface for different model outputs
struct PredictionResult: Sendable, Codable {
    /// Unique identifier for this prediction
    let id: UUID

    /// Type of prediction
    let type: PredictionType

    /// Input that generated this prediction
    let inputMetadata: InputMetadata

    /// Prediction output
    let output: PredictionOutput

    /// Model information
    let modelInfo: PredictionModelInfo

    /// Confidence/score information
    let confidence: ConfidenceInfo

    /// Timestamp of prediction
    let timestamp: Date

    /// Processing time in milliseconds
    let inferenceTime: Int

    /// Optional metadata about the prediction
    let metadata: [String: String]?

    // MARK: - Initialization

    init(
        type: PredictionType,
        inputMetadata: InputMetadata,
        output: PredictionOutput,
        modelInfo: PredictionModelInfo,
        confidence: ConfidenceInfo,
        inferenceTime: Int,
        metadata: [String: String]? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.inputMetadata = inputMetadata
        self.output = output
        self.modelInfo = modelInfo
        self.confidence = confidence
        self.timestamp = Date()
        self.inferenceTime = inferenceTime
        self.metadata = metadata
    }

    // MARK: - Computed Properties

    var isHighConfidence: Bool {
        confidence.average >= 0.7
    }

    var isMediumConfidence: Bool {
        confidence.average >= 0.5 && confidence.average < 0.7
    }

    var isLowConfidence: Bool {
        confidence.average < 0.5
    }
}

/// Type of prediction produced
enum PredictionType: String, Sendable, Codable {
    case classification
    case objectDetection
    case defectDetection
    case semanticSegmentation
    case poseEstimation
    case depthEstimation
    case custom
}

/// Metadata about the input to the prediction
struct InputMetadata: Sendable, Codable {
    /// Size of input image
    let imageSize: CGSize

    /// Format of input
    let format: InputFormat

    /// Optional image identifier
    let imageId: String?

    /// Source of the input
    let source: InputSource

    enum InputFormat: String, Codable {
        case pixelBuffer = "CVPixelBuffer"
        case cgImage = "CGImage"
        case uiImage = "UIImage"
        case videoFrame = "VideoFrame"
    }

    enum InputSource: String, Codable {
        case camera
        case photoLibrary
        case file
        case videoStream
    }
}

/// Output of the prediction
enum PredictionOutput: Sendable, Codable {
    case classification([ClassificationOutput])
    case detection([DetectionOutput])
    case segmentation(SegmentationOutput)
    case multiple([String: PredictionValue])

    enum CodingKeys: String, CodingKey {
        case classification = "classification"
        case detection = "detection"
        case segmentation = "segmentation"
        case multiple = "multiple"
    }
}

/// Classification output
struct ClassificationOutput: Sendable, Codable {
    let label: String
    let confidence: Float
    let index: Int?
}

/// Object detection output
struct DetectionOutput: Sendable, Codable {
    let className: String
    let confidence: Float
    let boundingBox: BoundingBoxOutput
    let index: Int?

    struct BoundingBoxOutput: Sendable, Codable {
        let x: Float
        let y: Float
        let width: Float
        let height: Float
    }
}

/// Semantic segmentation output
struct SegmentationOutput: Sendable, Codable {
    let classMap: [[Int]]
    let classNames: [String]
    let confidence: [[Float]]?
}

/// Generic prediction value
enum PredictionValue: Sendable, Codable {
    case float(Float)
    case string(String)
    case array([Float])
    case object([String: PredictionValue])
}

/// Model information for prediction results
struct PredictionModelInfo: Sendable, Codable {
    /// Name of the model
    let name: String

    /// Unique model identifier
    let identifier: String

    /// Model version
    let version: String

    /// Framework used
    let framework: String = "CoreML"
}

/// Confidence/score information
struct ConfidenceInfo: Sendable, Codable {
    /// Average confidence across all predictions
    let average: Float

    /// Maximum confidence value
    let maximum: Float

    /// Minimum confidence value
    let minimum: Float

    /// Standard deviation of confidence values
    let standardDeviation: Float

    /// Raw confidence scores
    let scores: [Float]

    // MARK: - Initialization

    init(scores: [Float]) {
        self.scores = scores

        if scores.isEmpty {
            self.average = 0
            self.maximum = 0
            self.minimum = 0
            self.standardDeviation = 0
        } else {
            self.average = scores.reduce(0, +) / Float(scores.count)
            self.maximum = scores.max() ?? 0
            self.minimum = scores.min() ?? 0

            let variance = scores.map { pow($0 - average, 2) }.reduce(0, +) / Float(scores.count)
            self.standardDeviation = sqrt(variance)
        }
    }
}

/// Collection of multiple prediction results
struct BatchPredictionResults: Sendable {
    let predictions: [PredictionResult]
    let processingTime: Int
    let successCount: Int
    let failureCount: Int
    let averageInferenceTime: Int

    var successRate: Float {
        guard !predictions.isEmpty else { return 0 }
        return Float(successCount) / Float(predictions.count)
    }
}

/// Builder for constructing prediction results
struct PredictionResultBuilder {
    private var type: PredictionType = .custom
    private var inputMetadata: InputMetadata?
    private var output: PredictionOutput?
    private var modelInfo: PredictionModelInfo?
    private var confidence: ConfidenceInfo?
    private var inferenceTime: Int = 0
    private var metadata: [String: String]?

    mutating func setType(_ type: PredictionType) -> Self {
        self.type = type
        return self
    }

    mutating func setInput(_ metadata: InputMetadata) -> Self {
        self.inputMetadata = metadata
        return self
    }

    mutating func setOutput(_ output: PredictionOutput) -> Self {
        self.output = output
        return self
    }

    mutating func setModel(_ info: PredictionModelInfo) -> Self {
        self.modelInfo = info
        return self
    }

    mutating func setConfidence(_ confidence: ConfidenceInfo) -> Self {
        self.confidence = confidence
        return self
    }

    mutating func setInferenceTime(_ time: Int) -> Self {
        self.inferenceTime = time
        return self
    }

    mutating func setMetadata(_ data: [String: String]) -> Self {
        self.metadata = data
        return self
    }

    func build() throws -> PredictionResult {
        guard let inputMetadata = inputMetadata else {
            throw PredictionError.missingInputMetadata
        }
        guard let output = output else {
            throw PredictionError.missingOutput
        }
        guard let modelInfo = modelInfo else {
            throw PredictionError.missingModelInfo
        }
        guard let confidence = confidence else {
            throw PredictionError.missingConfidence
        }

        return PredictionResult(
            type: type,
            inputMetadata: inputMetadata,
            output: output,
            modelInfo: modelInfo,
            confidence: confidence,
            inferenceTime: inferenceTime,
            metadata: metadata
        )
    }
}

/// Errors for prediction operations
enum PredictionError: LocalizedError {
    case missingInputMetadata
    case missingOutput
    case missingModelInfo
    case missingConfidence
    case invalidPredictionType
    case serializationFailed

    var errorDescription: String? {
        switch self {
        case .missingInputMetadata:
            return "Input metadata is required"
        case .missingOutput:
            return "Prediction output is required"
        case .missingModelInfo:
            return "Model information is required"
        case .missingConfidence:
            return "Confidence information is required"
        case .invalidPredictionType:
            return "Invalid prediction type"
        case .serializationFailed:
            return "Failed to serialize prediction result"
        }
    }
}
