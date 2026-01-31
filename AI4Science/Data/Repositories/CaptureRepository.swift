import Foundation
import SwiftData

/// Protocol for capture operations
protocol CaptureRepositoryProtocol: Sendable {
    func createCapture(_ capture: CaptureEntity) async throws
    func getCapture(id: String) async throws -> CaptureEntity?
    func getCapturesBySample(sampleID: String) async throws -> [CaptureEntity]
    func updateCapture(_ capture: CaptureEntity) async throws
    func deleteCapture(id: String) async throws
    func getAllCaptures() async throws -> [CaptureEntity]
    func getCapturesByType(_ type: String) async throws -> [CaptureEntity]
    func getCapturesByStatus(_ status: String) async throws -> [CaptureEntity]
    func markCaptureProcessed(id: String) async throws
    func updateProcessingStatus(id: String, status: String) async throws
}

/// Capture repository implementation
actor CaptureRepository: CaptureRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Create a new capture
    func createCapture(_ capture: CaptureEntity) async throws {
        modelContext.insert(capture)
        try modelContext.save()
    }

    /// Get capture by ID
    func getCapture(id: String) async throws -> CaptureEntity? {
        let descriptor = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Get captures by sample
    func getCapturesBySample(sampleID: String) async throws -> [CaptureEntity] {
        let descriptor = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { capture in
                capture.sample?.id == sampleID
            },
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Update capture
    func updateCapture(_ capture: CaptureEntity) async throws {
        capture.updatedAt = Date()
        try modelContext.save()
    }

    /// Delete capture
    func deleteCapture(id: String) async throws {
        guard let capture = try getCapture(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(capture)
        try modelContext.save()
    }

    /// Get all captures
    func getAllCaptures() async throws -> [CaptureEntity] {
        let descriptor = FetchDescriptor<CaptureEntity>(
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get captures by type
    func getCapturesByType(_ type: String) async throws -> [CaptureEntity] {
        let descriptor = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { $0.captureType == type },
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get captures by status
    func getCapturesByStatus(_ status: String) async throws -> [CaptureEntity] {
        let descriptor = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { $0.processingStatus == status },
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Mark capture as processed
    func markCaptureProcessed(id: String) async throws {
        guard let capture = try getCapture(id: id) else {
            throw RepositoryError.notFound
        }
        capture.markAsProcessed()
        try modelContext.save()
    }

    /// Update processing status
    func updateProcessingStatus(id: String, status: String) async throws {
        guard let capture = try getCapture(id: id) else {
            throw RepositoryError.notFound
        }
        capture.setProcessingStatus(status)
        try modelContext.save()
    }
}

/// Factory for creating capture repository
struct CaptureRepositoryFactory {
    static func makeRepository(modelContext: ModelContext) -> CaptureRepository {
        CaptureRepository(modelContext: modelContext)
    }

    static func makeRepository(modelContainer: ModelContainer) -> CaptureRepository {
        let context = ModelContext(modelContainer)
        return CaptureRepository(modelContext: context)
    }
}
