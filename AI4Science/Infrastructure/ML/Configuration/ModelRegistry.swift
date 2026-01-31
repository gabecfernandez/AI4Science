import Foundation
import os.log

/// Registry of available ML models with metadata
/// Manages model lifecycle, availability, and versioning
actor ModelRegistry {
    static let shared = ModelRegistry()

    private let logger = Logger(subsystem: "com.ai4science.ml", category: "ModelRegistry")
    private var registeredModels: [String: RegisteredModel] = [:]
    private var modelGroups: [ModelGroup: [String]] = [:]

    private init() {
        loadDefaultModels()
    }

    // MARK: - Model Registration

    /// Register a new model
    /// - Parameter model: RegisteredModel to add to registry
    func registerModel(_ model: RegisteredModel) async {
        registeredModels[model.metadata.identifier] = model
        logger.debug("Registered model: \(model.metadata.name)")

        // Add to group
        if !modelGroups[model.group, default: []].contains(model.metadata.identifier) {
            modelGroups[model.group, default: []].append(model.metadata.identifier)
        }
    }

    /// Register multiple models
    /// - Parameter models: Array of RegisteredModel to register
    func registerModels(_ models: [RegisteredModel]) async {
        for model in models {
            await registerModel(model)
        }
    }

    // MARK: - Model Retrieval

    /// Get model metadata by identifier
    /// - Parameter identifier: Model identifier
    /// - Returns: RegisteredModel or nil if not found
    func getModel(_ identifier: String) -> RegisteredModel? {
        return registeredModels[identifier]
    }

    /// Get all registered models
    /// - Returns: Dictionary of all registered models
    func getAllModels() -> [String: RegisteredModel] {
        return registeredModels
    }

    /// Get models in a specific group
    /// - Parameter group: ModelGroup to query
    /// - Returns: Array of model identifiers in group
    func getModels(in group: ModelGroup) -> [RegisteredModel] {
        let identifiers = modelGroups[group] ?? []
        return identifiers.compactMap { registeredModels[$0] }
    }

    /// Search for models by name
    /// - Parameter searchTerm: Name or partial name to search
    /// - Returns: Array of matching RegisteredModel
    func searchModels(by searchTerm: String) -> [RegisteredModel] {
        registeredModels.values.filter { model in
            model.metadata.name.localizedCaseInsensitiveContains(searchTerm) ||
            model.metadata.description?.localizedCaseInsensitiveContains(searchTerm) ?? false
        }.sorted { $0.metadata.name < $1.metadata.name }
    }

    // MARK: - Model Status

    /// Check if model is available
    /// - Parameter identifier: Model identifier
    /// - Returns: true if model is registered and available
    func isModelAvailable(_ identifier: String) -> Bool {
        guard let model = registeredModels[identifier] else { return false }
        return model.status == .available
    }

    /// Get models available on device
    /// - Returns: Array of available models
    func getAvailableModels() -> [RegisteredModel] {
        registeredModels.values.filter { $0.status == .available }
    }

    /// Get models requiring update
    /// - Returns: Array of models with available updates
    func getModelsRequiringUpdate() -> [RegisteredModel] {
        registeredModels.values.filter { $0.hasUpdate }
    }

    // MARK: - Model Metadata

    /// Get model dependencies
    /// - Parameter identifier: Model identifier
    /// - Returns: Array of dependent model identifiers
    func getDependencies(for identifier: String) -> [String] {
        guard let model = registeredModels[identifier] else { return [] }
        return model.dependencies
    }

    /// Check if all dependencies are available
    /// - Parameter identifier: Model identifier
    /// - Returns: true if all dependencies are available
    func areDependenciesAvailable(for identifier: String) -> Bool {
        let dependencies = getDependencies(for: identifier)
        return dependencies.allSatisfy { isModelAvailable($0) }
    }

    // MARK: - Model Management

    /// Mark model as unavailable
    /// - Parameter identifier: Model identifier
    func markUnavailable(_ identifier: String) async {
        guard var model = registeredModels[identifier] else { return }
        model.status = .unavailable
        registeredModels[identifier] = model
        logger.warning("Marked model as unavailable: \(identifier)")
    }

    /// Mark model as outdated
    /// - Parameter identifier: Model identifier
    func markOutdated(_ identifier: String) async {
        guard var model = registeredModels[identifier] else { return }
        model.hasUpdate = true
        registeredModels[identifier] = model
        logger.debug("Marked model as outdated: \(identifier)")
    }

    /// Update model version
    /// - Parameters:
    ///   - identifier: Model identifier
    ///   - version: New version string
    func updateVersion(_ identifier: String, to version: String) async {
        guard var model = registeredModels[identifier] else { return }
        model.metadata = RegisteredModel.Metadata(
            identifier: model.metadata.identifier,
            name: model.metadata.name,
            version: version,
            description: model.metadata.description,
            author: model.metadata.author,
            createdDate: model.metadata.createdDate,
            lastUpdatedDate: Date(),
            requiredIOSVersion: model.metadata.requiredIOSVersion,
            estimatedSize: model.metadata.estimatedSize,
            supportedDevices: model.metadata.supportedDevices,
            performance: model.metadata.performance,
            documentation: model.metadata.documentation
        )
        model.status = .available
        model.hasUpdate = false
        registeredModels[identifier] = model
        logger.debug("Updated model version: \(identifier) to \(version)")
    }

    // MARK: - Statistics

    /// Get registry statistics
    /// - Returns: ModelRegistryStats with information about registered models
    func getStatistics() -> ModelRegistryStats {
        let models = registeredModels.values
        let totalCount = models.count
        let availableCount = models.filter { $0.status == .available }.count
        let totalSize = models.reduce(0) { $0 + $1.metadata.estimatedSize }

        let groupCounts = Dictionary(grouping: models) { $0.group }
            .mapValues { $0.count }

        return ModelRegistryStats(
            totalModels: totalCount,
            availableModels: availableCount,
            modelsRequiringUpdate: models.filter { $0.hasUpdate }.count,
            totalEstimatedSize: totalSize,
            modelsByGroup: groupCounts
        )
    }

    // MARK: - Default Models

    private func loadDefaultModels() {
        let defaultModels = [
            RegisteredModel(
                metadata: .init(
                    identifier: "ImageClassificationModel",
                    name: "Image Classification",
                    version: "1.0.0",
                    description: "Classifies images into predefined categories",
                    author: "AI4Science",
                    createdDate: Date(),
                    lastUpdatedDate: Date(),
                    requiredIOSVersion: "14.0",
                    estimatedSize: 50_000_000,
                    supportedDevices: [.iPhone, .iPad],
                    performance: ModelPerformanceInfo(
                        averageInferenceTime: 100,
                        peakMemoryUsage: 200_000_000,
                        accuracy: 0.92
                    ),
                    documentation: "Classification model for general image analysis"
                ),
                group: .imageProcessing,
                status: .available,
                downloadURL: nil,
                dependencies: []
            ),
            RegisteredModel(
                metadata: .init(
                    identifier: "ObjectDetectionModel",
                    name: "Object Detection",
                    version: "1.0.0",
                    description: "Detects objects with bounding boxes",
                    author: "AI4Science",
                    createdDate: Date(),
                    lastUpdatedDate: Date(),
                    requiredIOSVersion: "14.0",
                    estimatedSize: 80_000_000,
                    supportedDevices: [.iPhone, .iPad],
                    performance: ModelPerformanceInfo(
                        averageInferenceTime: 150,
                        peakMemoryUsage: 300_000_000,
                        accuracy: 0.85
                    ),
                    documentation: "Object detection model with bounding box output"
                ),
                group: .imageProcessing,
                status: .available,
                downloadURL: nil,
                dependencies: []
            ),
            RegisteredModel(
                metadata: .init(
                    identifier: "DefectDetectionModel",
                    name: "Defect Detection",
                    version: "1.0.0",
                    description: "Specialized defect detection model",
                    author: "AI4Science",
                    createdDate: Date(),
                    lastUpdatedDate: Date(),
                    requiredIOSVersion: "14.0",
                    estimatedSize: 75_000_000,
                    supportedDevices: [.iPhone, .iPad],
                    performance: ModelPerformanceInfo(
                        averageInferenceTime: 120,
                        peakMemoryUsage: 250_000_000,
                        accuracy: 0.88
                    ),
                    documentation: "Specialized model for detecting manufacturing defects"
                ),
                group: .defectDetection,
                status: .available,
                downloadURL: nil,
                dependencies: []
            ),
        ]

        for model in defaultModels {
            registeredModels[model.metadata.identifier] = model
            modelGroups[model.group, default: []].append(model.metadata.identifier)
        }

        logger.debug("Loaded \(defaultModels.count) default models")
    }
}

