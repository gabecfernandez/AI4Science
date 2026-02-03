import Foundation

/// Use case for fetching user's projects
@available(iOS 15.0, *)
public actor FetchProjectsUseCase: Sendable {
    private let projectService: any ProjectServiceProtocol

    public init(projectService: any ProjectServiceProtocol) {
        self.projectService = projectService
    }

    /// Fetch all projects for user
    /// - Parameter userId: User ID
    /// - Returns: Array of projects
    /// - Throws: ProjectError if fetch fails
    public func execute(userId: String) async throws -> [Project] {
        guard !userId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ProjectError.projectNotFound
        }

        do {
            let responses = try await projectService.fetchProjects(userId: userId)
            let projects = responses.toDomainProjects()
            return projects.sorted { $0.updatedAt > $1.updatedAt }
        } catch let error as ProjectError {
            throw error
        } catch {
            throw ProjectError.unknownError(error.localizedDescription)
        }
    }

    /// Fetch archived projects only
    /// - Parameter userId: User ID
    /// - Returns: Array of archived projects
    /// - Throws: ProjectError if fetch fails
    public func fetchArchived(userId: String) async throws -> [Project] {
        let allProjects = try await execute(userId: userId)
        return allProjects.filter { $0.status == .archived }
    }

    /// Fetch active projects only
    /// - Parameter userId: User ID
    /// - Returns: Array of active projects
    /// - Throws: ProjectError if fetch fails
    public func fetchActive(userId: String) async throws -> [Project] {
        let allProjects = try await execute(userId: userId)
        return allProjects.filter { $0.status != .archived }
    }

    /// Search projects by name or description
    /// - Parameters:
    ///   - userId: User ID
    ///   - query: Search query
    /// - Returns: Filtered array of projects
    /// - Throws: ProjectError if fetch fails
    public func search(userId: String, query: String) async throws -> [Project] {
        let allProjects = try await execute(userId: userId)
        let lowercaseQuery = query.lowercased()

        return allProjects.filter { project in
            project.title.lowercased().contains(lowercaseQuery) ||
            project.description.lowercased().contains(lowercaseQuery)
        }
    }
}
