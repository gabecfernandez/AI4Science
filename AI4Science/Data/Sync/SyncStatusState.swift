import Foundation

/// Data structure tracking synchronization state info
struct SyncStatusInfo: Sendable {
    // MARK: - Properties

    /// Whether a sync is currently in progress
    let isSyncing: Bool

    /// Timestamp of last successful sync
    let lastSyncTime: Date?

    /// Number of pending items in sync queue
    let pendingItemsCount: Int

    // MARK: - Computed Properties

    /// Human-readable sync status
    var statusText: String {
        if isSyncing {
            return "Syncing..."
        } else if let lastSync = lastSyncTime {
            let formatter = RelativeDateTimeFormatter()
            return "Last synced \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
        } else {
            return "Never synced"
        }
    }

    /// Whether sync is needed
    var needsSync: Bool {
        pendingItemsCount > 0
    }

    /// Sync progress indication
    var progressIndicator: String {
        if isSyncing {
            return "🔄 Syncing"
        } else if needsSync {
            return "⏳ \(pendingItemsCount) pending"
        } else {
            return "✅ All synced"
        }
    }

    /// Time since last sync
    var timeSinceLastSync: TimeInterval? {
        guard let lastSync = lastSyncTime else { return nil }
        return Date().timeIntervalSince(lastSync)
    }

    /// Whether sync data is stale (older than 1 hour)
    var isStale: Bool {
        guard let lastSync = lastSyncTime else { return true }
        return Date().timeIntervalSince(lastSync) > 3600 // 1 hour
    }

    // MARK: - Methods

    /// Create JSON representation
    func toJSON() -> [String: Any]? {
        var json: [String: Any] = [
            "isSyncing": isSyncing,
            "pendingItemsCount": pendingItemsCount,
            "statusText": statusText,
        ]

        if let lastSync = lastSyncTime {
            json["lastSyncTime"] = ISO8601DateFormatter().string(from: lastSync)
        }

        return json
    }

    /// Create readable description
    var description: String {
        var desc = "SyncStatusInfo {\n"
        desc += "  isSyncing: \(isSyncing)\n"
        desc += "  lastSyncTime: \(lastSyncTime?.description ?? "nil")\n"
        desc += "  pendingItemsCount: \(pendingItemsCount)\n"
        desc += "  statusText: \(statusText)\n"
        desc += "  needsSync: \(needsSync)\n"
        desc += "}"
        return desc
    }
}

// MARK: - Sync Result

/// Result of a sync operation
struct SyncOperationResult: Sendable {
    /// Whether sync was successful
    let success: Bool

    /// Error message if sync failed
    let error: String?

    /// Number of items synced
    let itemsSynced: Int

    /// Timestamp of sync
    let syncTime: Date

    /// Duration of sync
    var duration: TimeInterval {
        Date().timeIntervalSince(syncTime)
    }

    // MARK: - Initialization

    nonisolated init(
        success: Bool,
        error: String? = nil,
        itemsSynced: Int = 0,
        syncTime: Date = Date()
    ) {
        self.success = success
        self.error = error
        self.itemsSynced = itemsSynced
        self.syncTime = syncTime
    }

    // MARK: - Methods

    /// Create JSON representation
    func toJSON() -> [String: Any] {
        return [
            "success": success,
            "error": error ?? NSNull(),
            "itemsSynced": itemsSynced,
            "syncTime": ISO8601DateFormatter().string(from: syncTime),
            "duration": duration,
        ]
    }

    var description: String {
        let status = success ? "✅ SUCCESS" : "❌ FAILED"
        var desc = "\(status) - \(itemsSynced) items synced"
        if let error = error {
            desc += " - Error: \(error)"
        }
        return desc
    }
}

// MARK: - Sync Event

/// Event representing a sync activity
enum SyncEvent: Sendable {
    case syncStarted
    case itemSynced(entityType: String, itemID: String)
    case itemFailed(entityType: String, itemID: String, error: String)
    case conflictDetected(entityType: String, itemID: String)
    case syncCompleted(result: SyncOperationResult)
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
        case let .syncCompleted(result):
            return "Sync completed: \(result.description)"
        case let .syncFailed(error):
            return "Sync failed: \(error)"
        }
    }
}
