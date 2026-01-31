import Foundation
import SwiftData

/// Protocol for ML model operations - returns only Sendable domain types
/// Entity-based operations are internal to the actor and not exposed via protocol
protocol MLModelRepositoryProtocol: Sendable {
    // Domain model operations would go here when MLModel domain model is added
    // For now, keep entity operations internal to actor only
}

/// ML Model repository implementation using ModelActor
@ModelActor
final actor MLModelRepository {

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
        guard let model = try await getModel(id: id) else {
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
        guard let model = try await getModel(id: modelID) else {
            throw RepositoryError.notFound
        }
        // Inline property updates instead of calling @MainActor method
        model.downloadStatus = status
        model.downloadProgress = min(max(progress, 0.0), 1.0)
        model.updatedAt = Date()
        try modelContext.save()
    }

    /// Mark model download as complete
    func markModelDownloadComplete(modelID: String, localPath: String) async throws {
        guard let model = try await getModel(id: modelID) else {
            throw RepositoryError.notFound
        }
        // Inline property updates instead of calling @MainActor method
        model.downloadStatus = "downloaded"
        model.downloadProgress = 1.0
        model.localPath = localPath
        model.updatedAt = Date()
        try modelContext.save()
    }
}

/// Factory for creating ML model repository
enum MLModelRepositoryFactory {
    @MainActor
    static func makeRepository(modelContainer: ModelContainer) -> MLModelRepository {
        MLModelRepository(modelContainer: modelContainer)
    }
}
