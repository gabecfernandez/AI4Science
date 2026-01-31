import Foundation
import SwiftData

actor ProjectRepository: ProjectRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ project: Project) async throws {
        let idStr = project.id.uuidString
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { $0.id == idStr }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.name = project.name
            existing.projectDescription = project.description
            existing.ownerId = project.ownerId.uuidString
            existing.status = project.status.rawValue
            existing.sampleIds = project.sampleIds.map { $0.uuidString }
            existing.collaboratorIds = project.collaboratorIds.map { $0.uuidString }
            existing.updatedAt = project.updatedAt
        } else {
            let entity = ProjectMapper.toEntity(from: project)
            modelContext.insert(entity)
        }
        try modelContext.save()
    }

    func findById(_ id: UUID) async throws -> Project? {
        let idStr = id.uuidString
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { $0.id == idStr }
        )
        guard let entity = try modelContext.fetch(descriptor).first else { return nil }
        return ProjectMapper.toModel(from: entity)
    }

    func findByOwner(_ ownerId: UUID) async throws -> [Project] {
        let ownerStr = ownerId.uuidString
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { $0.ownerId == ownerStr },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { ProjectMapper.toModel(from: $0) }
    }

    func findByStatus(_ status: ProjectStatus) async throws -> [Project] {
        let statusStr = status.rawValue
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { $0.status == statusStr },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { ProjectMapper.toModel(from: $0) }
    }

    func findAll() async throws -> [Project] {
        let descriptor = FetchDescriptor<ProjectEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { ProjectMapper.toModel(from: $0) }
    }

    func search(query: String) async throws -> [Project] {
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { entity in
                entity.name.localizedCaseInsensitiveContains(query) ||
                entity.projectDescription.localizedCaseInsensitiveContains(query)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { ProjectMapper.toModel(from: $0) }
    }

    func delete(_ id: UUID) async throws {
        let idStr = id.uuidString
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { $0.id == idStr }
        )
        guard let entity = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        modelContext.delete(entity)
        try modelContext.save()
    }
}
