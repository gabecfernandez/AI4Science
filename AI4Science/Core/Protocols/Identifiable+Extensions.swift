import Foundation

/// Extension to provide default Identifiable implementation
public extension Identifiable {
    /// Get a unique string representation of the identifier
    var idString: String {
        String(describing: id)
    }
}

/// Protocol for entities that can be compared by ID
public protocol IDComparable: Identifiable {
    /// Compare two entities by their IDs
    func isSame(as other: Self) -> Bool
}

public extension IDComparable {
    func isSame(as other: Self) -> Bool {
        self.id == other.id
    }
}

/// Protocol for entities with timestamps
public protocol Timestamped: Sendable {
    var createdAt: Date { get }
    var updatedAt: Date { get }

    var ageInSeconds: TimeInterval { get }
    var isRecent(seconds: TimeInterval) -> Bool { get }
}

public extension Timestamped {
    var ageInSeconds: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }

    func isRecent(seconds: TimeInterval) -> Bool {
        ageInSeconds <= seconds
    }
}

/// Protocol for entities with sync state
public protocol Syncable: Sendable {
    var syncStatus: SyncStatus { get set }

    var isSynced: Bool { get }
    var needsSync: Bool { get }
}

public extension Syncable {
    var isSynced: Bool {
        syncStatus == .synced
    }

    var needsSync: Bool {
        syncStatus == .pending || syncStatus == .failed
    }
}
