import Foundation

public actor FetchProjectsUseCase: Sendable {
    private let repository: any ProjectRepositoryProtocol

    public init(repository: any ProjectRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(ownerId: UUID) async throws -> [Project] {
        try await repository.findByOwner(ownerId)
    }

    public func fetchArchived(ownerId: UUID) async throws -> [Project] {
        let projects = try await repository.findByOwner(ownerId)
        return projects.filter { $0.isArchived }
    }

    public func fetchActive(ownerId: UUID) async throws -> [Project] {
        let projects = try await repository.findByOwner(ownerId)
        return projects.filter { !$0.isArchived }
    }

    public func search(ownerId: UUID, query: String) async throws -> [Project] {
        let projects = try await repository.findByOwner(ownerId)
        let lower = query.lowercased()
        return projects.filter {
            $0.name.lowercased().contains(lower) ||
            $0.description.lowercased().contains(lower)
        }
    }
}
