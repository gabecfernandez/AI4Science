import Foundation
import SwiftData

/// Protocol for sync queue operations - returns only Sendable domain types
/// Entity-based operations are internal to the actor and not exposed via protocol
protocol SyncQueueRepositoryProtocol: Sendable {
    func getQueueSize() async throws -> Int
    func clearQueue() async throws
    // Entity operations are internal to actor only
}

/// Sync queue repository implementation using ModelActor
@ModelActor
final actor SyncQueueRepository {

    /// Add entry to sync queue
    func addToQueue(_ entry: SyncQueueEntity) async throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    /// Get queue entry by ID
    func getSyncQueueEntry(id: String) async throws -> SyncQueueEntity? {
        let descriptor = FetchDescriptor<SyncQueueEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Get pending queue entries
    func getPendingQueue() async throws -> [SyncQueueEntity] {
        let descriptor = FetchDescriptor<SyncQueueEntity>(
            predicate: #Predicate { entry in
                entry.status == "pending" || entry.status == "pending_retry"
            },
            sortBy: [SortDescriptor(\.priority, order: .reverse), SortDescriptor(\.enqueuedAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get queue entries by status
    func getQueueByStatus(_ status: String) async throws -> [SyncQueueEntity] {
        let descriptor = FetchDescriptor<SyncQueueEntity>(
            predicate: #Predicate { $0.status == status },
            sortBy: [SortDescriptor(\.enqueuedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get high priority queue entries
    func getHighPriorityQueue() async throws -> [SyncQueueEntity] {
        let descriptor = FetchDescriptor<SyncQueueEntity>(
            predicate: #Predicate { $0.priority > 7 },
            sortBy: [SortDescriptor(\.priority, order: .reverse), SortDescriptor(\.enqueuedAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Update queue entry
    func updateQueueEntry(_ entry: SyncQueueEntity) async throws {
        try modelContext.save()
    }

    /// Remove entry from queue
    func removeFromQueue(id: String) async throws {
        guard let entry = try await getSyncQueueEntry(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(entry)
        try modelContext.save()
    }

    /// Clear all queue entries
    func clearQueue() async throws {
        let descriptor = FetchDescriptor<SyncQueueEntity>()
        let entries = try modelContext.fetch(descriptor)
        for entry in entries {
            modelContext.delete(entry)
        }
        try modelContext.save()
    }

    /// Get queue size
    func getQueueSize() async throws -> Int {
        let descriptor = FetchDescriptor<SyncQueueEntity>()
        let entries = try modelContext.fetch(descriptor)
        return entries.count
    }

    /// Get failed entries
    func getFailedEntries() async throws -> [SyncQueueEntity] {
        let descriptor = FetchDescriptor<SyncQueueEntity>(
            predicate: #Predicate { $0.status == "failed" },
            sortBy: [SortDescriptor(\.enqueuedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get critical entries
    func getCriticalEntries() async throws -> [SyncQueueEntity] {
        let descriptor = FetchDescriptor<SyncQueueEntity>(
            predicate: #Predicate { $0.isCritical == true },
            sortBy: [SortDescriptor(\.priority, order: .reverse), SortDescriptor(\.enqueuedAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get expired entries
    func getExpiredEntries() async throws -> [SyncQueueEntity] {
        // Use predicate to filter expired entries (older than 24 hours)
        let expirationDate = Date().addingTimeInterval(-86400)
        let descriptor = FetchDescriptor<SyncQueueEntity>(
            predicate: #Predicate { $0.enqueuedAt < expirationDate }
        )
        return try modelContext.fetch(descriptor)
    }
}

/// Factory for creating sync queue repository
enum SyncQueueRepositoryFactory {
    @MainActor
    static func makeRepository(modelContainer: ModelContainer) -> SyncQueueRepository {
        SyncQueueRepository(modelContainer: modelContainer)
    }
}
