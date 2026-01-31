import Foundation

public actor CreateProjectUseCase: Sendable {
    private let repository: any ProjectRepositoryProtocol

    public init(repository: any ProjectRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ request: CreateProjectRequest) async throws -> Project {
        let trimmedName = request.name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, trimmedName.count >= 3 else {
            throw ValidationError(message: "Project name must be at least 3 characters")
        }
        guard trimmedName.count <= 100 else {
            throw ValidationError(message: "Project name must be 100 characters or fewer")
        }

        let now = Date()
        let project = Project(
            id: UUID(),
            name: trimmedName,
            description: request.description,
            ownerId: request.ownerId,
            status: .draft,
            createdAt: now,
            updatedAt: now
        )

        try await repository.save(project)
        return project
    }
}
