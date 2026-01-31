import Foundation

// MARK: - SyncConflict

/// Represents a sync conflict between local and remote data.
public struct SyncConflict: Sendable, Identifiable {
    public let id: String
    public let entityId: UUID
    public let entityType: String
    public let type: ConflictType
    public let resourceId: String
    public let localVersion: Int
    public let remoteVersion: Int
    public let detectedAt: Date

    public init(
        entityId: UUID,
        entityType: String,
        id: String = UUID().uuidString,
        type: ConflictType = .versionMismatch,
        resourceId: String = "",
        localVersion: Int = 0,
        remoteVersion: Int = 0,
        detectedAt: Date = Date()
    ) {
        self.id = id
        self.entityId = entityId
        self.entityType = entityType
        self.type = type
        self.resourceId = resourceId
        self.localVersion = localVersion
        self.remoteVersion = remoteVersion
        self.detectedAt = detectedAt
    }
}

// MARK: - ConflictType

public enum ConflictType: Sendable {
    case versionMismatch
    case deletionConflict
    case modificationConflict

    public var description: String {
        switch self {
        case .versionMismatch: return "Version Mismatch"
        case .deletionConflict: return "Deletion Conflict"
        case .modificationConflict: return "Modification Conflict"
        }
    }
}

// MARK: - ConflictResolution

public enum ConflictResolution: Sendable {
    case useLocal
    case useRemote
    case useNewest
    case custom(String)

    public var description: String {
        switch self {
        case .useLocal: return "Use local version"
        case .useRemote: return "Use remote version"
        case .useNewest: return "Use newest version"
        case .custom(let strategy): return "Custom: \(strategy)"
        }
    }
}

// MARK: - ConflictResolutionResult

public struct ConflictResolutionResult: Sendable {
    public let totalConflicts: Int
    public let resolvedCount: Int
    public let failedCount: Int
    public let failedConflicts: [SyncConflict]

    public var resolutionRate: Float {
        guard totalConflicts > 0 else { return 1.0 }
        return Float(resolvedCount) / Float(totalConflicts)
    }

    public var isSuccessful: Bool {
        failedCount == 0
    }
}

// MARK: - SyncStatusValue

/// Status of a sync operation result.
public enum SyncStatusValue: String, Sendable {
    case completed
    case queued
    case completedWithConflicts
    case failed
    case inProgress
}

// MARK: - SyncResult (test-contract compatible)

/// Result returned by SyncDataUseCase.execute().
public struct SyncResult: Sendable {
    public let status: SyncStatusValue
    public let syncedItemsCount: Int
    public let conflicts: [SyncConflict]

    public init(status: SyncStatusValue, syncedItemsCount: Int, conflicts: [SyncConflict]) {
        self.status = status
        self.syncedItemsCount = syncedItemsCount
        self.conflicts = conflicts
    }
}
