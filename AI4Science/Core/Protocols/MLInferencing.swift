import Foundation
import CoreML

/// Protocol for ML model inference operations
public protocol MLInferencing: Sendable {
    /// Load an ML model
    func loadModel(from url: URL) async throws

    /// Run inference on image data
    func runInference(on imageData: Data, metadata: MLInputMetadata) async throws -> MLInferenceResult

    /// Run batch inference
    func runBatchInference(on imageDataArray: [Data], metadata: [MLInputMetadata]) async throws -> [MLInferenceResult]

    /// Get model information
    func getModelInfo() async -> MLModelInfo

    /// Check if model is loaded
    func isModelLoaded() async -> Bool

    /// Unload model to free memory
    func unloadModel() async throws

    /// Get supported input dimensions
    func getSupportedInputDimensions() async -> [Int]

    /// Get output class names
    func getOutputClasses() async -> [String]
}

/// Input metadata for inference
public struct MLInputMetadata: Sendable {
    public var imageSize: CGSize
    public var colorSpace: ColorSpace
    public var normalizationMethod: NormalizationMethod

    public init(
        imageSize: CGSize,
        colorSpace: ColorSpace = .rgb,
        normalizationMethod: NormalizationMethod = .standard
    ) {
        self.imageSize = imageSize
        self.colorSpace = colorSpace
        self.normalizationMethod = normalizationMethod
    }

    @frozen
    public enum ColorSpace: String, Sendable {
        case rgb
        case bgr
        case grayscale
    }

    @frozen
    public enum NormalizationMethod: String, Sendable {
        case standard
        case imagenet
        case custom
    }
}

/// Result of ML inference
public struct MLInferenceResult: Sendable {
    public var predictions: [String: Double]
    public var confidence: Double
    public var inferenceTimeMillis: Int64
    public var executedOnNeuralEngine: Bool
    public var metadata: [String: String]

    public init(
        predictions: [String: Double],
        confidence: Double,
        inferenceTimeMillis: Int64,
        executedOnNeuralEngine: Bool = false,
        metadata: [String: String] = [:]
    ) {
        self.predictions = predictions
        self.confidence = max(0, min(1, confidence))
        self.inferenceTimeMillis = inferenceTimeMillis
        self.executedOnNeuralEngine = executedOnNeuralEngine
        self.metadata = metadata
    }

    public var topPrediction: (class: String, confidence: Double)? {
        predictions.max { $0.value < $1.value }.map { ($0.key, $0.value) }
    }
}

/// ML model information
public struct MLModelInfo: Sendable {
    public var name: String
    public var version: String
    public var inputShape: [Int]
    public var outputShape: [Int]
    public var outputNames: [String]
    public var modelSize: Int64

    public init(
        name: String,
        version: String,
        inputShape: [Int],
        outputShape: [Int],
        outputNames: [String],
        modelSize: Int64
    ) {
        self.name = name
        self.version = version
        self.inputShape = inputShape
        self.outputShape = outputShape
        self.outputNames = outputNames
        self.modelSize = modelSize
    }
}
