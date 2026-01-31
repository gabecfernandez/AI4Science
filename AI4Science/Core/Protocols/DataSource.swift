import Foundation

/// Protocol for remote data source operations
public protocol RemoteDataSource<Entity>: Sendable {
    associatedtype Entity: Identifiable where Entity.ID == UUID

    func fetch(id: UUID) async throws -> Entity
    func fetchAll() async throws -> [Entity]
    func fetchPage(number: Int, pageSize: Int) async throws -> Page<Entity>
    func create(_ entity: Entity) async throws -> Entity
    func update(_ entity: Entity) async throws -> Entity
    func delete(id: UUID) async throws
    func search(query: String) async throws -> [Entity]
}

/// Represents a page of entities for pagination
public struct Page<Entity>: Sendable {
    public let content: [Entity]
    public let number: Int
    public let size: Int
    public let totalElements: Int
    public let totalPages: Int

    public init(
        content: [Entity],
        number: Int,
        size: Int,
        totalElements: Int,
        totalPages: Int
    ) {
        self.content = content
        self.number = number
        self.size = size
        self.totalElements = totalElements
        self.totalPages = totalPages
    }

    public var hasNext: Bool {
        number < (totalPages - 1)
    }

    public var hasPrevious: Bool {
        number > 0
    }
}
