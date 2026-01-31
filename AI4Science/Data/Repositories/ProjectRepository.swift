import Foundation
import SwiftData

/// Protocol for project operations
protocol ProjectRepositoryProtocol: Sendable {
    // Entity-based operations
    func createProject(_ project: ProjectEntity) async throws
    func getProject(id: String) async throws -> ProjectEntity?
    func getProjectsByOwner(userID: String) async throws -> [ProjectEntity]
    func updateProject(_ project: ProjectEntity) async throws
    func deleteProject(id: String) async throws
    func getAllProjects() async throws -> [ProjectEntity]
    func searchProjects(query: String) async throws -> [ProjectEntity]
    func getProjectsByStatus(_ status: String) async throws -> [ProjectEntity]
    func archiveProject(id: String) async throws
    func unarchiveProject(id: String) async throws

    // Domain model operations
    func save(_ project: Project) async throws
    func findById(_ id: UUID) async throws -> Project?
    func findAll() async throws -> [Project]
    func update(_ project: Project) async throws
    func delete(_ id: UUID) async throws
    func search(query: String) async throws -> [Project]
    func filterByStatus(_ status: ProjectStatus) async throws -> [Project]
}

/// Project repository implementation
actor ProjectRepository: ProjectRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Domain Model Operations

    /// Save a new domain Project
    func save(_ project: Project) async throws {
        let entity = ProjectMapper.toEntity(from: project)
        modelContext.insert(entity)
        try modelContext.save()
    }

    /// Find project by UUID
    func findById(_ id: UUID) async throws -> Project? {
        let idString = id.uuidString
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { $0.id == idString }
        )
        guard let entity = try modelContext.fetch(descriptor).first else {
            return nil
        }
        return ProjectMapper.toDomain(entity)
    }

    /// Find all projects as domain models
    func findAll() async throws -> [Project] {
        let descriptor = FetchDescriptor<ProjectEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map { ProjectMapper.toDomain($0) }
    }

    /// Update an existing domain Project
    func update(_ project: Project) async throws {
        let idString = project.id.uuidString
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { $0.id == idString }
        )
        guard let entity = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        ProjectMapper.update(entity, with: project)
        try modelContext.save()
    }

    /// Delete project by UUID
    func delete(_ id: UUID) async throws {
        let idString = id.uuidString
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { $0.id == idString }
        )
        guard let entity = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        modelContext.delete(entity)
        try modelContext.save()
    }

    /// Search projects by title or description
    func search(query: String) async throws -> [Project] {
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { project in
                project.name.localizedStandardContains(query) ||
                project.description.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map { ProjectMapper.toDomain($0) }
    }

    /// Filter projects by status
    func filterByStatus(_ status: ProjectStatus) async throws -> [Project] {
        let statusString = status.rawValue
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { $0.status == statusString },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map { ProjectMapper.toDomain($0) }
    }

    // MARK: - Entity-based Operations (Legacy)

    /// Create a new project
    func createProject(_ project: ProjectEntity) async throws {
        modelContext.insert(project)
        try modelContext.save()
    }

    /// Get project by ID
    func getProject(id: String) async throws -> ProjectEntity? {
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Get projects by owner
    func getProjectsByOwner(userID: String) async throws -> [ProjectEntity] {
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { project in
                project.owner?.id == userID
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Update project
    func updateProject(_ project: ProjectEntity) async throws {
        project.updatedAt = Date()
        try modelContext.save()
    }

    /// Delete project
    func deleteProject(id: String) async throws {
        guard let project = try await getProject(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(project)
        try modelContext.save()
    }

    /// Get all projects
    func getAllProjects() async throws -> [ProjectEntity] {
        let descriptor = FetchDescriptor<ProjectEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Search projects by name or description
    func searchProjects(query: String) async throws -> [ProjectEntity] {
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { project in
                project.name.localizedStandardContains(query) ||
                project.description.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get projects by status
    func getProjectsByStatus(_ status: String) async throws -> [ProjectEntity] {
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { $0.status == status },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Archive a project
    func archiveProject(id: String) async throws {
        guard let project = try await getProject(id: id) else {
            throw RepositoryError.notFound
        }
        project.status = ProjectStatus.archived.rawValue
        project.updatedAt = Date()
        try modelContext.save()
    }

    /// Unarchive a project
    func unarchiveProject(id: String) async throws {
        guard let project = try await getProject(id: id) else {
            throw RepositoryError.notFound
        }
        project.status = ProjectStatus.active.rawValue
        project.updatedAt = Date()
        try modelContext.save()
    }
}

/// Factory for creating project repository
struct ProjectRepositoryFactory {
    static func makeRepository(modelContext: ModelContext) -> ProjectRepository {
        ProjectRepository(modelContext: modelContext)
    }

    static func makeRepository(modelContainer: ModelContainer) -> ProjectRepository {
        let context = ModelContext(modelContainer)
        return ProjectRepository(modelContext: context)
    }
}
