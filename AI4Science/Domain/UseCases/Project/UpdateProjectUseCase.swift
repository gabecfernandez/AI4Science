import Foundation

/// Use case for updating project details
@available(iOS 15.0, *)
public actor UpdateProjectUseCase: Sendable {
    private let projectService: any ProjectServiceProtocol

    public init(projectService: any ProjectServiceProtocol) {
        self.projectService = projectService
    }

    /// Execute project update
    /// - Parameters:
    ///   - projectId: Project ID to update
    ///   - name: New project name (optional)
    ///   - description: New project description (optional)
    ///   - isArchived: Archive status (optional)
    /// - Returns: Updated project
    /// - Throws: ProjectError if update fails
    public func execute(
        projectId: String,
        name: String? = nil,
        description: String? = nil,
        isArchived: Bool? = nil
    ) async throws -> Project {
        guard !projectId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ProjectError.projectNotFound
        }

        // Validate provided values
        if let name = name {
            try validateName(name)
        }

        if let description = description {
            try validateDescription(description)
        }

        let request = UpdateProjectRequest(
            projectId: projectId,
            name: name,
            description: description,
            isArchived: isArchived
        )

        do {
            let response = try await projectService.updateProject(request)
            return response.toDomainProject()
        } catch let error as ProjectError {
            throw error
        } catch {
            throw ProjectError.unknownError(error.localizedDescription)
        }
    }

    /// Archive project
    /// - Parameter projectId: Project ID to archive
    /// - Returns: Updated project
    /// - Throws: ProjectError if archiving fails
    public func archive(projectId: String) async throws -> Project {
        return try await execute(projectId: projectId, isArchived: true)
    }

    /// Unarchive project
    /// - Parameter projectId: Project ID to unarchive
    /// - Returns: Updated project
    /// - Throws: ProjectError if unarchiving fails
    public func unarchive(projectId: String) async throws -> Project {
        return try await execute(projectId: projectId, isArchived: false)
    }

    private func validateName(_ name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty && trimmed.count >= 3 && trimmed.count <= 100 else {
            throw ProjectError.invalidName
        }
    }

    private func validateDescription(_ description: String) throws {
        guard description.count <= 5000 else {
            throw ProjectError.invalidName
        }
    }
}
