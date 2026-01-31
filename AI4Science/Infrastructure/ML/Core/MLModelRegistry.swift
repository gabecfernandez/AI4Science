import Foundation
import os.log

/// Model information
public struct ModelInfo: Sendable, Codable {
    public let id: String
    public let name: String
    public let version: String
    public let type: ModelType
    public let sizeBytes: UInt64
    public let localPath: String?
    public let remoteUrl: URL?
    public let checksumSHA256: String?
    public let minimumIOSVersion: String
    public let isRequired: Bool
    public let isAutoDownload: Bool

    public init(
        id: String,
        name: String,
        version: String,
        type: ModelType,
        sizeBytes: UInt64,
        localPath: String? = nil,
        remoteUrl: URL? = nil,
        checksumSHA256: String? = nil,
        minimumIOSVersion: String = "17.0",
        isRequired: Bool = false,
        isAutoDownload: Bool = true
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.type = type
        self.sizeBytes = sizeBytes
        self.localPath = localPath
        self.remoteUrl = remoteUrl
        self.checksumSHA256 = checksumSHA256
        self.minimumIOSVersion = minimumIOSVersion
        self.isRequired = isRequired
        self.isAutoDownload = isAutoDownload
    }
}

/// Model type enumeration
public enum ModelType: String, Sendable, Codable {
    case classification = "classification"
    case objectDetection = "object_detection"
    case segmentation = "segmentation"
    case anomalyDetection = "anomaly_detection"
    case qualityScoring = "quality_scoring"
    case custom = "custom"
}

/// Model registry for managing available models
public actor MLModelRegistry {
    private let logger = Logger(subsystem: "com.ai4science.ml", category: "MLModelRegistry")

    /// Registered models: [modelId: ModelInfo]
    private var models: [String: ModelInfo] = [:]

    /// Model discovery enabled
    private var discoveryEnabled: Bool = true

    public init() {
        logger.info("MLModelRegistry initialized")
    }

    /// Register a model
    public func registerModel(_ modelInfo: ModelInfo) throws {
        guard discoveryEnabled else {
            throw RegistryError.registryLocked
        }

        models[modelInfo.id] = modelInfo
        logger.debug("Model registered: \(modelInfo.id) - \(modelInfo.name)")
    }

    /// Register multiple models
    public func registerModels(_ modelInfos: [ModelInfo]) throws {
        for modelInfo in modelInfos {
            try registerModel(modelInfo)
        }
    }

    /// Get model info by ID
    public func getModel(id: String) -> ModelInfo? {
        models[id]
    }

    /// Get all models
    public func getAllModels() -> [ModelInfo] {
        Array(models.values)
    }

    /// Get models by type
    public func getModelsByType(_ type: ModelType) -> [ModelInfo] {
        models.values.filter { $0.type == type }
    }

    /// Get required models
    public func getRequiredModels() -> [ModelInfo] {
        models.values.filter { $0.isRequired }
    }

    /// Get models that should be auto-downloaded
    public func getAutoDownloadModels() -> [ModelInfo] {
        models.values.filter { $0.isAutoDownload }
    }

    /// Unregister a model
    public func unregisterModel(id: String) -> ModelInfo? {
        models.removeValue(forKey: id)
    }

    /// Check if model exists
    public func modelExists(id: String) -> Bool {
        models[id] != nil
    }

    /// Get model count
    public func getModelCount() -> Int {
        models.count
    }

    /// Get models with local paths
    public func getAvailableOfflineModels() -> [ModelInfo] {
        models.values.filter { $0.localPath != nil }
    }

    /// Enable/disable discovery
    public func setDiscoveryEnabled(_ enabled: Bool) {
        discoveryEnabled = enabled
        logger.info("Model discovery \(enabled ? "enabled" : "disabled")")
    }

    /// Clear all models
    public func clearRegistry() {
        models.removeAll()
        logger.info("Model registry cleared")
    }

    /// Load registry from JSON file
    public func loadFromJSON(path: String) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let decoder = JSONDecoder()
        let models = try decoder.decode([ModelInfo].self, from: data)
        try registerModels(models)
        logger.info("Registry loaded from: \(path)")
    }

    /// Save registry to JSON file
    public func saveToJSON(path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(Array(models.values))
        try data.write(to: URL(fileURLWithPath: path))
        logger.info("Registry saved to: \(path)")
    }

    /// Get total size of all models
    public func getTotalModelSize() -> UInt64 {
        models.values.reduce(0) { $0 + $1.sizeBytes }
    }
}

/// Registry errors
public enum RegistryError: LocalizedError {
    case registryLocked
    case modelNotFound(String)
    case invalidModel
    case loadFailed(String)

    public var errorDescription: String? {
        switch self {
        case .registryLocked:
            return "Registry is locked and cannot accept new models"
        case .modelNotFound(let id):
            return "Model not found: \(id)"
        case .invalidModel:
            return "Invalid model information"
        case .loadFailed(let path):
            return "Failed to load registry from: \(path)"
        }
    }
}
