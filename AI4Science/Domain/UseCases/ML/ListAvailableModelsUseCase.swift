import Foundation

public struct ListAvailableModelsUseCase: Sendable {
    private let mlRepository: any MLRepositoryProtocol

    public init(mlRepository: any MLRepositoryProtocol) {
        self.mlRepository = mlRepository
    }

    /// Lists all available ML models
    /// - Returns: Array of ModelInfo sorted by name
    /// - Throws: MLError if fetch fails
    public func execute() async throws -> [ModelInfo] {
        let models = try await mlRepository.listAvailableModels()
        return models.sorted { $0.name < $1.name }
    }

    /// Filters models by type
    /// - Parameter type: Model type to filter
    /// - Returns: Filtered array of models
    /// - Throws: MLError if fetch fails
    public func execute(byType type: ModelType) async throws -> [ModelInfo] {
        let allModels = try await execute()
        return allModels.filter { matchesType($0, type: type) }
    }

    /// Filters models by minimum iOS version compatibility
    /// - Parameter minIOSVersion: Minimum iOS version string
    /// - Returns: Compatible models
    /// - Throws: MLError if fetch fails
    public func execute(compatibleWith minIOSVersion: String) async throws -> [ModelInfo] {
        let allModels = try await execute()
        return allModels.filter { $0.minimumIOSVersion <= minIOSVersion }
    }

    /// Filters models by size constraints
    /// - Parameter maxSizeInBytes: Maximum model size
    /// - Returns: Models within size limit
    /// - Throws: MLError if fetch fails
    public func execute(maxSize maxSizeInBytes: UInt64) async throws -> [ModelInfo] {
        let allModels = try await execute()
        return allModels.filter { $0.sizeBytes <= maxSizeInBytes }
    }

    /// Filters models that are required
    /// - Returns: Required models
    /// - Throws: MLError if fetch fails
    public func executeRequired() async throws -> [ModelInfo] {
        let allModels = try await execute()
        return allModels.filter { $0.isRequired }
    }

    /// Searches models by name or description
    /// - Parameter query: Search query
    /// - Returns: Matching models
    /// - Throws: MLError if fetch fails
    public func search(query: String) async throws -> [ModelInfo] {
        guard !query.isEmpty else {
            return try await execute()
        }

        let allModels = try await execute()
        let searchQuery = query.lowercased()

        return allModels.filter { model in
            model.name.lowercased().contains(searchQuery) ||
            model.id.lowercased().contains(searchQuery)
        }
    }

    /// Gets recommended models for a use case
    /// - Parameter useCase: Research use case
    /// - Returns: Recommended models
    /// - Throws: MLError if fetch fails
    public func getRecommendations(forUseCase useCase: ResearchUseCase) async throws -> [ModelInfo] {
        let allModels = try await execute()

        return allModels.filter { model in
            switch useCase {
            case .microscopy:
                return model.type == .objectDetection || model.type == .segmentation
            case .spectroscopy:
                return model.type == .classification
            case .general:
                return true
            }
        }
        .sorted { $0.name < $1.name }
        .prefix(5)
        .map { $0 }
    }

    // MARK: - Private Methods

    private func matchesType(_ model: ModelInfo, type: ModelType) -> Bool {
        model.type == type
    }
}

// MARK: - Supporting Types

public enum ResearchUseCase: Sendable {
    case microscopy
    case spectroscopy
    case general

    public var description: String {
        switch self {
        case .microscopy:
            return "Microscopy sample analysis"
        case .spectroscopy:
            return "Spectroscopy data analysis"
        case .general:
            return "General research analysis"
        }
    }
}

public struct ModelFilterOptions: Sendable {
    public var type: ModelType?
    public var maxSize: UInt64?
    public var deviceModel: String?
    public var sortBy: ModelSortOption

    public init(
        type: ModelType? = nil,
        maxSize: UInt64? = nil,
        deviceModel: String? = nil,
        sortBy: ModelSortOption = .accuracy
    ) {
        self.type = type
        self.maxSize = maxSize
        self.deviceModel = deviceModel
        self.sortBy = sortBy
    }
}

public enum ModelSortOption: Sendable {
    case accuracy
    case size
    case speed
    case relevance
    case name
}

public struct ModelCatalog: Sendable {
    public let models: [ModelInfo]
    public let totalCount: Int
    public let categories: [String: [ModelInfo]]
    public let lastUpdated: Date

    public var objectDetectionModels: [ModelInfo] {
        models.filter { $0.type == .objectDetection }
    }

    public var classificationModels: [ModelInfo] {
        models.filter { $0.type == .classification }
    }

    public var segmentationModels: [ModelInfo] {
        models.filter { $0.type == .segmentation }
    }

    public init(
        models: [ModelInfo],
        totalCount: Int,
        categories: [String: [ModelInfo]] = [:],
        lastUpdated: Date = Date()
    ) {
        self.models = models
        self.totalCount = totalCount
        self.categories = categories
        self.lastUpdated = lastUpdated
    }
}
