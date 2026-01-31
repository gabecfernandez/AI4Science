import Foundation

/// Domain-level sync service protocol for production sync implementations.
public protocol SyncServiceProtocol: Sendable {
    /// Trigger full data synchronization
    func syncData() async throws -> SyncResult

    /// Check current sync status
    func checkSyncStatus() async throws -> SyncStatusValue

    /// Resolve sync conflicts
    func resolveConflicts(_ conflicts: [SyncConflict]) async throws -> SyncResult

    /// Stop ongoing sync
    func stopSync() async throws

    /// Clear local cache
    func clearCache() async throws
}

/// Sync statistics
public struct SyncStatistics: Sendable {
    public let totalSyncCount: Int
    public let lastSyncDate: Date?
    public let averageSyncDuration: TimeInterval
    public let successRate: Double
    public let totalBytesTransferred: Int
    public let conflictCount: Int

    public init(
        totalSyncCount: Int,
        lastSyncDate: Date?,
        averageSyncDuration: TimeInterval,
        successRate: Double,
        totalBytesTransferred: Int,
        conflictCount: Int
    ) {
        self.totalSyncCount = totalSyncCount
        self.lastSyncDate = lastSyncDate
        self.averageSyncDuration = averageSyncDuration
        self.successRate = successRate
        self.totalBytesTransferred = totalBytesTransferred
        self.conflictCount = conflictCount
    }
}

/// Sync service errors
public enum SyncServiceError: LocalizedError, Sendable {
    case syncInProgress
    case networkUnavailable
    case conflictResolutionFailed
    case cacheAccessFailed
    case networkError(String)
    case unknownError(String)

    public var errorDescription: String? {
        switch self {
        case .syncInProgress: return "Sync is already in progress"
        case .networkUnavailable: return "Network is unavailable"
        case .conflictResolutionFailed: return "Failed to resolve conflicts"
        case .cacheAccessFailed: return "Failed to access local cache"
        case .networkError(let message): return "Network error: \(message)"
        case .unknownError(let message): return "Error: \(message)"
        }
    }
}
