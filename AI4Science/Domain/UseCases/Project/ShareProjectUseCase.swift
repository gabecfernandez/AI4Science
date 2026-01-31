import Foundation

/// Use case for sharing project with collaborators
@available(iOS 15.0, *)
public actor ShareProjectUseCase: Sendable {
    private let projectService: any ProjectServiceProtocol

    public init(projectService: any ProjectServiceProtocol) {
        self.projectService = projectService
    }

    /// Share project with collaborators
    /// - Parameters:
    ///   - projectId: Project ID to share
    ///   - emails: Array of collaborator emails
    ///   - permission: Permission level for collaborators
    /// - Throws: ProjectError if sharing fails
    public func execute(
        projectId: String,
        with emails: [String],
        permission: ProjectPermission
    ) async throws {
        guard !projectId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ProjectError.projectNotFound
        }

        try validateEmails(emails)
        guard !emails.isEmpty else {
            throw ProjectError.projectNotFound
        }

        do {
            try await projectService.shareProject(
                projectId: projectId,
                with: emails,
                permission: permission
            )
        } catch let error as ProjectError {
            throw error
        } catch {
            throw ProjectError.unknownError(error.localizedDescription)
        }
    }

    /// Remove collaborator from project
    /// - Parameters:
    ///   - projectId: Project ID
    ///   - email: Collaborator email to remove
    /// - Throws: ProjectError if removal fails
    public func removeCollaborator(projectId: String, email: String) async throws {
        guard !projectId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ProjectError.projectNotFound
        }

        try validateEmail(email)

        do {
            try await projectService.removeCollaborator(projectId: projectId, email: email)
        } catch let error as ProjectError {
            throw error
        } catch {
            throw ProjectError.unknownError(error.localizedDescription)
        }
    }

    private func validateEmail(_ email: String) throws {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard predicate.evaluate(with: email) else {
            throw ProjectError.projectNotFound
        }
    }

    private func validateEmails(_ emails: [String]) throws {
        for email in emails {
            try validateEmail(email)
        }
    }
}
