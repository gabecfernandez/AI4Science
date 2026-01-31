import Foundation
import SwiftData

/// Protocol for sample operations
protocol SampleRepositoryProtocol: Sendable {
    func createSample(_ sample: SampleEntity) async throws
    func getSample(id: String) async throws -> SampleEntity?
    func getSamplesByProject(projectID: String) async throws -> [SampleEntity]
    func updateSample(_ sample: SampleEntity) async throws
    func deleteSample(id: String) async throws
    func getAllSamples() async throws -> [SampleEntity]
    func searchSamples(query: String) async throws -> [SampleEntity]
    func getSamplesByType(_ type: String) async throws -> [SampleEntity]
    func getSamplesByStatus(_ status: String) async throws -> [SampleEntity]
    func flagSample(id: String) async throws
    func unflagSample(id: String) async throws
}

/// Sample repository implementation
actor SampleRepository: SampleRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Create a new sample
    func createSample(_ sample: SampleEntity) async throws {
        modelContext.insert(sample)
        try modelContext.save()
    }

    /// Get sample by ID
    func getSample(id: String) async throws -> SampleEntity? {
        let descriptor = FetchDescriptor<SampleEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Get samples by project
    func getSamplesByProject(projectID: String) async throws -> [SampleEntity] {
        let descriptor = FetchDescriptor<SampleEntity>(
            predicate: #Predicate { sample in
                sample.project?.id == projectID
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Update sample
    func updateSample(_ sample: SampleEntity) async throws {
        sample.updatedAt = Date()
        try modelContext.save()
    }

    /// Delete sample
    func deleteSample(id: String) async throws {
        guard let sample = try getSample(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(sample)
        try modelContext.save()
    }

    /// Get all samples
    func getAllSamples() async throws -> [SampleEntity] {
        let descriptor = FetchDescriptor<SampleEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Search samples by name or description
    func searchSamples(query: String) async throws -> [SampleEntity] {
        let lowercaseQuery = query.lowercased()
        let descriptor = FetchDescriptor<SampleEntity>(
            predicate: #Predicate { sample in
                sample.name.localizedCaseInsensitiveContains(lowercaseQuery) ||
                sample.description.localizedCaseInsensitiveContains(lowercaseQuery)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get samples by type
    func getSamplesByType(_ type: String) async throws -> [SampleEntity] {
        let descriptor = FetchDescriptor<SampleEntity>(
            predicate: #Predicate { $0.sampleType == type },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get samples by status
    func getSamplesByStatus(_ status: String) async throws -> [SampleEntity] {
        let descriptor = FetchDescriptor<SampleEntity>(
            predicate: #Predicate { $0.status == status },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Flag a sample
    func flagSample(id: String) async throws {
        guard let sample = try getSample(id: id) else {
            throw RepositoryError.notFound
        }
        sample.flag()
        try modelContext.save()
    }

    /// Unflag a sample
    func unflagSample(id: String) async throws {
        guard let sample = try getSample(id: id) else {
            throw RepositoryError.notFound
        }
        sample.unflag()
        try modelContext.save()
    }
}

/// Factory for creating sample repository
struct SampleRepositoryFactory {
    static func makeRepository(modelContext: ModelContext) -> SampleRepository {
        SampleRepository(modelContext: modelContext)
    }

    static func makeRepository(modelContainer: ModelContainer) -> SampleRepository {
        let context = ModelContext(modelContainer)
        return SampleRepository(modelContext: context)
    }
}
