import Foundation

/// Use case for creating a new research project
@available(iOS 15.0, *)
public actor CreateProjectUseCase: Sendable {
    private let projectService: any ProjectServiceProtocol

    public init(projectService: any ProjectServiceProtocol) {
        self.projectService = projectService
    }

    /// Execute project creation
    /// - Parameters:
    ///   - name: Project name
    ///   - description: Project description
    /// - Returns: Created project
    /// - Throws: ProjectError if creation fails
    public func execute(name: String, description: String) async throws -> Project {
        try validateInput(name: name, description: description)

        let request = CreateProjectRequest(name: name, description: description)

        do {
            let project = try await projectService.createProject(request)
            return project
        } catch let error as ProjectError {
            throw error
        } catch {
            throw ProjectError.unknownError(error.localizedDescription)
        }
    }

    /// Validate project input
    private func validateInput(name: String, description: String) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            throw ProjectError.invalidName
        }

        guard trimmedName.count >= 3 && trimmedName.count <= 100 else {
            throw ProjectError.invalidName
        }

        guard description.count <= 5000 else {
            throw ProjectError.invalidName
        }
    }
}
