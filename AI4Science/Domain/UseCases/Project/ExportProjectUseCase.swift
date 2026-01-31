import Foundation

public actor ExportProjectUseCase: Sendable {
    private let repository: any ProjectRepositoryProtocol

    public init(repository: any ProjectRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(projectId: UUID, format: ExportFormat) async throws -> Data {
        guard try await repository.findById(projectId) != nil else {
            throw ProjectError.projectNotFound
        }
        // Stub: real export logic TBD
        return Data()
    }
}
