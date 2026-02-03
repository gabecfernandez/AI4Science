import Foundation

public struct ListAvailableModelsUseCase: Sendable {
    private let mlRepository: any MLRepositoryProtocol

    public init(mlRepository: any MLRepositoryProtocol) {
        self.mlRepository = mlRepository
    }

    /// Lists all available ML models
    /// - Returns: Array of LoadedModelInfo sorted by relevance
    /// - Throws: MLError if fetch fails
    public func execute() async throws -> [LoadedModelInfo] {
        let models = try await mlRepository.listAvailableModels()
        return models.sorted { $0.accuracy > $1.accuracy }
    }

    /// Filters models by type
    /// - Parameter type: Model type to filter
    /// - Returns: Filtered array of models
    /// - Throws: MLError if fetch fails
    public func execute(byType type: LoadedModelType) async throws -> [LoadedModelInfo] {
        let allModels = try await execute()
        return allModels.filter { $0.type == type }
    }

    /// Filters models by compatibility
    /// - Parameter deviceModel: Device model string
    /// - Returns: Compatible models
    /// - Throws: MLError if fetch fails
    public func execute(compatibleWith deviceModel: String) async throws -> [LoadedModelInfo] {
        let allModels = try await execute()
        return allModels.filter { $0.compatibility.contains(deviceModel) }
    }

    /// Filters models by size constraints
    /// - Parameter maxSizeInBytes: Maximum model size
    /// - Returns: Models within size limit
    /// - Throws: MLError if fetch fails
    public func execute(maxSize maxSizeInBytes: Int) async throws -> [LoadedModelInfo] {
        let allModels = try await execute()
        return allModels.filter { $0.sizeInBytes <= maxSizeInBytes }
    }

    /// Filters models by minimum accuracy
    /// - Parameter minAccuracy: Minimum accuracy threshold (0.0 to 1.0)
    /// - Returns: Models meeting accuracy threshold
    /// - Throws: MLError if fetch fails
    public func execute(minAccuracy: Float) async throws -> [LoadedModelInfo] {
        guard minAccuracy >= 0 && minAccuracy <= 1.0 else {
            throw MLError.validationFailed("Accuracy must be between 0 and 1.")
        }

        let allModels = try await execute()
        return allModels.filter { $0.accuracy >= minAccuracy }
    }

    /// Searches models by name or description
    /// - Parameter query: Search query
    /// - Returns: Matching models
    /// - Throws: MLError if fetch fails
    public func search(query: String) async throws -> [LoadedModelInfo] {
        guard !query.isEmpty else {
            return try await execute()
        }

        let allModels = try await execute()
        let searchQuery = query.lowercased()

        return allModels.filter { model in
            model.name.lowercased().contains(searchQuery) ||
            model.description.lowercased().contains(searchQuery)
        }
    }

    /// Gets recommended models for a use case
    /// - Parameter useCase: Research use case
    /// - Returns: Recommended models
    /// - Throws: MLError if fetch fails
    public func getRecommendations(forUseCase useCase: ResearchUseCase) async throws -> [LoadedModelInfo] {
        let allModels = try await execute()

        let filtered = allModels.filter { model in
            switch useCase {
            case .microscopy:
                return model.type == .objectDetection || model.type == .segmentation
            case .spectroscopy:
                return model.type == .imageClassification
            case .general:
                return true
            }
        }
        .sorted { $0.accuracy > $1.accuracy }

        return Array(filtered.prefix(5))
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
    public var type: LoadedModelType?
    public var maxSize: Int?
    public var minAccuracy: Float?
    public var deviceModel: String?
    public var sortBy: ModelSortOption

    public init(
        type: LoadedModelType? = nil,
        maxSize: Int? = nil,
        minAccuracy: Float? = nil,
        deviceModel: String? = nil,
        sortBy: ModelSortOption = .accuracy
    ) {
        self.type = type
        self.maxSize = maxSize
        self.minAccuracy = minAccuracy
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
    public let models: [LoadedModelInfo]
    public let totalCount: Int
    public let categories: [String: [LoadedModelInfo]]
    public let lastUpdated: Date

    public var objectDetectionModels: [LoadedModelInfo] {
        models.filter { $0.type == .objectDetection }
    }

    public var classificationModels: [LoadedModelInfo] {
        models.filter { $0.type == .imageClassification }
    }

    public var segmentationModels: [LoadedModelInfo] {
        models.filter { $0.type == .segmentation }
    }

    public init(
        models: [LoadedModelInfo],
        totalCount: Int,
        categories: [String: [LoadedModelInfo]] = [:],
        lastUpdated: Date = Date()
    ) {
        self.models = models
        self.totalCount = totalCount
        self.categories = categories
        self.lastUpdated = lastUpdated
    }
}
