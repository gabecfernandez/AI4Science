import Foundation

public struct QueueForSyncUseCase: Sendable {
    private let syncRepository: any SyncRepositoryProtocol

    public init(syncRepository: any SyncRepositoryProtocol) {
        self.syncRepository = syncRepository
    }

    /// Queues a single item for synchronization
    /// - Parameters:
    ///   - type: Type of item to sync
    ///   - resourceId: Resource identifier
    ///   - operation: Sync operation (create, update, delete)
    ///   - priority: Priority level (higher = more urgent)
    /// - Returns: SyncQueueItem that was queued
    /// - Throws: SyncUseCaseError if queuing fails
    public func execute(
        type: SyncItemType,
        resourceId: String,
        operation: SyncOperationType,
        priority: Int = 0
    ) async throws -> SyncQueueItem {
        guard !resourceId.isEmpty else {
            throw SyncUseCaseError.validationFailed("Resource ID is required.")
        }

        let item = SyncQueueItem(
            type: type,
            resourceId: resourceId,
            operation: operation,
            priority: priority
        )

        try await syncRepository.queueItemForSync(item)
        return item
    }

    /// Queues multiple items for synchronization
    /// - Parameter items: Array of queue items to add
    /// - Returns: Array of queued items
    /// - Throws: SyncUseCaseError if queuing fails
    public func queueBatch(_ items: [SyncQueueItem]) async throws -> [SyncQueueItem] {
        guard !items.isEmpty else {
            throw SyncUseCaseError.validationFailed("At least one item is required.")
        }

        var queuedItems: [SyncQueueItem] = []

        for item in items {
            do {
                try await syncRepository.queueItemForSync(item)
                queuedItems.append(item)
            } catch {
                print("Failed to queue item \(item.id): \(error)")
            }
        }

        return queuedItems
    }

    /// Gets all currently queued items
    /// - Returns: Array of queued items
    /// - Throws: SyncError if fetch fails
    public func getQueuedItems() async throws -> [SyncQueueItem] {
        let items = try await syncRepository.getQueuedItems()
        return items.sorted { $0.priority > $1.priority }
    }

    /// Gets queued items by type
    /// - Parameter type: Item type to filter
    /// - Returns: Filtered array of queued items
    /// - Throws: SyncError if fetch fails
    public func getQueuedItems(ofType type: SyncItemType) async throws -> [SyncQueueItem] {
        let allItems = try await getQueuedItems()
        return allItems.filter { $0.type == type }
    }

    /// Gets queue statistics
    /// - Returns: QueueStatistics
    /// - Throws: SyncError if calculation fails
    public func getQueueStatistics() async throws -> QueueStatistics {
        let items = try await getQueuedItems()

        let byType = Dictionary(grouping: items, by: { $0.type })
            .mapValues { $0.count }

        let byOperation = Dictionary(grouping: items, by: { $0.operation })
            .mapValues { $0.count }

        let avgRetryCount = items.isEmpty ? 0 : items.reduce(0) { $0 + $1.retryCount } / items.count

        return QueueStatistics(
            totalItems: items.count,
            itemsByType: byType,
            itemsByOperation: byOperation,
            averageRetryCount: avgRetryCount,
            oldestItemAge: items.min(by: { $0.addedAt > $1.addedAt })
                .map { Date().timeIntervalSince($0.addedAt) } ?? 0
        )
    }
}

// MARK: - Supporting Types

public struct QueueStatistics: Sendable {
    public let totalItems: Int
    public let itemsByType: [SyncItemType: Int]
    public let itemsByOperation: [SyncOperationType: Int]
    public let averageRetryCount: Int
    public let oldestItemAge: TimeInterval

    public init(
        totalItems: Int,
        itemsByType: [SyncItemType: Int],
        itemsByOperation: [SyncOperationType: Int],
        averageRetryCount: Int,
        oldestItemAge: TimeInterval
    ) {
        self.totalItems = totalItems
        self.itemsByType = itemsByType
        self.itemsByOperation = itemsByOperation
        self.averageRetryCount = averageRetryCount
        self.oldestItemAge = oldestItemAge
    }
}

public struct SyncPriority: Sendable {
    public static let critical = 100
    public static let high = 50
    public static let normal = 0
    public static let low = -50
}

public struct BatchQueueRequest: Sendable {
    public let items: [SyncQueueItem]
    public let autoSync: Bool
    public let syncDelay: TimeInterval

    public init(
        items: [SyncQueueItem],
        autoSync: Bool = true,
        syncDelay: TimeInterval = 0
    ) {
        self.items = items
        self.autoSync = autoSync
        self.syncDelay = syncDelay
    }
}
