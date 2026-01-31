//
//  MockRepositories.swift
//  AI4ScienceTests
//
//  Centralized mock repositories for testing
//

import Foundation
@testable import AI4Science

// MARK: - Mock User Repository

actor MockUserRepository: UserRepositoryProtocol {
    private var users: [UUID: User] = [:]
    var saveCallCount = 0
    var deleteCallCount = 0

    func save(_ user: User) async throws {
        saveCallCount += 1
        users[user.id] = user
    }

    func findById(_ id: UUID) async throws -> User? {
        users[id]
    }

    func findByEmail(_ email: String) async throws -> User? {
        users.values.first { $0.email == email }
    }

    func findAll() async throws -> [User] {
        Array(users.values)
    }

    func delete(_ id: UUID) async throws {
        deleteCallCount += 1
        users.removeValue(forKey: id)
    }

    func clear() {
        users.removeAll()
    }
}

// MARK: - Mock Sample Repository

actor MockSampleRepository: SampleRepositoryProtocol {
    private var samples: [UUID: Sample] = [:]

    func save(_ sample: Sample) async throws {
        samples[sample.id] = sample
    }

    func findById(_ id: UUID) async throws -> Sample? {
        samples[id]
    }

    func findByProject(_ projectId: UUID) async throws -> [Sample] {
        samples.values.filter { $0.projectId == projectId }
    }

    func findByStatus(_ status: SampleStatus) async throws -> [Sample] {
        samples.values.filter { $0.status == status }
    }

    func delete(_ id: UUID) async throws {
        samples.removeValue(forKey: id)
    }

    func addSamples(_ newSamples: [Sample]) {
        for sample in newSamples {
            samples[sample.id] = sample
        }
    }
}

// MARK: - Mock Annotation Repository

actor MockAnnotationRepository: AnnotationRepositoryProtocol {
    private var annotations: [UUID: Annotation] = [:]

    func save(_ annotation: Annotation) async throws {
        annotations[annotation.id] = annotation
    }

    func findById(_ id: UUID) async throws -> Annotation? {
        annotations[id]
    }

    func findByCapture(_ captureId: UUID) async throws -> [Annotation] {
        annotations.values.filter { $0.captureId == captureId }
    }

    func findByType(_ type: AnnotationType) async throws -> [Annotation] {
        annotations.values.filter { $0.type == type }
    }

    func findBySeverity(_ severity: DefectSeverity) async throws -> [Annotation] {
        annotations.values.filter { $0.severity == severity }
    }

    func delete(_ id: UUID) async throws {
        annotations.removeValue(forKey: id)
    }

    func deleteByCapture(_ captureId: UUID) async throws {
        annotations = annotations.filter { $0.value.captureId != captureId }
    }
}

// MARK: - Mock Analysis Repository

actor MockAnalysisResultRepository: AnalysisRepositoryProtocol {
    private var results: [UUID: AnalysisResult] = [:]

    func save(_ result: AnalysisResult) async throws {
        results[result.id] = result
    }

    func findById(_ id: UUID) async throws -> AnalysisResult? {
        results[id]
    }

    func findByCapture(_ captureId: UUID) async throws -> [AnalysisResult] {
        results.values.filter { $0.captureId == captureId }
    }

    func findByModel(_ modelType: String) async throws -> [AnalysisResult] {
        results.values.filter { $0.modelType == modelType }
    }

    func findLatest(for captureId: UUID) async throws -> AnalysisResult? {
        results.values
            .filter { $0.captureId == captureId }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }

    func delete(_ id: UUID) async throws {
        results.removeValue(forKey: id)
    }
}

// MARK: - Mock ML Model Repository

actor MockMLModelRepository: MLModelRepositoryProtocol {
    private var models: [String: MLModelMetadata] = [:]

    func save(_ metadata: MLModelMetadata) async throws {
        models[metadata.type.rawValue] = metadata
    }

    func findByType(_ type: MLModelType) async throws -> MLModelMetadata? {
        models[type.rawValue]
    }

    func findAll() async throws -> [MLModelMetadata] {
        Array(models.values)
    }

    func delete(_ type: MLModelType) async throws {
        models.removeValue(forKey: type.rawValue)
    }

    func getLatestVersion(for type: MLModelType) async throws -> String? {
        models[type.rawValue]?.version
    }
}

// MARK: - Mock Sync Repository

actor MockSyncRepository {
    private var pendingOperations: [SyncOperation] = []
    private var completedOperations: [SyncOperation] = []

    func addPending(_ operation: SyncOperation) {
        pendingOperations.append(operation)
    }

    func getPending() -> [SyncOperation] {
        pendingOperations
    }

    func markCompleted(_ operationId: UUID) {
        if let index = pendingOperations.firstIndex(where: { $0.id == operationId }) {
            let operation = pendingOperations.remove(at: index)
            completedOperations.append(operation)
        }
    }

    func clearAll() {
        pendingOperations.removeAll()
        completedOperations.removeAll()
    }
}

// MARK: - Supporting Types

struct SyncOperation: Identifiable, Sendable {
    let id: UUID
    let entityType: String
    let entityId: UUID
    let operationType: SyncOperationType
    let createdAt: Date
}

enum SyncOperationType: String, Sendable {
    case create
    case update
    case delete
}

protocol UserRepositoryProtocol: Sendable {
    func save(_ user: User) async throws
    func findById(_ id: UUID) async throws -> User?
    func findByEmail(_ email: String) async throws -> User?
    func findAll() async throws -> [User]
    func delete(_ id: UUID) async throws
}

protocol SampleRepositoryProtocol: Sendable {
    func save(_ sample: Sample) async throws
    func findById(_ id: UUID) async throws -> Sample?
    func findByProject(_ projectId: UUID) async throws -> [Sample]
    func delete(_ id: UUID) async throws
}

protocol AnnotationRepositoryProtocol: Sendable {
    func save(_ annotation: Annotation) async throws
    func findById(_ id: UUID) async throws -> Annotation?
    func findByCapture(_ captureId: UUID) async throws -> [Annotation]
    func delete(_ id: UUID) async throws
}

protocol AnalysisRepositoryProtocol: Sendable {
    func save(_ result: AnalysisResult) async throws
    func findById(_ id: UUID) async throws -> AnalysisResult?
    func findByCapture(_ captureId: UUID) async throws -> [AnalysisResult]
    func delete(_ id: UUID) async throws
}

protocol MLModelRepositoryProtocol: Sendable {
    func save(_ metadata: MLModelMetadata) async throws
    func findByType(_ type: MLModelType) async throws -> MLModelMetadata?
    func findAll() async throws -> [MLModelMetadata]
    func delete(_ type: MLModelType) async throws
}

enum SampleStatus: String, Sendable, CaseIterable {
    case pending
    case inProgress
    case analyzed
    case reviewed
    case archived
}
