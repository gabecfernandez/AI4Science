import Foundation
import SwiftData

/// Protocol for analysis result operations - entity methods are internal to actor only
protocol AnalysisResultDataSourceProtocol: Sendable {
    // Domain model operations would go here when AnalysisResult domain model is added
    // For now, keep entity operations internal to actor only
}

/// Analysis result repository implementation using ModelActor
@ModelActor
final actor AnalysisResultRepository {

    /// Create a new analysis result
    func createAnalysisResult(_ result: AnalysisResultEntity) async throws {
        modelContext.insert(result)
        try modelContext.save()
    }

    /// Get analysis result by ID
    func getAnalysisResult(id: String) async throws -> AnalysisResultEntity? {
        let descriptor = FetchDescriptor<AnalysisResultEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Get analysis results by capture
    func getAnalysisResultsByCapture(captureID: String) async throws -> [AnalysisResultEntity] {
        let descriptor = FetchDescriptor<AnalysisResultEntity>(
            predicate: #Predicate { result in
                result.capture?.id == captureID
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get analysis results by model
    func getAnalysisResultsByModel(modelID: String) async throws -> [AnalysisResultEntity] {
        let descriptor = FetchDescriptor<AnalysisResultEntity>(
            predicate: #Predicate { $0.modelID == modelID },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Update analysis result
    func updateAnalysisResult(_ result: AnalysisResultEntity) async throws {
        try modelContext.save()
    }

    /// Delete analysis result
    func deleteAnalysisResult(id: String) async throws {
        guard let result = try await getAnalysisResult(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(result)
        try modelContext.save()
    }

    /// Get all analysis results
    func getAllAnalysisResults() async throws -> [AnalysisResultEntity] {
        let descriptor = FetchDescriptor<AnalysisResultEntity>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get results by status
    func getResultsByStatus(_ status: String) async throws -> [AnalysisResultEntity] {
        let descriptor = FetchDescriptor<AnalysisResultEntity>(
            predicate: #Predicate { $0.status == status },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get reviewed results
    func getReviewedResults() async throws -> [AnalysisResultEntity] {
        let descriptor = FetchDescriptor<AnalysisResultEntity>(
            predicate: #Predicate { $0.isReviewed == true },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get pending analysis results
    func getPendingAnalysis() async throws -> [AnalysisResultEntity] {
        let descriptor = FetchDescriptor<AnalysisResultEntity>(
            predicate: #Predicate { status in
                status.status == "pending" || status.status == "processing"
            },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}

/// Type alias for compatibility
typealias AnalysisRepository = AnalysisResultRepository

/// Factory for creating analysis result repository
enum AnalysisResultRepositoryFactory {
    @MainActor
    static func makeRepository(modelContainer: ModelContainer) -> AnalysisResultRepository {
        AnalysisResultRepository(modelContainer: modelContainer)
    }
}
