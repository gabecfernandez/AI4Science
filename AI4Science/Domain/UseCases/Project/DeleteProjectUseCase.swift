import Foundation

public actor DeleteProjectUseCase: Sendable {
    private let repository: any ProjectRepositoryProtocol

    public init(repository: any ProjectRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(projectId: UUID) async throws {
        try await repository.delete(projectId)
    }
}
