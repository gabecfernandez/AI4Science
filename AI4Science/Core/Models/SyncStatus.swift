import Foundation

/// Sync status for data entities
@frozen
public enum SyncStatus: String, Sendable, Codable, Hashable, CaseIterable {
    case pending
    case syncing
    case synced
    case failed
    case conflict

    // MARK: - Helpers
    public var isPending: Bool {
        self == .pending
    }

    public var isSyncing: Bool {
        self == .syncing
    }

    public var isSynced: Bool {
        self == .synced
    }

    public var isFailed: Bool {
        self == .failed
    }

    public var needsSync: Bool {
        self == .pending || self == .failed
    }
}
