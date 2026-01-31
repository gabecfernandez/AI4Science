import Foundation
import SwiftData

/// Actor managing the sync queue for offline operations
actor SyncQueue: Sendable {
    // MARK: - Properties

    private let modelContainer: ModelContainer

    // MARK: - Initialization

    init(modelContainer: ModelContainer) throws {
        self.modelContainer = modelContainer
    }

    // MARK: - Public Methods

    /// Add operation to sync queue
    /// - Parameters:
    ///   - operationType: Type of operation (create, update, delete)
    ///   - entityType: Type of entity
    ///   - entityID: ID of the entity
    ///   - data: Operation data as JSON
    /// - Returns: The created SyncQueueEntity
    @discardableResult
    func enqueue(
        operationType: String,
        entityType: String,
        entityID: String,
        data: String
    ) async throws -> SyncQueueEntity {
        let context = ModelContext(modelContainer)

        let queueEntry = SyncQueueEntity(
            id: UUID().uuidString,
            operationType: operationType,
            entityType: entityType,
            entityID: entityID,
            operationData: data
        )

        context.insert(queueEntry)
        try context.save()

        AppLogger.info("Queued \(operationType) for \(entityType):\(entityID)")
        return queueEntry
    }

    /// Process all pending queue items
    /// - Returns: Number of items successfully synced
    func processQueue() async -> Int {
        do {
            let context = ModelContext(modelContainer)
            let predicate = #Predicate<SyncQueueEntity> { $0.status == "pending" || $0.status == "pending_retry" }
            let descriptor = FetchDescriptor(predicate: predicate)
            let pendingItems = try context.fetch(descriptor)

            var synced = 0

            for item in pendingItems {
                if item.shouldRetry {
                    await processQueueItem(item)
                    synced += 1
                }
            }

            return synced
        } catch {
            AppLogger.error("Failed to process queue: \(error.localizedDescription)")
            return 0
        }
    }

    /// Get pending items count
    var pendingCount: Int {
        get async {
            do {
                let context = ModelContext(modelContainer)
                let predicate = #Predicate<SyncQueueEntity> { $0.status == "pending" || $0.status == "pending_retry" }
                let descriptor = FetchDescriptor(predicate: predicate)
                return try context.fetchCount(descriptor)
            } catch {
                AppLogger.error("Failed to count pending items: \(error.localizedDescription)")
                return 0
            }
        }
    }

    /// Remove item from queue
    /// - Parameter id: ID of the queue entry
    func removeFromQueue(id: String) async throws {
        let context = ModelContext(modelContainer)
        let predicate = #Predicate<SyncQueueEntity> { $0.id == id }
        let descriptor = FetchDescriptor(predicate: predicate)

        if let item = try context.fetch(descriptor).first {
            context.delete(item)
            try context.save()
            AppLogger.info("Removed from queue: \(id)")
        }
    }

    /// Clear entire queue (use with caution)
    func clearQueue() async throws {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<SyncQueueEntity>()
        let allItems = try context.fetch(descriptor)

        for item in allItems {
            context.delete(item)
        }

        try context.save()
        AppLogger.warning("Queue cleared")
    }

    /// Get queue items by entity type
    /// - Parameter entityType: Type of entity to filter
    func getQueueItems(for entityType: String) async throws -> [SyncQueueEntity] {
        let context = ModelContext(modelContainer)
        let predicate = #Predicate<SyncQueueEntity> { $0.entityType == entityType }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try context.fetch(descriptor)
    }

    // MARK: - Private Methods

    private func processQueueItem(_ item: SyncQueueEntity) async {
        let context = ModelContext(modelContainer)

        do {
            item.markInProgress()

            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            // Update would sync to server here
            // For now, just mark as synced
            item.markSynced()

            AppLogger.info("Synced \(item.operationType) for \(item.entityType)")
        } catch {
            item.markFailedWithRetry(errorMessage: error.localizedDescription)
            AppLogger.warning("Failed to sync \(item.entityType):\(item.entityID) - will retry")
        }

        try? context.save()
    }
}
