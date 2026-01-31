import Foundation
import SwiftData

/// Protocol for ML model operations
protocol MLModelRepositoryProtocol: Sendable {
    func createModel(_ model: MLModelEntity) async throws
    func getModel(id: String) async throws -> MLModelEntity?
    func getModelByName(_ name: String) async throws -> MLModelEntity?
    func updateModel(_ model: MLModelEntity) async throws
    func deleteModel(id: String) async throws
    func getAllModels() async throws -> [MLModelEntity]
    func getDownloadedModels() async throws -> [MLModelEntity]
    func getModelsByType(_ type: String) async throws -> [MLModelEntity]
    func getEnabledModels() async throws -> [MLModelEntity]
    func updateDownloadStatus(modelID: String, status: String, progress: Double) async throws
    func markModelDownloadComplete(modelID: String, localPath: String) async throws
}

/// ML Model repository implementation
actor MLModelRepository: MLModelRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Create a new ML model
    func createModel(_ model: MLModelEntity) async throws {
        modelContext.insert(model)
        try modelContext.save()
    }

    /// Get model by ID
    func getModel(id: String) async throws -> MLModelEntity? {
        let descriptor = FetchDescriptor<MLModelEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Get model by name
    func getModelByName(_ name: String) async throws -> MLModelEntity? {
        let descriptor = FetchDescriptor<MLModelEntity>(
            predicate: #Predicate { $0.name == name }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Update model
    func updateModel(_ model: MLModelEntity) async throws {
        model.updatedAt = Date()
        try modelContext.save()
    }

    /// Delete model
    func deleteModel(id: String) async throws {
        guard let model = try getModel(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(model)
        try modelContext.save()
    }

    /// Get all models
    func getAllModels() async throws -> [MLModelEntity] {
        let descriptor = FetchDescriptor<MLModelEntity>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get downloaded models
    func getDownloadedModels() async throws -> [MLModelEntity] {
        let descriptor = FetchDescriptor<MLModelEntity>(
            predicate: #Predicate { $0.downloadStatus == "downloaded" },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get models by type
    func getModelsByType(_ type: String) async throws -> [MLModelEntity] {
        let descriptor = FetchDescriptor<MLModelEntity>(
            predicate: #Predicate { $0.modelType == type },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get enabled models
    func getEnabledModels() async throws -> [MLModelEntity] {
        let descriptor = FetchDescriptor<MLModelEntity>(
            predicate: #Predicate { $0.isEnabled == true },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Update download status
    func updateDownloadStatus(modelID: String, status: String, progress: Double) async throws {
        guard let model = try getModel(id: modelID) else {
            throw RepositoryError.notFound
        }
        model.updateDownloadStatus(status, progress: progress)
        try modelContext.save()
    }

    /// Mark model download as complete
    func markModelDownloadComplete(modelID: String, localPath: String) async throws {
        guard let model = try getModel(id: modelID) else {
            throw RepositoryError.notFound
        }
        model.markDownloadCompleted(localPath: localPath)
        try modelContext.save()
    }
}

/// Factory for creating ML model repository
struct MLModelRepositoryFactory {
    static func makeRepository(modelContext: ModelContext) -> MLModelRepository {
        MLModelRepository(modelContext: modelContext)
    }

    static func makeRepository(modelContainer: ModelContainer) -> MLModelRepository {
        let context = ModelContext(modelContainer)
        return MLModelRepository(modelContext: context)
    }
}
