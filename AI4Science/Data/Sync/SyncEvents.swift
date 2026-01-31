import Foundation

// MARK: - Sync Event

/// Event representing a sync activity
enum SyncEvent: Sendable {
    case syncStarted
    case itemSynced(entityType: String, itemID: String)
    case itemFailed(entityType: String, itemID: String, error: String)
    case conflictDetected(entityType: String, itemID: String)
    case syncCompleted(itemsSynced: Int)
    case syncFailed(error: String)

    var description: String {
        switch self {
        case .syncStarted:
            return "Sync started"
        case let .itemSynced(type, id):
            return "Synced \(type): \(id)"
        case let .itemFailed(type, id, error):
            return "Failed to sync \(type) \(id): \(error)"
        case let .conflictDetected(type, id):
            return "Conflict detected for \(type): \(id)"
        case let .syncCompleted(count):
            return "Sync completed: \(count) items synced"
        case let .syncFailed(error):
            return "Sync failed: \(error)"
        }
    }
}
