import Foundation
import SwiftData

/// Sync Queue persistence model for SwiftData
/// Manages offline operations that need to be synced when connectivity is restored
@Model
final class SyncQueueEntity {
    /// Unique identifier for the queue entry
    @Attribute(.unique) var id: String

    /// Type of operation (create, update, delete)
    var operationType: String

    /// Entity type being synced (user, project, sample, capture, etc.)
    var entityType: String

    /// ID of the entity being synced
    var entityID: String

    /// Operation data (JSON)
    var operationData: String

    /// Sync status
    var status: String = "pending"

    /// Number of retry attempts
    var retryCount: Int = 0

    /// Maximum retry attempts
    var maxRetries: Int = 3

    /// Timestamp when added to queue
    var enqueuedAt: Date

    /// Last attempted timestamp
    var lastAttemptedAt: Date?

    /// Timestamp when synced
    var syncedAt: Date?

    /// Error message if sync failed
    var errorMessage: String?

    /// Priority level (0-10, higher = more important)
    var priority: Int = 5

    /// Device that created this queue entry
    var deviceID: String?

    /// Whether operation requires network
    var requiresNetwork: Bool = true

    /// Whether operation is critical
    var isCritical: Bool = false

    /// Additional metadata
    var metadata: [String: String] = [:]

    /// Initialization
    init(
        id: String,
        operationType: String,
        entityType: String,
        entityID: String,
        operationData: String,
        enqueuedAt: Date = Date()
    ) {
        self.id = id
        self.operationType = operationType
        self.entityType = entityType
        self.entityID = entityID
        self.operationData = operationData
        self.enqueuedAt = enqueuedAt
    }

    /// Mark as pending
    @MainActor
    func markPending() {
        self.status = "pending"
    }

    /// Mark as in progress
    @MainActor
    func markInProgress() {
        self.status = "in_progress"
        self.lastAttemptedAt = Date()
    }

    /// Mark as synced
    @MainActor
    func markSynced() {
        self.status = "synced"
        self.syncedAt = Date()
        self.errorMessage = nil
    }

    /// Mark as failed with retry
    @MainActor
    func markFailedWithRetry(errorMessage: String) {
        self.retryCount += 1
        self.errorMessage = errorMessage

        if retryCount >= maxRetries {
            self.status = "failed"
        } else {
            self.status = "pending_retry"
        }
    }

    /// Mark as permanently failed
    @MainActor
    func markFailed(errorMessage: String) {
        self.status = "failed"
        self.errorMessage = errorMessage
        self.retryCount = maxRetries
    }

    /// Reset retry count
    @MainActor
    func resetRetry() {
        self.retryCount = 0
        self.errorMessage = nil
        self.status = "pending"
    }

    /// Check if should retry
    nonisolated var shouldRetry: Bool {
        status == "pending_retry" && retryCount < maxRetries
    }

    /// Get retry wait time in seconds (exponential backoff)
    @MainActor
    var retryWaitTime: TimeInterval {
        pow(2.0, Double(retryCount)) * 60.0 // 1 min, 2 min, 4 min, etc.
    }

    /// Check if entry is expired (24 hours)
    @MainActor
    var isExpired: Bool {
        Date().timeIntervalSince(enqueuedAt) > 86400
    }
}
