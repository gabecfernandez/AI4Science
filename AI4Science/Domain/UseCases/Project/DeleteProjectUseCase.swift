import Foundation

/// Use case for deleting project with cleanup
@available(iOS 15.0, *)
public actor DeleteProjectUseCase: Sendable {
    private let projectService: any ProjectServiceProtocol

    public init(projectService: any ProjectServiceProtocol) {
        self.projectService = projectService
    }

    /// Execute project deletion
    /// - Parameter projectId: Project ID to delete
    /// - Throws: ProjectError if deletion fails
    public func execute(projectId: String) async throws {
        guard !projectId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ProjectError.projectNotFound
        }

        do {
            try await projectService.deleteProject(projectId: projectId)
        } catch let error as ProjectError {
            throw error
        } catch {
            throw ProjectError.unknownError(error.localizedDescription)
        }
    }
}
