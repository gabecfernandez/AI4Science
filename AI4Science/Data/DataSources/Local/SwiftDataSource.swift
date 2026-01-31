import Foundation
import SwiftData

/// Generic SwiftData data source for repository operations
actor SwiftDataSource<T: PersistentModel & Identifiable> {
    // MARK: - Properties

    private let modelContainer: ModelContainer

    // MARK: - Initialization

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Public Methods

    /// Fetch all entities
    /// - Returns: Array of entities
    func fetchAll() async throws -> [T] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<T>()
        return try context.fetch(descriptor)
    }

    /// Fetch entity by ID
    /// - Parameter id: Entity ID
    /// - Returns: Entity or nil if not found
    func fetch(id: String) async throws -> T? {
        let context = ModelContext(modelContainer)
        let predicate = #Predicate<T> { entity in
            entity.id as? String == id
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try context.fetch(descriptor).first
    }

    /// Fetch entities with predicate
    /// - Parameter predicate: Fetch predicate
    /// - Returns: Array of matching entities
    func fetch(where predicate: Predicate<T>) async throws -> [T] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor(predicate: predicate)
        return try context.fetch(descriptor)
    }

    /// Insert entity
    /// - Parameter entity: Entity to insert
    func insert(_ entity: T) async throws {
        let context = ModelContext(modelContainer)
        context.insert(entity)
        try context.save()
    }

    /// Insert multiple entities
    /// - Parameter entities: Array of entities
    func insert(_ entities: [T]) async throws {
        let context = ModelContext(modelContainer)
        for entity in entities {
            context.insert(entity)
        }
        try context.save()
    }

    /// Update entity
    /// - Parameter entity: Entity to update
    func update(_ entity: T) async throws {
        let context = ModelContext(modelContainer)
        // Entity is already attached to context if fetched from this source
        try context.save()
    }

    /// Delete entity
    /// - Parameter entity: Entity to delete
    func delete(_ entity: T) async throws {
        let context = ModelContext(modelContainer)
        context.delete(entity)
        try context.save()
    }

    /// Delete entity by ID
    /// - Parameter id: Entity ID
    func delete(id: String) async throws {
        let context = ModelContext(modelContainer)
        let predicate = #Predicate<T> { entity in
            entity.id as? String == id
        }
        let descriptor = FetchDescriptor(predicate: predicate)

        if let entity = try context.fetch(descriptor).first {
            context.delete(entity)
            try context.save()
        }
    }

    /// Delete entities matching predicate
    /// - Parameter predicate: Fetch predicate
    func delete(where predicate: Predicate<T>) async throws {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor(predicate: predicate)
        let entities = try context.fetch(descriptor)

        for entity in entities {
            context.delete(entity)
        }

        try context.save()
    }

    /// Count all entities
    /// - Returns: Count of entities
    func count() async throws -> Int {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<T>()
        return try context.fetchCount(descriptor)
    }

    /// Count entities matching predicate
    /// - Parameter predicate: Fetch predicate
    /// - Returns: Count of matching entities
    func count(where predicate: Predicate<T>) async throws -> Int {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor(predicate: predicate)
        return try context.fetchCount(descriptor)
    }

    /// Check if entity exists
    /// - Parameter id: Entity ID
    /// - Returns: True if exists
    func exists(id: String) async throws -> Bool {
        let context = ModelContext(modelContainer)
        let predicate = #Predicate<T> { entity in
            entity.id as? String == id
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try context.fetchCount(descriptor) > 0
    }

    /// Clear all entities (use with caution)
    func clear() async throws {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<T>()
        let all = try context.fetch(descriptor)

        for entity in all {
            context.delete(entity)
        }

        try context.save()
    }

    /// Perform batch operation
    /// - Parameter block: Batch operation block
    func batch(_ block: @escaping (ModelContext) async throws -> Void) async throws {
        let context = ModelContext(modelContainer)
        try await block(context)
        try context.save()
    }
}

