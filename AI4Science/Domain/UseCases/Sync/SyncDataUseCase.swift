import Foundation

/// Protocol for sync services consumed by SyncDataUseCase.
public protocol SyncServiceConsumer: Sendable {
    func sync() async throws -> SyncResult
}

/// Use case for synchronizing data with the remote server.
/// Accepts any sync service with a `sync() -> SyncResult` method via generic init.
/// Test mocks conform via an extension in the test target.
public actor SyncDataUseCase: Sendable {
    private let _sync: @Sendable () async throws -> SyncResult

    /// Generic init — captures the sync method via protocol constraint.
    public init<S: SyncServiceConsumer>(syncService: S) {
        self._sync = { try await syncService.sync() }
    }

    /// Execute the sync operation.
    public func execute() async throws -> SyncResult {
        try await _sync()
    }
}

// MARK: - Sync Use Case Error

public enum SyncUseCaseError: LocalizedError, Sendable {
    case validationFailed(String)
    case queueEmpty
    case syncInProgress
    case networkError
    case serverError(message: String)
    case conflictError
    case authenticationRequired

    public var errorDescription: String? {
        switch self {
        case .validationFailed(let message): return message
        case .queueEmpty: return "No items to synchronize."
        case .syncInProgress: return "Synchronization is already in progress."
        case .networkError: return "Network connection failed."
        case .serverError(let message): return "Server error: \(message)"
        case .conflictError: return "Sync conflict occurred."
        case .authenticationRequired: return "Authentication required to sync."
        }
    }
}

// MARK: - Repository Protocol (for production use)

public protocol SyncRepositoryProtocol: Sendable {
    func syncAllData() async throws -> SyncResult
    func getSyncStatus() async throws -> SyncStatusValue
    func pauseSync() async throws
    func resumeSync() async throws
    func resolveSyncConflict(conflict: SyncConflict, resolution: ConflictResolution) async throws
    func queueItemForSync(_ item: SyncQueueItem) async throws
    func getQueuedItems() async throws -> [SyncQueueItem]
}

// MARK: - Sync Queue Item

public struct SyncQueueItem: Sendable {
    public let id: String
    public let type: SyncItemType
    public let resourceId: String
    public let operation: SyncOperationType
    public let priority: Int
    public let addedAt: Date
    public let retryCount: Int

    public init(
        id: String = UUID().uuidString,
        type: SyncItemType,
        resourceId: String,
        operation: SyncOperationType,
        priority: Int = 0,
        addedAt: Date = Date(),
        retryCount: Int = 0
    ) {
        self.id = id
        self.type = type
        self.resourceId = resourceId
        self.operation = operation
        self.priority = priority
        self.addedAt = addedAt
        self.retryCount = retryCount
    }
}

public enum SyncItemType: Sendable {
    case project
    case capture
    case analysis
    case annotation
}

public enum SyncOperationType: Sendable {
    case create
    case update
    case delete
}
