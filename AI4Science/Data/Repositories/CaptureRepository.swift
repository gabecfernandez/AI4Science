import Foundation
import SwiftData

/// Capture repository implementation using ModelActor
/// Note: Does not conform to a protocol because SwiftData entities are non-Sendable
@ModelActor
final actor CaptureRepository {

    /// Create a new capture
    func createCapture(_ capture: CaptureEntity) throws {
        modelContext.insert(capture)
        try modelContext.save()
    }

    /// Get capture by ID
    func getCapture(id: String) throws -> CaptureEntity? {
        let descriptor = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Get captures by sample
    func getCapturesBySample(sampleID: String) throws -> [CaptureEntity] {
        let descriptor = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { capture in
                capture.sample?.id == sampleID
            },
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Update capture
    func updateCapture(_ capture: CaptureEntity) throws {
        capture.updatedAt = Date()
        try modelContext.save()
    }

    /// Delete capture
    func deleteCapture(id: String) throws {
        guard let capture = try getCapture(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(capture)
        try modelContext.save()
    }

    /// Get all captures
    func getAllCaptures() throws -> [CaptureEntity] {
        let descriptor = FetchDescriptor<CaptureEntity>(
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get captures by type
    func getCapturesByType(_ type: String) throws -> [CaptureEntity] {
        let descriptor = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { $0.captureType == type },
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get captures by status
    func getCapturesByStatus(_ status: String) throws -> [CaptureEntity] {
        let descriptor = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { $0.processingStatus == status },
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Mark capture as processed
    func markCaptureProcessed(id: String) throws {
        guard let capture = try getCapture(id: id) else {
            throw RepositoryError.notFound
        }
        capture.processingStatus = "processed"
        capture.updatedAt = Date()
        try modelContext.save()
    }

    /// Update processing status
    func updateProcessingStatus(id: String, status: String) throws {
        guard let capture = try getCapture(id: id) else {
            throw RepositoryError.notFound
        }
        capture.processingStatus = status
        capture.updatedAt = Date()
        try modelContext.save()
    }
}

/// Factory for creating capture repository
enum CaptureRepositoryFactory {
    @MainActor
    static func makeRepository(modelContainer: ModelContainer) -> CaptureRepository {
        CaptureRepository(modelContainer: modelContainer)
    }
}
