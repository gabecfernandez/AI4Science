import Foundation

public protocol ProjectRepositoryProtocol: Sendable {
    func save(_ project: Project) async throws
    func findById(_ id: UUID) async throws -> Project?
    func findByOwner(_ ownerId: UUID) async throws -> [Project]
    func findByStatus(_ status: ProjectStatus) async throws -> [Project]
    func findAll() async throws -> [Project]
    func search(query: String) async throws -> [Project]
    func delete(_ id: UUID) async throws
}

extension ProjectRepositoryProtocol {
    func findAll() async throws -> [Project] { [] }
    func search(query: String) async throws -> [Project] { [] }
}
