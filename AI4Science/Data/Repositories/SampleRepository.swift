import Foundation
import SwiftData

/// Protocol for sample operations - returns only Sendable domain types
/// Entity-based operations are internal to the actor and not exposed via protocol
protocol SampleRepositoryProtocol: Sendable {
    // Domain model operations would go here when Sample domain model is added
    // For now, keep entity operations internal to actor only
}

/// Sample repository implementation using ModelActor
@ModelActor
final actor SampleRepository {

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
        guard let sample = try await getSample(id: id) else {
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
        // Note: Using localizedStandardContains which is supported in SwiftData predicates
        let descriptor = FetchDescriptor<SampleEntity>(
            predicate: #Predicate { sample in
                sample.name.localizedStandardContains(query) ||
                sample.sampleDescription.localizedStandardContains(query)
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
        guard let sample = try await getSample(id: id) else {
            throw RepositoryError.notFound
        }
        // Inline property updates instead of calling @MainActor method
        sample.isFlagged = true
        sample.updatedAt = Date()
        try modelContext.save()
    }

    /// Unflag a sample
    func unflagSample(id: String) async throws {
        guard let sample = try await getSample(id: id) else {
            throw RepositoryError.notFound
        }
        // Inline property updates instead of calling @MainActor method
        sample.isFlagged = false
        sample.updatedAt = Date()
        try modelContext.save()
    }
}

/// Factory for creating sample repository
enum SampleRepositoryFactory {
    @MainActor
    static func makeRepository(modelContainer: ModelContainer) -> SampleRepository {
        SampleRepository(modelContainer: modelContainer)
    }
}
