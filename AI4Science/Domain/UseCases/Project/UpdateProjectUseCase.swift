import Foundation

public actor UpdateProjectUseCase: Sendable {
    private let repository: any ProjectRepositoryProtocol

    public init(repository: any ProjectRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ request: UpdateProjectRequest) async throws -> Project {
        guard var project = try await repository.findById(request.projectId) else {
            throw ProjectError.projectNotFound
        }

        if let name = request.name {
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, trimmed.count >= 3, trimmed.count <= 100 else {
                throw ProjectError.invalidName
            }
            project.name = trimmed
        }

        if let description = request.description {
            project.description = description
        }

        project.updatedAt = Date()
        try await repository.save(project)
        return project
    }
}
