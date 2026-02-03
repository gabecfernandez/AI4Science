import Foundation

/// Sync direction
@frozen
public enum SyncDirection: String, Sendable, Codable, Hashable {
    case upload
    case download
    case bidirectional
}

/// Sync error types
@frozen
public enum SyncServiceErrorType: String, Sendable, Codable, Hashable {
    case networkUnavailable
    case conflictDetected
    case invalidData
    case storageExceeded
    case authenticationRequired
    case unknown
}

/// Sync operation result
public struct SyncOperation: Sendable, Codable, Hashable, Identifiable {
    public let id: UUID
    public let entityType: String
    public let entityId: UUID
    public let direction: SyncDirection
    public let status: SyncStatus
    public let error: SyncServiceErrorType?
    public let timestamp: Date
    public var retryCount: Int

    public init(
        id: UUID = UUID(),
        entityType: String,
        entityId: UUID,
        direction: SyncDirection,
        status: SyncStatus = .pending,
        error: SyncServiceErrorType? = nil,
        timestamp: Date = Date(),
        retryCount: Int = 0
    ) {
        self.id = id
        self.entityType = entityType
        self.entityId = entityId
        self.direction = direction
        self.status = status
        self.error = error
        self.timestamp = timestamp
        self.retryCount = retryCount
    }
}

/// Protocol for offline sync operations
public protocol OfflineSyncService: Sendable {
    /// Sync all pending changes
    /// - Parameter direction: Direction of sync
    func syncAll(direction: SyncDirection) async throws -> [SyncOperation]

    /// Sync specific entity
    /// - Parameters:
    ///   - entityType: Type of entity (e.g., "Capture", "Annotation")
    ///   - entityId: ID of the entity
    ///   - direction: Direction of sync
    func sync(
        entityType: String,
        entityId: UUID,
        direction: SyncDirection
    ) async throws -> SyncOperation

    /// Check if network is available
    /// - Returns: True if network is available
    func isNetworkAvailable() async -> Bool

    /// Get pending sync operations
    /// - Returns: Array of pending operations
    func getPendingSyncOperations() async throws -> [SyncOperation]

    /// Get sync history
    /// - Parameter limit: Maximum number of operations to return
    /// - Returns: Array of sync operations
    func getSyncHistory(limit: Int) async throws -> [SyncOperation]

    /// Clear sync history
    func clearSyncHistory() async throws

    /// Retry failed sync operations
    /// - Parameter maxRetries: Maximum number of retries per operation
    func retryFailedOperations(maxRetries: Int) async throws -> [SyncOperation]

    /// Cancel pending sync operation
    /// - Parameter operationId: ID of the operation to cancel
    func cancelOperation(id operationId: UUID) async throws

    /// Register for sync updates
    /// - Parameter handler: Callback for sync events
    func onSyncStatusChanged(
        handler: @Sendable (SyncOperation) -> Void
    ) async

    /// Get last successful sync time
    /// - Returns: Date of last successful sync, or nil if never synced
    func getLastSyncTime() async throws -> Date?

    /// Set automatic sync interval
    /// - Parameter interval: Sync interval in seconds
    func setAutoSyncInterval(_ interval: TimeInterval) async throws
}
