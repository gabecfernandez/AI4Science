import Foundation
import SwiftData

/// Sync metadata persistence model for SwiftData
/// Tracks synchronization status for each entity type
@Model
final class SyncMetadataEntity {
    /// Unique identifier for the sync metadata
    @Attribute(.unique) var id: String

    /// Entity type being tracked (user, project, sample, capture, annotation, defect, etc.)
    var entityType: String

    /// ID of the entity
    var entityID: String

    /// Current sync status (pending, syncing, synced, failed)
    var syncStatus: String

    /// Last attempted sync time
    var lastSyncAttempt: Date?

    /// Last successful sync time
    var lastSyncSuccess: Date?

    /// Sync error message (if failed)
    var syncError: String?

    /// Number of sync attempts
    var syncAttempts: Int = 0

    /// Maximum sync attempts allowed
    var maxSyncAttempts: Int = 5

    /// Remote version/timestamp from server
    var remoteVersion: String?

    /// Local version/timestamp
    var localVersion: String?

    /// Whether conflict detected
    var hasConflict: Bool = false

    /// Conflict resolution strategy (client_wins, server_wins, merge)
    var conflictResolution: String?

    /// Creation timestamp
    var createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    /// Device ID that initiated sync
    var deviceID: String?

    /// User ID associated with sync
    var userID: String?

    /// Sync batch ID for grouping related syncs
    var batchID: String?

    /// Additional sync metadata
    var metadata: [String: String] = [:]

    /// Whether this is a critical sync
    var isCritical: Bool = false

    /// Initialization
    init(
        id: String = UUID().uuidString,
        entityType: String,
        entityID: String,
        syncStatus: String = "pending"
    ) {
        self.id = id
        self.entityType = entityType
        self.entityID = entityID
        self.syncStatus = syncStatus
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Mark sync as started
    @MainActor
    func markSyncStarted() {
        self.syncStatus = "syncing"
        self.lastSyncAttempt = Date()
        self.syncAttempts += 1
        self.updatedAt = Date()
    }

    /// Mark sync as successful
    @MainActor
    func markSyncSuccess(remoteVersion: String? = nil, localVersion: String? = nil) {
        self.syncStatus = "synced"
        self.lastSyncSuccess = Date()
        self.syncError = nil
        self.hasConflict = false
        self.syncAttempts = 0

        if let remoteVersion = remoteVersion {
            self.remoteVersion = remoteVersion
        }
        if let localVersion = localVersion {
            self.localVersion = localVersion
        }

        self.updatedAt = Date()
    }

    /// Mark sync as failed
    @MainActor
    func markSyncFailed(error: String) {
        self.syncError = error

        if syncAttempts >= maxSyncAttempts {
            self.syncStatus = "failed"
        } else {
            self.syncStatus = "pending"
        }

        self.updatedAt = Date()
    }

    /// Mark conflict detected
    @MainActor
    func markConflictDetected(
        remoteVersion: String? = nil,
        localVersion: String? = nil,
        resolution: String = "client_wins"
    ) {
        self.hasConflict = true
        self.conflictResolution = resolution

        if let remoteVersion = remoteVersion {
            self.remoteVersion = remoteVersion
        }
        if let localVersion = localVersion {
            self.localVersion = localVersion
        }

        self.syncStatus = "pending"
        self.updatedAt = Date()
    }

    /// Reset sync state
    @MainActor
    func resetSync() {
        self.syncStatus = "pending"
        self.syncAttempts = 0
        self.syncError = nil
        self.hasConflict = false
        self.updatedAt = Date()
    }

    /// Add sync metadata
    @MainActor
    func addMetadata(key: String, value: String) {
        metadata[key] = value
        self.updatedAt = Date()
    }

    /// Check if sync should be retried
    nonisolated var shouldRetry: Bool {
        (syncStatus == "pending" || syncStatus == "failed") && syncAttempts < maxSyncAttempts
    }

    /// Get retry wait time in seconds (exponential backoff)
    nonisolated var retryWaitTime: TimeInterval {
        pow(2.0, Double(syncAttempts)) * 10.0 // 10s, 20s, 40s, etc.
    }

    /// Check if sync is stale (longer than 24 hours)
    @MainActor
    var isStale: Bool {
        guard let lastSync = lastSyncSuccess ?? lastSyncAttempt else {
            return false
        }
        return Date().timeIntervalSince(lastSync) > 86400
    }

    /// Get sync status as human-readable text
    nonisolated var statusDescription: String {
        switch syncStatus {
        case "pending":
            return "Pending"
        case "syncing":
            return "Syncing..."
        case "synced":
            return "Synced"
        case "failed":
            return "Sync Failed"
        default:
            return "Unknown"
        }
    }
}
