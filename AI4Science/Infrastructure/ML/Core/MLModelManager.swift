import Foundation
import CoreML
import os.log

/// Error types for ML model management
public enum MLModelManagerError: LocalizedError {
    case modelNotFound(String)
    case modelAlreadyLoaded(String)
    case modelNotLoaded(String)
    case loadingFailed(String, Error)
    case unloadingFailed(String, Error)
    case insufficientMemory
    case invalidModel(String)

    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let id):
            return "Model not found: \(id)"
        case .modelAlreadyLoaded(let id):
            return "Model already loaded: \(id)"
        case .modelNotLoaded(let id):
            return "Model not loaded: \(id)"
        case .loadingFailed(let id, let error):
            return "Failed to load model \(id): \(error.localizedDescription)"
        case .unloadingFailed(let id, let error):
            return "Failed to unload model \(id): \(error.localizedDescription)"
        case .insufficientMemory:
            return "Insufficient memory to load model"
        case .invalidModel(let id):
            return "Invalid model: \(id)"
        }
    }
}

/// Actor managing the lifecycle of ML models
public actor MLModelManager {
    private let logger = Logger(subsystem: "com.ai4science.ml", category: "MLModelManager")

    /// Loaded models cache: [modelId: MLModel]
    private var loadedModels: [String: MLModel] = [:]

    /// Model metadata: [modelId: metadata]
    private var modelMetadata: [String: ModelMetadata] = [:]

    /// Current memory usage in bytes
    private var currentMemoryUsageBytes: UInt64 = 0

    /// Maximum memory available for models (device-dependent)
    private let maxMemoryBytes: UInt64

    /// Model loading queue for serialized access
    private let modelLoadingQueue = DispatchQueue(
        label: "com.ai4science.ml.modelLoading",
        qos: .userInitiated
    )

    /// Metadata about a loaded model
    private struct ModelMetadata: Sendable {
        let modelId: String
        let modelPath: String
        let modelSizeBytes: UInt64
        let loadedAt: Date
        let config: MLModelConfiguration
    }

    /// Initialize the manager
    public init(maxMemoryMB: UInt64 = 500) {
        self.maxMemoryBytes = maxMemoryMB * 1024 * 1024
        logger.info("MLModelManager initialized with max memory: \(maxMemoryMB)MB")
    }

    /// Register model metadata
    public func registerModel(
        id: String,
        modelPath: String,
        sizeBytes: UInt64
    ) {
        logger.debug("Registering model: \(id)")
    }

    /// Load a model from file path
    public func loadModel(
        modelId: String,
        modelPath: String,
        sizeBytes: UInt64,
        configuration: MLModelConfiguration = .init()
    ) async throws -> MLModel {
        // Check if already loaded
        if let cachedModel = loadedModels[modelId] {
            logger.debug("Model already loaded in memory: \(modelId)")
            return cachedModel
        }

        // Check memory availability
        guard currentMemoryUsageBytes + sizeBytes <= maxMemoryBytes else {
            logger.error("Insufficient memory to load model: \(modelId)")
            throw MLModelManagerError.insufficientMemory
        }

        // Load model on dedicated queue
        let model = try await withCheckedThrowingContinuation { continuation in
            modelLoadingQueue.async { [weak self] in
                do {
                    let loadedModel = try MLModel(contentsOf: URL(fileURLWithPath: modelPath), configuration: configuration)
                    continuation.resume(returning: loadedModel)
                } catch {
                    continuation.resume(throwing: MLModelManagerError.loadingFailed(modelId, error))
                }
            }
        }

        // Cache model and metadata
        loadedModels[modelId] = model
        modelMetadata[modelId] = ModelMetadata(
            modelId: modelId,
            modelPath: modelPath,
            modelSizeBytes: sizeBytes,
            loadedAt: Date(),
            config: configuration
        )
        currentMemoryUsageBytes += sizeBytes

        logger.info("Model loaded successfully: \(modelId), Memory: \(self.currentMemoryUsageBytes / (1024 * 1024))MB")
        return model
    }

    /// Unload a model from memory
    public func unloadModel(modelId: String) throws {
        guard let model = loadedModels[modelId] else {
            throw MLModelManagerError.modelNotLoaded(modelId)
        }

        if let metadata = modelMetadata[modelId] {
            currentMemoryUsageBytes -= metadata.modelSizeBytes
        }

        loadedModels.removeValue(forKey: modelId)
        modelMetadata.removeValue(forKey: modelId)

        logger.info("Model unloaded: \(modelId), Memory: \(self.currentMemoryUsageBytes / (1024 * 1024))MB")
    }

    /// Get a loaded model
    public func getModel(modelId: String) throws -> MLModel {
        guard let model = loadedModels[modelId] else {
            throw MLModelManagerError.modelNotLoaded(modelId)
        }
        return model
    }

    /// Check if model is loaded
    public func isModelLoaded(modelId: String) -> Bool {
        loadedModels[modelId] != nil
    }

    /// Get list of loaded model IDs
    public func getLoadedModelIds() -> [String] {
        Array(loadedModels.keys)
    }

    /// Get current memory usage
    public func getMemoryUsageMB() -> UInt64 {
        currentMemoryUsageBytes / (1024 * 1024)
    }

    /// Get available memory for models
    public func getAvailableMemoryMB() -> UInt64 {
        let availableBytes = maxMemoryBytes > currentMemoryUsageBytes ? maxMemoryBytes - currentMemoryUsageBytes : 0
        return availableBytes / (1024 * 1024)
    }

    /// Unload all models
    public func unloadAllModels() {
        loadedModels.removeAll()
        modelMetadata.removeAll()
        currentMemoryUsageBytes = 0
        logger.info("All models unloaded")
    }

    /// Get model metadata
    public func getModelMetadata(modelId: String) -> (sizeBytes: UInt64, loadedAt: Date)? {
        guard let metadata = modelMetadata[modelId] else { return nil }
        return (metadata.modelSizeBytes, metadata.loadedAt)
    }
}
