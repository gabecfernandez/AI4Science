import Foundation
import SwiftData

/// Annotation repository implementation using ModelActor
/// Note: Does not conform to a protocol because SwiftData entities are non-Sendable
/// and cannot cross actor boundaries through protocol requirements
@ModelActor
final actor AnnotationRepository {

    /// Create a new annotation
    func createAnnotation(_ annotation: AnnotationEntity) throws {
        modelContext.insert(annotation)
        try modelContext.save()
    }

    /// Get annotation by ID
    func getAnnotation(id: String) throws -> AnnotationEntity? {
        let descriptor = FetchDescriptor<AnnotationEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Get annotations by capture
    func getAnnotationsByCapture(captureID: String) throws -> [AnnotationEntity] {
        let descriptor = FetchDescriptor<AnnotationEntity>(
            predicate: #Predicate { annotation in
                annotation.capture?.id == captureID
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Update annotation
    func updateAnnotation(_ annotation: AnnotationEntity) throws {
        annotation.updatedAt = Date()
        try modelContext.save()
    }

    /// Delete annotation
    func deleteAnnotation(id: String) throws {
        guard let annotation = try getAnnotation(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(annotation)
        try modelContext.save()
    }

    /// Get all annotations
    func getAllAnnotations() throws -> [AnnotationEntity] {
        let descriptor = FetchDescriptor<AnnotationEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get annotations by type
    func getAnnotationsByType(_ type: String) throws -> [AnnotationEntity] {
        let descriptor = FetchDescriptor<AnnotationEntity>(
            predicate: #Predicate { $0.annotationType == type },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get annotations by creator
    func getAnnotationsByCreator(_ creatorID: String) throws -> [AnnotationEntity] {
        let descriptor = FetchDescriptor<AnnotationEntity>(
            predicate: #Predicate { $0.createdBy == creatorID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Delete all annotations for a capture
    func deleteAnnotationsByCapture(captureID: String) throws {
        let annotations = try getAnnotationsByCapture(captureID: captureID)
        for annotation in annotations {
            modelContext.delete(annotation)
        }
        try modelContext.save()
    }
}

/// Factory for creating annotation repository
enum AnnotationRepositoryFactory {
    @MainActor
    static func makeRepository(modelContainer: ModelContainer) -> AnnotationRepository {
        AnnotationRepository(modelContainer: modelContainer)
    }
}
