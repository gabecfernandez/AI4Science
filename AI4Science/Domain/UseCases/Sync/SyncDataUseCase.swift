import Foundation

public struct SyncDataUseCase: Sendable {
    private let syncRepository: any SyncRepositoryProtocol

    public init(syncRepository: any SyncRepositoryProtocol) {
        self.syncRepository = syncRepository
    }

    /// Synchronizes all pending offline data with server
    /// - Returns: SyncResult with statistics
    /// - Throws: SyncError if sync fails
    public func execute() async throws -> SyncResult {
        let startTime = Date()

        // Sync pending data
        let syncResult = try await syncRepository.syncAllData()

        return SyncResult(
            itemsSynced: syncResult.itemsSynced,
            itemsSkipped: syncResult.itemsSkipped,
            conflictsResolved: syncResult.conflictsResolved,
            totalProcessingTime: Date().timeIntervalSince(startTime),
            startTime: startTime,
            endTime: Date()
        )
    }

    /// Synchronizes data for a specific project
    /// - Parameter projectId: Project identifier
    /// - Returns: SyncResult
    /// - Throws: SyncError if sync fails
    public func execute(projectId: String) async throws -> SyncResult {
        guard !projectId.isEmpty else {
            throw SyncUseCaseError.validationFailed("Project ID is required.")
        }

        let startTime = Date()
        let syncResult = try await syncRepository.syncProject(projectId: projectId)

        return SyncResult(
            itemsSynced: syncResult.itemsSynced,
            itemsSkipped: syncResult.itemsSkipped,
            conflictsResolved: syncResult.conflictsResolved,
            totalProcessingTime: Date().timeIntervalSince(startTime),
            startTime: startTime,
            endTime: Date()
        )
    }

    /// Gets the current sync status
    /// - Returns: SyncUseCaseStatus with queue info
    /// - Throws: SyncUseCaseError if fetch fails
    public func getStatus() async throws -> SyncUseCaseStatus {
        return try await syncRepository.getSyncStatus()
    }

    /// Pauses synchronization
    /// - Throws: SyncError if pause fails
    public func pause() async throws {
        try await syncRepository.pauseSync()
    }

    /// Resumes synchronization
    /// - Throws: SyncError if resume fails
    public func resume() async throws {
        try await syncRepository.resumeSync()
    }
}

// MARK: - Supporting Types

public struct SyncResult: Sendable {
    public let itemsSynced: Int
    public let itemsSkipped: Int
    public let conflictsResolved: Int
    public let totalProcessingTime: TimeInterval
    public let startTime: Date
    public let endTime: Date

    public var totalItems: Int {
        itemsSynced + itemsSkipped
    }

    public var successRate: Float {
        guard totalItems > 0 else { return 1.0 }
        return Float(itemsSynced) / Float(totalItems)
    }

    public var isSuccessful: Bool {
        itemsSkipped == 0
    }

    public init(
        itemsSynced: Int,
        itemsSkipped: Int,
        conflictsResolved: Int,
        totalProcessingTime: TimeInterval,
        startTime: Date,
        endTime: Date
    ) {
        self.itemsSynced = itemsSynced
        self.itemsSkipped = itemsSkipped
        self.conflictsResolved = conflictsResolved
        self.totalProcessingTime = totalProcessingTime
        self.startTime = startTime
        self.endTime = endTime
    }
}

public struct SyncUseCaseStatus: Sendable {
    public let isSyncing: Bool
    public let queuedItemsCount: Int
    public let lastSyncTime: Date?
    public let nextSyncTime: Date?
    public let currentlySyncingItem: String?
    public let syncProgress: Float

    public init(
        isSyncing: Bool,
        queuedItemsCount: Int,
        lastSyncTime: Date? = nil,
        nextSyncTime: Date? = nil,
        currentlySyncingItem: String? = nil,
        syncProgress: Float = 0
    ) {
        self.isSyncing = isSyncing
        self.queuedItemsCount = queuedItemsCount
        self.lastSyncTime = lastSyncTime
        self.nextSyncTime = nextSyncTime
        self.currentlySyncingItem = currentlySyncingItem
        self.syncProgress = syncProgress
    }
}

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
        case .validationFailed(let message):
            return message
        case .queueEmpty:
            return "No items to synchronize."
        case .syncInProgress:
            return "Synchronization is already in progress."
        case .networkError:
            return "Network connection failed."
        case .serverError(let message):
            return "Server error: \(message)"
        case .conflictError:
            return "Sync conflict occurred."
        case .authenticationRequired:
            return "Authentication required to sync."
        }
    }
}

// MARK: - Repository Protocol

public protocol SyncRepositoryProtocol: Sendable {
    func syncAllData() async throws -> SyncResult
    func syncProject(projectId: String) async throws -> SyncResult
    func getSyncStatus() async throws -> SyncUseCaseStatus
    func pauseSync() async throws
    func resumeSync() async throws
    func queueItemForSync(_ item: SyncQueueItem) async throws
    func getQueuedItems() async throws -> [SyncQueueItem]
    func resolveSyncConflict(conflictId: String, resolution: SyncResolutionType) async throws
}

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

public enum SyncResolutionType: Sendable {
    case useLocal
    case useRemote
    case merge
}
