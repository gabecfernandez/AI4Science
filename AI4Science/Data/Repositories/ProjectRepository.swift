import Foundation
import SwiftData

/// Protocol for project operations
protocol ProjectRepositoryProtocol: Sendable {
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
}

/// Project repository implementation
actor ProjectRepository: ProjectRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

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
        guard let project = try getProject(id: id) else {
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
        let lowercaseQuery = query.lowercased()
        let descriptor = FetchDescriptor<ProjectEntity>(
            predicate: #Predicate { project in
                project.name.localizedCaseInsensitiveContains(lowercaseQuery) ||
                project.description.localizedCaseInsensitiveContains(lowercaseQuery)
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
        guard let project = try getProject(id: id) else {
            throw RepositoryError.notFound
        }
        project.archive()
        try modelContext.save()
    }

    /// Unarchive a project
    func unarchiveProject(id: String) async throws {
        guard let project = try getProject(id: id) else {
            throw RepositoryError.notFound
        }
        project.unarchive()
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
