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

// MARK: - Sendable Display Models

/// Sendable display model for capture list
struct CaptureDisplayData: Identifiable, Sendable {
    let id: String
    let captureType: String
    let fileURL: String
    let capturedAt: Date
    let processingStatus: String
    let qualityScore: Double?
    let notes: String?
    let sampleName: String?
    let deviceInfo: String?
    let isProcessed: Bool
}

extension CaptureRepository {
    /// Get all captures as Sendable display models
    func getAllCapturesDisplayData() throws -> [CaptureDisplayData] {
        let descriptor = FetchDescriptor<CaptureEntity>(
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map { entity in
            CaptureDisplayData(
                id: entity.id,
                captureType: entity.captureType,
                fileURL: entity.fileURL,
                capturedAt: entity.capturedAt,
                processingStatus: entity.processingStatus,
                qualityScore: entity.qualityScore,
                notes: entity.notes,
                sampleName: entity.sample?.name,
                deviceInfo: entity.deviceInfo,
                isProcessed: entity.isProcessed
            )
        }
    }

    /// Get capture count
    func getCaptureCount() throws -> Int {
        let descriptor = FetchDescriptor<CaptureEntity>()
        return try modelContext.fetchCount(descriptor)
    }
}
