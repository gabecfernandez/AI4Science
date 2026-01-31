import Foundation

/// Protocol defining the contract for inference results
public protocol InferenceResultProtocol: Sendable {
    /// Unique identifier for this inference result
    var resultId: UUID { get }

    /// Timestamp when inference was completed
    var timestamp: Date { get }

    /// Time taken to perform inference in milliseconds
    var inferenceTimeMs: Double { get }

    /// Model identifier that produced this result
    var modelIdentifier: String { get }

    /// Input image size that was used
    var inputImageSize: CGSize { get }

    /// Overall confidence score (0.0 to 1.0)
    var confidence: Float { get }

    /// Whether the inference was successful
    var isValid: Bool { get }

    /// Detailed error message if inference failed
    var errorMessage: String? { get }
}

/// Concrete implementation of InferenceResultProtocol
public struct BaseInferenceResult: InferenceResultProtocol, Sendable {
    public let resultId: UUID
    public let timestamp: Date
    public let inferenceTimeMs: Double
    public let modelIdentifier: String
    public let inputImageSize: CGSize
    public let confidence: Float
    public let isValid: Bool
    public let errorMessage: String?

    public init(
        resultId: UUID = UUID(),
        timestamp: Date = Date(),
        inferenceTimeMs: Double,
        modelIdentifier: String,
        inputImageSize: CGSize,
        confidence: Float,
        isValid: Bool = true,
        errorMessage: String? = nil
    ) {
        self.resultId = resultId
        self.timestamp = timestamp
        self.inferenceTimeMs = inferenceTimeMs
        self.modelIdentifier = modelIdentifier
        self.inputImageSize = inputImageSize
        self.confidence = confidence
        self.isValid = isValid
        self.errorMessage = errorMessage
    }
}