// MARK: - Registered Model

struct RegisteredModel: Sendable {
    let metadata: Metadata
    let group: ModelGroup
    var status: ModelStatus
    let downloadURL: URL?
    let dependencies: [String]
    var hasUpdate: Bool = false

    struct Metadata: Sendable, Codable {
        let identifier: String
        let name: String
        let version: String
        let description: String?
        let author: String?
        let createdDate: Date?
        let lastUpdatedDate: Date?
        let requiredIOSVersion: String
        let estimatedSize: Int
        let supportedDevices: [ModelDevice]
        let performance: ModelPerformanceInfo?
        let documentation: String?

        enum ModelDevice: String, Sendable, Codable, CaseIterable {
            case iPhone
            case iPad
            case simulator
        }
    }
}

/// Model group categorization
enum ModelGroup: String, Sendable, Hashable, CaseIterable {
    case imageProcessing = "Image Processing"
    case defectDetection = "Defect Detection"
    case objectDetection = "Object Detection"
    case textRecognition = "Text Recognition"
    case custom = "Custom"

    var description: String {
        rawValue
    }
}

/// Model status
enum ModelStatus: String, Sendable {
    case available
    case unavailable
    case loading
    case error
}

/// Model performance information
struct ModelPerformanceInfo: Sendable, Codable {
    let averageInferenceTime: Int
    let peakMemoryUsage: Int
    let accuracy: Float?
}

/// Registry statistics
struct ModelRegistryStats: Sendable {
    let totalModels: Int
    let availableModels: Int
    let modelsRequiringUpdate: Int
    let totalEstimatedSize: Int
    let modelsByGroup: [ModelGroup: Int]

    var totalEstimatedSizeMB: Double {
        Double(totalEstimatedSize) / (1024 * 1024)
    }
}
