import Foundation

/// Domain-level sync service protocol
@available(iOS 15.0, *)
public protocol SyncServiceProtocol: Sendable {
    /// Trigger full data synchronization
    func syncData() async throws -> SyncResult

    /// Check current sync progress
    func checkSyncStatus() async throws -> SyncStatus

    /// Resolve sync conflicts
    func resolveConflicts(_ conflicts: [SyncConflict]) async throws -> SyncResult

    /// Stop ongoing sync
    func stopSync() async throws

    /// Clear local cache
    func clearCache() async throws

    /// Get sync statistics
    func getSyncStatistics() async throws -> SyncStatistics
}

/// Sync result
public struct SyncResult: Sendable {
    public let timestamp: Date
    public let duration: TimeInterval
    public let status: SyncResultStatus
    public let changesSynced: Int
    public let conflictsResolved: Int
    public let errors: [SyncError]
    public let details: SyncDetails

    public init(
        timestamp: Date,
        duration: TimeInterval,
        status: SyncResultStatus,
        changesSynced: Int,
        conflictsResolved: Int,
        errors: [SyncError],
        details: SyncDetails
    ) {
        self.timestamp = timestamp
        self.duration = duration
        self.status = status
        self.changesSynced = changesSynced
        self.conflictsResolved = conflictsResolved
        self.errors = errors
        self.details = details
    }
}

/// Sync result status
public enum SyncResultStatus: String, Sendable {
    case success
    case partialSuccess
    case failed
    case cancelled
}

/// Sync details
public struct SyncDetails: Sendable {
    public let projectsSynced: Int
    public let samplesSynced: Int
    public let capturesSynced: Int
    public let annotationsSynced: Int
    public let analysisSynced: Int
    public let bytesTransferred: Int

    public init(
        projectsSynced: Int,
        samplesSynced: Int,
        capturesSynced: Int,
        annotationsSynced: Int,
        analysisSynced: Int,
        bytesTransferred: Int
    ) {
        self.projectsSynced = projectsSynced
        self.samplesSynced = samplesSynced
        self.capturesSynced = capturesSynced
        self.annotationsSynced = annotationsSynced
        self.analysisSynced = analysisSynced
        self.bytesTransferred = bytesTransferred
    }
}

/// Sync status
public struct SyncStatus: Sendable {
    public let isRunning: Bool
    public let progress: Double
    public let currentOperation: String
    public let estimatedTimeRemaining: TimeInterval?
    public let bytesDownloaded: Int
    public let bytesUploaded: Int
    public let startTime: Date?

    public init(
        isRunning: Bool,
        progress: Double,
        currentOperation: String,
        estimatedTimeRemaining: TimeInterval?,
        bytesDownloaded: Int,
        bytesUploaded: Int,
        startTime: Date?
    ) {
        self.isRunning = isRunning
        self.progress = progress
        self.currentOperation = currentOperation
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.bytesDownloaded = bytesDownloaded
        self.bytesUploaded = bytesUploaded
        self.startTime = startTime
    }
}

/// Sync conflict
public struct SyncConflict: Sendable {
    public let id: String
    public let resourceType: ResourceType
    public let resourceId: String
    public let localVersion: ConflictVersion
    public let remoteVersion: ConflictVersion
    public let conflictType: ConflictType

    public init(
        id: String,
        resourceType: ResourceType,
        resourceId: String,
        localVersion: ConflictVersion,
        remoteVersion: ConflictVersion,
        conflictType: ConflictType
    ) {
        self.id = id
        self.resourceType = resourceType
        self.resourceId = resourceId
        self.localVersion = localVersion
        self.remoteVersion = remoteVersion
        self.conflictType = conflictType
    }
}

/// Resource type
public enum ResourceType: String, Sendable {
    case project
    case sample
    case capture
    case annotation
    case analysis
}

/// Conflict version
public struct ConflictVersion: Sendable {
    public let timestamp: Date
    public let deviceId: String
    public let hash: String
    public let summary: String

    public init(timestamp: Date, deviceId: String, hash: String, summary: String) {
        self.timestamp = timestamp
        self.deviceId = deviceId
        self.hash = hash
        self.summary = summary
    }
}

/// Conflict type
public enum ConflictType: String, Sendable {
    case update
    case delete
    case merge
    case custom
}

/// Sync error
public struct SyncError: Sendable {
    public let code: String
    public let message: String
    public let resourceId: String?
    public let timestamp: Date

    public init(code: String, message: String, resourceId: String? = nil, timestamp: Date = Date()) {
        self.code = code
        self.message = message
        self.resourceId = resourceId
        self.timestamp = timestamp
    }
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

/// Sync errors
public enum SyncServiceError: LocalizedError, Sendable {
    case syncInProgress
    case networkUnavailable
    case conflictResolutionFailed
    case cacheAccessFailed
    case networkError(String)
    case unknownError(String)

    public var errorDescription: String? {
        switch self {
        case .syncInProgress:
            return "Sync is already in progress"
        case .networkUnavailable:
            return "Network is unavailable"
        case .conflictResolutionFailed:
            return "Failed to resolve conflicts"
        case .cacheAccessFailed:
            return "Failed to access local cache"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknownError(let message):
            return "Error: \(message)"
        }
    }
}
