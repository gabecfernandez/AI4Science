import Foundation
import SwiftData

/// Capture repository with domain-model interface
actor CaptureRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ capture: Capture) async throws {
        let idStr = capture.id.uuidString
        let descriptor = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { $0.id == idStr }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.captureType = capture.type.rawValue
            existing.fileURL = capture.fileURL.path
            existing.fileSize = capture.fileSize
            existing.deviceInfo = capture.metadata.deviceModel
            existing.capturedAt = capture.metadata.captureDate
        } else {
            let entity = CaptureMapper.toEntity(from: capture)
            modelContext.insert(entity)
        }
        try modelContext.save()
    }

    func findById(_ id: UUID) async throws -> Capture? {
        let idStr = id.uuidString
        let descriptor = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { $0.id == idStr }
        )
        guard let entity = try modelContext.fetch(descriptor).first else { return nil }
        return CaptureMapper.toModel(from: entity)
    }

    func findBySample(_ sampleId: UUID) async throws -> [Capture] {
        let sampleIdStr = sampleId.uuidString
        let descriptor = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { $0.sample?.id == sampleIdStr },
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { CaptureMapper.toModel(from: $0) }
    }

    func delete(_ id: UUID) async throws {
        let idStr = id.uuidString
        let descriptor = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { $0.id == idStr }
        )
        guard let entity = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        modelContext.delete(entity)
        try modelContext.save()
    }
}
