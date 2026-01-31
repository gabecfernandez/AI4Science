import Foundation
import CoreML
import os.log

/// Actor for thread-safe management of CoreML model lifecycle
/// Handles loading, caching, and unloading of ML models
actor MLModelManager {
    static let shared = MLModelManager()

    private let logger = Logger(subsystem: "com.ai4science.ml", category: "MLModelManager")
    private var modelCache: [String: MLModel] = [:]
    private let maxCacheSize = 500 * 1024 * 1024 // 500 MB
    private var currentCacheSize = 0

    private init() {
        logger.debug("MLModelManager initialized")
    }

    // MARK: - Model Loading

    /// Load a CoreML model by name, using cache if available
    /// - Parameter modelName: Name of the model file (without .mlmodelc extension)
    /// - Returns: Loaded MLModel
    /// - Throws: MLModelError if loading fails
    func loadModel(named modelName: String) async throws -> MLModel {
        // Check cache first
        if let cachedModel = modelCache[modelName] {
            logger.debug("Using cached model: \(modelName)")
            return cachedModel
        }

        // Load from bundle
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            logger.error("Model not found in bundle: \(modelName)")
            throw MLModelError.modelNotFound(modelName)
        }

        let compiledModelURL: URL
        if modelURL.pathExtension == "mlmodelc" {
            compiledModelURL = modelURL
        } else {
            // Compile model if needed
            compiledModelURL = try MLModel.compileModel(at: modelURL)
        }

        let model = try MLModel.load(contentsOf: compiledModelURL)
        logger.debug("Loaded model: \(modelName)")

        // Cache the model
        try await cacheModel(model, forKey: modelName)

        return model
    }

    /// Load multiple models concurrently
    /// - Parameter modelNames: Array of model names to load
    /// - Returns: Dictionary mapping model names to loaded models
    /// - Throws: MLModelError if any model fails to load
    func loadModels(named modelNames: [String]) async throws -> [String: MLModel] {
        var results: [String: MLModel] = [:]

        for modelName in modelNames {
            let model = try await loadModel(named: modelName)
            results[modelName] = model
        }

        return results
    }

    // MARK: - Model Caching

    /// Cache a loaded model in memory
    /// - Parameters:
    ///   - model: The MLModel to cache
    ///   - key: Cache key for retrieval
    private func cacheModel(_ model: MLModel, forKey key: String) async throws {
        // Check if model already cached
        guard modelCache[key] == nil else {
            return
        }

        modelCache[key] = model
        logger.debug("Cached model with key: \(key)")

        // Implement cache eviction if needed
        if currentCacheSize > maxCacheSize {
            await evictLRUModel()
        }
    }

    /// Retrieve a cached model
    /// - Parameter key: Cache key
    /// - Returns: Cached MLModel or nil
    func getCachedModel(key: String) -> MLModel? {
        return modelCache[key]
    }

    /// Clear all cached models
    nonisolated func clearCache() {
        Task {
            await clearCacheInternal()
        }
    }

    private func clearCacheInternal() {
        modelCache.removeAll()
        currentCacheSize = 0
        logger.debug("Cache cleared")
    }

    /// Evict least recently used model from cache
    private func evictLRUModel() {
        guard !modelCache.isEmpty else { return }

        if let keyToRemove = modelCache.keys.first {
            modelCache.removeValue(forKey: keyToRemove)
            logger.debug("Evicted model from cache: \(keyToRemove)")
        }
    }

    // MARK: - Cache Information

    /// Get cache statistics
    /// - Returns: Dictionary with cache information
    func getCacheStats() -> [String: Any] {
        return [
            "cachedModels": modelCache.count,
            "currentSize": currentCacheSize,
            "maxSize": maxCacheSize,
            "modelNames": Array(modelCache.keys)
        ]
    }

    // MARK: - Model Configuration

    /// Get the optimal compute unit for model inference
    /// - Returns: MLComputeUnit based on device capabilities
    nonisolated func getOptimalComputeUnit() -> MLComputeUnit {
        #if targetEnvironment(simulator)
        return .cpuOnly
        #else
        return .all // Use Neural Engine if available
        #endif
    }

    /// Configure model inference options
    /// - Parameter computeUnit: Desired compute unit
    /// - Returns: MLModelConfiguration with optimized settings
    nonisolated func configureModel(computeUnit: MLComputeUnit = .all) -> MLModelConfiguration {
        let config = MLModelConfiguration()
        config.computeUnits = computeUnit

        #if os(iOS)
        if #available(iOS 14.0, *) {
            config.allowLowPrecisionAccumulationOnGPU = true
        }
        #endif

        return config
    }
}

// MARK: - Error Handling

enum MLModelError: LocalizedError {
    case modelNotFound(String)
    case loadingFailed(String)
    case compilationFailed(String)
    case configurationError(String)
    case inferenceError(String)
    case invalidInput
    case outputParsingError(String)

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let name):
            return "ML model not found: \(name)"
        case .loadingFailed(let reason):
            return "Failed to load ML model: \(reason)"
        case .compilationFailed(let reason):
            return "Failed to compile ML model: \(reason)"
        case .configurationError(let reason):
            return "Model configuration error: \(reason)"
        case .inferenceError(let reason):
            return "Inference failed: \(reason)"
        case .invalidInput:
            return "Invalid input provided to model"
        case .outputParsingError(let reason):
            return "Failed to parse model output: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .modelNotFound:
            return "Ensure the model file is included in the app bundle"
        case .loadingFailed:
            return "Check model compatibility with current iOS version"
        case .compilationFailed:
            return "Verify the model format is valid CoreML (.mlmodelc)"
        case .configurationError:
            return "Review MLModelConfiguration settings"
        case .inferenceError:
            return "Verify input dimensions and format match model requirements"
        case .invalidInput:
            return "Check input array dimensions and data types"
        case .outputParsingError:
            return "Ensure output parsing matches model architecture"
        }
    }
}
