import Foundation

public struct LoadMLModelUseCase: Sendable {
    private let mlRepository: any MLRepositoryProtocol

    public init(mlRepository: any MLRepositoryProtocol) {
        self.mlRepository = mlRepository
    }

    /// Loads an ML model into memory
    /// - Parameter modelId: Model identifier
    /// - Returns: LoadedMLModel with metadata
    /// - Throws: MLError if loading fails
    public func execute(modelId: String) async throws -> LoadedMLModel {
        guard !modelId.isEmpty else {
            throw MLError.validationFailed("Model ID is required.")
        }

        let model = try await mlRepository.loadModel(modelId: modelId)
        return model
    }

    /// Preloads multiple models for faster access
    /// - Parameter modelIds: Array of model identifiers
    /// - Returns: PreloadResult with success and failure counts
    /// - Throws: MLError if operation fails
    public func preloadModels(modelIds: [String]) async throws -> PreloadResult {
        guard !modelIds.isEmpty else {
            throw MLError.validationFailed("At least one model ID is required.")
        }

        var successCount = 0
        var failedIds: [String] = []

        for modelId in modelIds {
            do {
                _ = try await execute(modelId: modelId)
                successCount += 1
            } catch {
                failedIds.append(modelId)
            }
        }

        return PreloadResult(
            successCount: successCount,
            failureCount: failedIds.count,
            failedModelIds: failedIds
        )
    }

    /// Unloads a model from memory
    /// - Parameter modelId: Model identifier
    /// - Throws: MLError if unloading fails
    public func unload(modelId: String) async throws {
        guard !modelId.isEmpty else {
            throw MLError.validationFailed("Model ID is required.")
        }

        try await mlRepository.unloadModel(modelId: modelId)
    }

    /// Gets information about a loaded model
    /// - Parameter modelId: Model identifier
    /// - Returns: ModelInfo with specifications
    /// - Throws: MLError if fetch fails
    public func getModelInfo(modelId: String) async throws -> ModelInfo {
        guard !modelId.isEmpty else {
            throw MLError.validationFailed("Model ID is required.")
        }

        return try await mlRepository.getModelInfo(modelId: modelId)
    }
}

// MARK: - Supporting Types

public struct LoadedMLModel: Sendable {
    public let id: String
    public let name: String
    public let version: String
    public let type: ModelType
    public let sizeInBytes: Int
    public let inputShape: [Int]
    public let outputShape: [Int]
    public let isLoaded: Bool
    public let loadedAt: Date?

    public init(
        id: String,
        name: String,
        version: String,
        type: ModelType,
        sizeInBytes: Int,
        inputShape: [Int],
        outputShape: [Int],
        isLoaded: Bool,
        loadedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.type = type
        self.sizeInBytes = sizeInBytes
        self.inputShape = inputShape
        self.outputShape = outputShape
        self.isLoaded = isLoaded
        self.loadedAt = loadedAt
    }
}

public struct ModelInfo: Sendable, Codable {
    public let id: String
    public let name: String
    public let description: String
    public let version: String
    public let type: ModelType
    public let sizeInBytes: Int
    public let accuracy: Float
    public let inferenceTime: Double // milliseconds
    public let supportedFormats: [String]
    public let inputShape: [Int]
    public let outputShape: [Int]
    public let requiredMemory: Int // bytes
    public let compatibility: [String]

    public init(
        id: String,
        name: String,
        description: String,
        version: String,
        type: ModelType,
        sizeInBytes: Int,
        accuracy: Float,
        inferenceTime: Double,
        supportedFormats: [String],
        inputShape: [Int],
        outputShape: [Int],
        requiredMemory: Int,
        compatibility: [String]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.version = version
        self.type = type
        self.sizeInBytes = sizeInBytes
        self.accuracy = accuracy
        self.inferenceTime = inferenceTime
        self.supportedFormats = supportedFormats
        self.inputShape = inputShape
        self.outputShape = outputShape
        self.requiredMemory = requiredMemory
        self.compatibility = compatibility
    }
}

public enum ModelType: Sendable, Codable, Equatable {
    case objectDetection
    case imageClassification
    case segmentation
    case customModel(String)

    public var displayName: String {
        switch self {
        case .objectDetection:
            return "Object Detection"
        case .imageClassification:
            return "Image Classification"
        case .segmentation:
            return "Segmentation"
        case .customModel(let name):
            return name
        }
    }
}

public struct PreloadResult: Sendable {
    public let successCount: Int
    public let failureCount: Int
    public let failedModelIds: [String]

    public var isSuccessful: Bool {
        failureCount == 0
    }

    public init(
        successCount: Int,
        failureCount: Int,
        failedModelIds: [String]
    ) {
        self.successCount = successCount
        self.failureCount = failureCount
        self.failedModelIds = failedModelIds
    }
}

public enum MLError: LocalizedError, Sendable {
    case validationFailed(String)
    case modelNotFound
    case modelNotLoaded
    case insufficientMemory
    case incompatibleDevice
    case corruptedModel
    case networkError
    case serverError(message: String)

    public var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return message
        case .modelNotFound:
            return "Model not found."
        case .modelNotLoaded:
            return "Model is not loaded."
        case .insufficientMemory:
            return "Insufficient device memory to load model."
        case .incompatibleDevice:
            return "Device is not compatible with this model."
        case .corruptedModel:
            return "Model file is corrupted."
        case .networkError:
            return "Network connection failed."
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - Repository Protocol

public protocol MLRepositoryProtocol: Sendable {
    func loadModel(modelId: String) async throws -> LoadedMLModel
    func unloadModel(modelId: String) async throws
    func getModelInfo(modelId: String) async throws -> ModelInfo
    func downloadModel(modelId: String) async throws -> ModelDownloadProgress
    func listAvailableModels() async throws -> [ModelInfo]
    func checkModelUpdates(modelId: String) async throws -> ModelUpdateInfo?
}
