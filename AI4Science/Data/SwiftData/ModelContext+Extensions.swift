import Foundation
import SwiftData

/// Extensions for ModelContext with convenient helper methods for AI4Science
extension ModelContext {
    /// Save changes with automatic error handling
    /// - Throws: SwiftData or custom save errors
    @MainActor
    func saveWithErrorHandling() throws {
        do {
            try save()
        } catch {
            AppLogger.error("Failed to save model context: \(error.localizedDescription)")
            throw error
        }
    }

    /// Fetch a single entity by ID
    /// - Parameters:
    ///   - type: The entity type to fetch
    ///   - id: The unique identifier
    /// - Returns: The entity if found
    @MainActor
    func fetch<T: PersistentModel & Identifiable>(
        type: T.Type,
        where id: String
    ) throws -> T? {
        let predicate = #Predicate<T> { entity in
            entity.id as? String == id
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try fetch(descriptor).first
    }

    /// Fetch all entities of a type
    /// - Parameters:
    ///   - type: The entity type to fetch
    /// - Returns: Array of entities
    @MainActor
    func fetchAll<T: PersistentModel>(type: T.Type) throws -> [T] {
        let descriptor = FetchDescriptor<T>()
        return try fetch(descriptor)
    }

    /// Delete all entities matching a predicate
    /// - Parameters:
    ///   - type: The entity type
    ///   - predicate: Fetch predicate for matching entities
    @MainActor
    func deleteAll<T: PersistentModel>(
        type: T.Type,
        where predicate: Predicate<T>
    ) throws {
        let descriptor = FetchDescriptor(predicate: predicate)
        let entities = try fetch(descriptor)
        for entity in entities {
            delete(entity)
        }
        try save()
    }

    /// Count entities matching a predicate
    /// - Parameters:
    ///   - type: The entity type
    ///   - predicate: Fetch predicate (optional)
    /// - Returns: Count of matching entities
    @MainActor
    func count<T: PersistentModel>(
        type: T.Type,
        where predicate: Predicate<T>? = nil
    ) throws -> Int {
        if let predicate = predicate {
            let descriptor = FetchDescriptor(predicate: predicate)
            return try fetchCount(descriptor)
        } else {
            let descriptor = FetchDescriptor<T>()
            return try fetchCount(descriptor)
        }
    }

    /// Insert and save multiple entities
    /// - Parameter entities: Array of entities to insert
    @MainActor
    func insertAndSave<T: PersistentModel>(_ entities: [T]) throws {
        for entity in entities {
            insert(entity)
        }
        try save()
    }

    /// Delete entity by ID
    /// - Parameters:
    ///   - type: The entity type
    ///   - id: The unique identifier
    @MainActor
    func deleteByID<T: PersistentModel & Identifiable>(
        type: T.Type,
        id: String
    ) throws {
        let predicate = #Predicate<T> { entity in
            entity.id as? String == id
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        if let entity = try fetch(descriptor).first {
            delete(entity)
            try save()
        }
    }

    /// Perform a transaction with automatic save
    /// - Parameter block: Transaction block
    @MainActor
    func transaction<T>(_ block: @escaping () throws -> T) throws -> T {
        let result = try block()
        try save()
        return result
    }

    /// Get the transaction author/context
    @MainActor
    var transactionAuthor: String? {
        get {
            self.undoManager?.undoActionName
        }
        set {
            if let author = newValue {
                self.undoManager?.setActionName(author)
            }
        }
    }
}

// Note: Logging is handled by AppLogger in Core/Utilities/Logger.swift

// MARK: - Helper Protocols

/// Protocol for entities with standard ID field
protocol IDProvider {
    var id: String { get }
}

/// Protocol for trackable entities
protocol SyncTrackable {
    var syncStatus: String { get set }
    var updatedAt: Date { get set }
}

/// Protocol for versioned entities
protocol Versioned {
    var version: Int { get set }
}
