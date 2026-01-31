import Foundation

/// Protocol for machine learning model operations
public protocol MLModelProvider: Sendable {
    /// Download a model for inference
    /// - Parameters:
    ///   - modelId: The model identifier
    ///   - progress: Closure for download progress updates (0.0 to 1.0)
    /// - Returns: The local URL of the downloaded model
    func downloadModel(
        id modelId: UUID,
        progress: @Sendable (Double) -> Void
    ) async throws -> URL

    /// Load a model for inference
    /// - Parameter modelPath: The local path to the model
    func loadModel(from modelPath: URL) async throws

    /// Unload a model from memory
    /// - Parameter modelPath: The local path to the model
    func unloadModel(from modelPath: URL) async throws

    /// Check if a model is currently loaded
    /// - Parameter modelPath: The local path to the model
    /// - Returns: True if model is loaded
    func isModelLoaded(at modelPath: URL) async throws -> Bool

    /// Get list of available models
    /// - Returns: Array of available model information
    func listAvailableModels() async throws -> [MLModel]

    /// Get model information
    /// - Parameter modelId: The model identifier
    /// - Returns: Model metadata
    func getModelInfo(id modelId: UUID) async throws -> MLModel?

    /// Delete a downloaded model
    /// - Parameter modelPath: The local path to the model
    func deleteModel(at modelPath: URL) async throws

    /// Get total size of all downloaded models
    /// - Returns: Size in bytes
    func getTotalDownloadedSize() async throws -> Int64

    /// Verify model integrity
    /// - Parameter modelPath: The local path to the model
    /// - Returns: True if model is valid
    func verifyModel(at modelPath: URL) async throws -> Bool
}

/// Protocol for model inference
public protocol ModelInferenceProvider: Sendable {
    /// Run inference on image data
    /// - Parameters:
    ///   - imageData: The image data to analyze
    ///   - modelId: The model to use
    /// - Returns: Analysis result with predictions
    func inferImage(
        data imageData: Data,
        using modelId: UUID
    ) async throws -> AnalysisResult

    /// Run batch inference
    /// - Parameters:
    ///   - imageDataArray: Array of image data
    ///   - modelId: The model to use
    /// - Returns: Array of analysis results
    func inferImageBatch(
        dataArray: [Data],
        using modelId: UUID
    ) async throws -> [AnalysisResult]

    /// Get inference capabilities for a model
    /// - Parameter modelId: The model identifier
    /// - Returns: Model capabilities
    func getModelCapabilities(id modelId: UUID) async throws -> ModelCapabilities?
}

/// Represents capabilities of an ML model
public struct ModelCapabilities: Sendable, Codable, Hashable {
    public let modelId: UUID
    public let supportsGPU: Bool
    public let supportsNeuralEngine: Bool
    public let maxImageSize: CGSize
    public let minImageSize: CGSize
    public let supportedInputFormats: [String]
    public let outputLabels: [String]

    public init(
        modelId: UUID,
        supportsGPU: Bool,
        supportsNeuralEngine: Bool,
        maxImageSize: CGSize,
        minImageSize: CGSize,
        supportedInputFormats: [String],
        outputLabels: [String]
    ) {
        self.modelId = modelId
        self.supportsGPU = supportsGPU
        self.supportsNeuralEngine = supportsNeuralEngine
        self.maxImageSize = maxImageSize
        self.minImageSize = minImageSize
        self.supportedInputFormats = supportedInputFormats
        self.outputLabels = outputLabels
    }
}
