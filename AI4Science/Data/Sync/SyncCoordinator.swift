import Foundation
import SwiftData

/// Actor responsible for coordinating synchronization operations
actor SyncCoordinator: Sendable {
    // MARK: - Properties

    private let modelContainer: ModelContainer
    private var syncInProgress: Bool = false
    private var lastSyncTime: Date?
    private let syncQueue: SyncQueue
    private let conflictResolver: ConflictResolver
    private let apiClient: APIClient

    // MARK: - Initialization

    init(
        modelContainer: ModelContainer,
        apiClient: APIClient
    ) async throws {
        self.modelContainer = modelContainer
        self.apiClient = apiClient
        self.syncQueue = try SyncQueue(modelContainer: modelContainer)
        self.conflictResolver = try ConflictResolver(modelContainer: modelContainer)
    }

    // MARK: - Public Methods

    /// Start full synchronization
    /// - Returns: SyncResult containing sync outcome
    func startFullSync() async -> SyncOperationResult {
        guard !syncInProgress else {
            return SyncOperationResult(
                success: false,
                error: "Sync already in progress",
                itemsSynced: 0
            )
        }

        syncInProgress = true
        defer { syncInProgress = false }

        AppLogger.info("Starting full sync...")

        var itemsSynced = 0
        var errors: [String] = []

        do {
            // Sync users
            let userResult = await syncEntitiesOfType("user")
            itemsSynced += userResult.itemsSynced
            if let error = userResult.error {
                errors.append("Users: \(error)")
            }

            // Sync projects
            let projectResult = await syncEntitiesOfType("project")
            itemsSynced += projectResult.itemsSynced
            if let error = projectResult.error {
                errors.append("Projects: \(error)")
            }

            // Sync samples
            let sampleResult = await syncEntitiesOfType("sample")
            itemsSynced += sampleResult.itemsSynced
            if let error = sampleResult.error {
                errors.append("Samples: \(error)")
            }

            // Sync captures
            let captureResult = await syncEntitiesOfType("capture")
            itemsSynced += captureResult.itemsSynced
            if let error = captureResult.error {
                errors.append("Captures: \(error)")
            }

            // Process sync queue
            let queueResult = await syncQueue.processQueue()
            itemsSynced += queueResult

            lastSyncTime = Date()

            return SyncOperationResult(
                success: errors.isEmpty,
                error: errors.isEmpty ? nil : errors.joined(separator: "; "),
                itemsSynced: itemsSynced
            )
        }
    }

    /// Sync specific entity type
    /// - Parameter entityType: Type of entity to sync
    func syncEntity(type entityType: String) async -> SyncOperationResult {
        AppLogger.info("Syncing \(entityType)...")
        return await syncEntitiesOfType(entityType)
    }

    /// Get current sync status
    func getSyncStatus() async -> SyncStatusInfo {
        return SyncStatusInfo(
            isSyncing: syncInProgress,
            lastSyncTime: lastSyncTime,
            pendingItemsCount: await syncQueue.pendingCount
        )
    }

    // MARK: - Private Methods

    /// Generic sync method that runs on MainActor to avoid data race issues
    private func syncEntitiesOfType(_ entityType: String) async -> SyncOperationResult {
        await MainActor.run {
            do {
                let context = ModelContext(modelContainer)
                let predicate = #Predicate<SyncMetadataEntity> { $0.entityType == entityType && $0.syncStatus != "synced" }
                let descriptor = FetchDescriptor(predicate: predicate)
                let pendingSync = try context.fetch(descriptor)

                var synced = 0

                for syncMeta in pendingSync {
                    do {
                        // Mark as syncing
                        syncMeta.syncStatus = "syncing"
                        syncMeta.lastSyncAttempt = Date()
                        syncMeta.syncAttempts += 1

                        // Simulate sync to server (would be actual API call)
                        // For now, mark as success
                        syncMeta.syncStatus = "synced"
                        syncMeta.lastSyncSuccess = Date()
                        syncMeta.syncError = nil
                        syncMeta.hasConflict = false
                        syncMeta.syncAttempts = 0

                        synced += 1
                    } catch {
                        syncMeta.syncError = error.localizedDescription
                        if syncMeta.syncAttempts >= syncMeta.maxSyncAttempts {
                            syncMeta.syncStatus = "failed"
                        } else {
                            syncMeta.syncStatus = "pending"
                        }
                    }
                }

                try context.save()
                return SyncOperationResult(success: true, error: nil, itemsSynced: synced)
            } catch {
                return SyncOperationResult(success: false, error: error.localizedDescription, itemsSynced: 0)
            }
        }
    }
}
