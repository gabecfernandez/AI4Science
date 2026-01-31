import Foundation

/// Generic error type for repository operations
public enum RepositoryError: LocalizedError, Sendable {
    case notFound
    case alreadyExists
    case invalidData
    case saveFailed(Error?)
    case deleteFailed(Error?)
    case fetchFailed(Error?)
    case syncFailed(Error?)

    public var errorDescription: String? {
        switch self {
        case .notFound:
            return "Entity not found"
        case .alreadyExists:
            return "Entity already exists"
        case .invalidData:
            return "Invalid data provided"
        case .saveFailed:
            return "Failed to save entity"
        case .deleteFailed:
            return "Failed to delete entity"
        case .fetchFailed:
            return "Failed to fetch entity"
        case .syncFailed:
            return "Failed to sync data"
        }
    }
}

/// Generic repository protocol with CRUD operations
public protocol Repository<Entity>: Sendable {
    associatedtype Entity: Identifiable where Entity.ID == UUID

    /// Fetch entity by ID
    func read(id: UUID) async throws -> Entity

    /// Fetch all entities
    func readAll() async throws -> [Entity]

    /// Fetch entities matching predicate
    func readWhere(predicate: @escaping (Entity) -> Bool) async throws -> [Entity]

    /// Create a new entity
    func create(_ entity: Entity) async throws

    /// Update existing entity
    func update(_ entity: Entity) async throws

    /// Delete entity by ID
    func delete(id: UUID) async throws

    /// Delete all entities matching predicate
    func deleteWhere(predicate: @escaping (Entity) -> Bool) async throws

    /// Check if entity exists
    func exists(id: UUID) async throws -> Bool

    /// Count entities
    func count() async throws -> Int

    /// Batch operations
    func createBatch(_ entities: [Entity]) async throws

    /// Clear all data
    func clear() async throws
}
