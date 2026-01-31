import Foundation

public actor ShareProjectUseCase: Sendable {
    private let repository: any ProjectRepositoryProtocol

    public init(repository: any ProjectRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(
        projectId: UUID,
        with emails: [String],
        permission: ProjectPermission
    ) async throws {
        guard try await repository.findById(projectId) != nil else {
            throw ProjectError.projectNotFound
        }
        // Stub: real sharing logic TBD
    }

    public func removeCollaborator(projectId: UUID, email: String) async throws {
        guard try await repository.findById(projectId) != nil else {
            throw ProjectError.projectNotFound
        }
        // Stub: real removal logic TBD
    }
}
