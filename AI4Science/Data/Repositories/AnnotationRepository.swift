import Foundation
import SwiftData

/// Protocol for annotation operations
protocol AnnotationRepositoryProtocol: Sendable {
    func createAnnotation(_ annotation: AnnotationEntity) async throws
    func getAnnotation(id: String) async throws -> AnnotationEntity?
    func getAnnotationsByCapture(captureID: String) async throws -> [AnnotationEntity]
    func updateAnnotation(_ annotation: AnnotationEntity) async throws
    func deleteAnnotation(id: String) async throws
    func getAllAnnotations() async throws -> [AnnotationEntity]
    func getAnnotationsByType(_ type: String) async throws -> [AnnotationEntity]
    func getAnnotationsByCreator(_ creatorID: String) async throws -> [AnnotationEntity]
    func deleteAnnotationsByCapture(captureID: String) async throws
}

/// Annotation repository implementation
actor AnnotationRepository: AnnotationRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Create a new annotation
    func createAnnotation(_ annotation: AnnotationEntity) async throws {
        modelContext.insert(annotation)
        try modelContext.save()
    }

    /// Get annotation by ID
    func getAnnotation(id: String) async throws -> AnnotationEntity? {
        let descriptor = FetchDescriptor<AnnotationEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Get annotations by capture
    func getAnnotationsByCapture(captureID: String) async throws -> [AnnotationEntity] {
        let descriptor = FetchDescriptor<AnnotationEntity>(
            predicate: #Predicate { annotation in
                annotation.capture?.id == captureID
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Update annotation
    func updateAnnotation(_ annotation: AnnotationEntity) async throws {
        annotation.updatedAt = Date()
        try modelContext.save()
    }

    /// Delete annotation
    func deleteAnnotation(id: String) async throws {
        guard let annotation = try getAnnotation(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(annotation)
        try modelContext.save()
    }

    /// Get all annotations
    func getAllAnnotations() async throws -> [AnnotationEntity] {
        let descriptor = FetchDescriptor<AnnotationEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get annotations by type
    func getAnnotationsByType(_ type: String) async throws -> [AnnotationEntity] {
        let descriptor = FetchDescriptor<AnnotationEntity>(
            predicate: #Predicate { $0.annotationType == type },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get annotations by creator
    func getAnnotationsByCreator(_ creatorID: String) async throws -> [AnnotationEntity] {
        let descriptor = FetchDescriptor<AnnotationEntity>(
            predicate: #Predicate { $0.createdBy == creatorID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Delete all annotations for a capture
    func deleteAnnotationsByCapture(captureID: String) async throws {
        let annotations = try getAnnotationsByCapture(captureID: captureID)
        for annotation in annotations {
            modelContext.delete(annotation)
        }
        try modelContext.save()
    }
}

/// Factory for creating annotation repository
struct AnnotationRepositoryFactory {
    static func makeRepository(modelContext: ModelContext) -> AnnotationRepository {
        AnnotationRepository(modelContext: modelContext)
    }

    static func makeRepository(modelContainer: ModelContainer) -> AnnotationRepository {
        let context = ModelContext(modelContainer)
        return AnnotationRepository(modelContext: context)
    }
}
