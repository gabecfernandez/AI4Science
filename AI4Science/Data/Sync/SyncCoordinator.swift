import Foundation
import SwiftData

/// Internal result type for SyncCoordinator operations.
/// Distinct from the domain-layer SyncResult in SyncTypes.swift.
struct SyncCoordinatorResult: Sendable {
    let success: Bool
    let error: String?
    let itemsSynced: Int
}

/// Internal status type for SyncCoordinator.
/// Distinct from the domain-layer SyncStatusValue in SyncTypes.swift.
struct CoordinatorSyncStatus: Sendable {
    let isSyncing: Bool
    let lastSyncTime: Date?
    let pendingItemsCount: Int
}

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
    /// - Returns: CoordinatorSyncStatus containing sync outcome
    func startFullSync() async -> SyncCoordinatorResult {
        guard !syncInProgress else {
            return SyncCoordinatorResult(
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

        // Sync users
        let userResult = await syncUsers()
        itemsSynced += userResult.itemsSynced
        if let error = userResult.error {
            errors.append("Users: \(error)")
        }

        // Sync projects
        let projectResult = await syncProjects()
        itemsSynced += projectResult.itemsSynced
        if let error = projectResult.error {
            errors.append("Projects: \(error)")
        }

        // Sync samples
        let sampleResult = await syncSamples()
        itemsSynced += sampleResult.itemsSynced
        if let error = sampleResult.error {
            errors.append("Samples: \(error)")
        }

        // Sync captures
        let captureResult = await syncCaptures()
        itemsSynced += captureResult.itemsSynced
        if let error = captureResult.error {
            errors.append("Captures: \(error)")
        }

        // Process sync queue
        let queueResult = await syncQueue.processQueue()
        itemsSynced += queueResult

        lastSyncTime = Date()

        return SyncCoordinatorResult(
            success: errors.isEmpty,
            error: errors.isEmpty ? nil : errors.joined(separator: "; "),
            itemsSynced: itemsSynced
        )
    }

    /// Sync specific entity type
    /// - Parameter entityType: Type of entity to sync
    func syncEntity(type entityType: String) async -> SyncCoordinatorResult {
        AppLogger.info("Syncing \(entityType)...")

        switch entityType {
        case "users":
            return await syncUsers()
        case "projects":
            return await syncProjects()
        case "samples":
            return await syncSamples()
        case "captures":
            return await syncCaptures()
        case "annotations":
            return await syncAnnotations()
        default:
            return SyncCoordinatorResult(
                success: false,
                error: "Unknown entity type: \(entityType)",
                itemsSynced: 0
            )
        }
    }

    /// Get current sync status
    func getSyncStatus() async -> CoordinatorSyncStatus {
        let pending = await syncQueue.pendingCount
        return CoordinatorSyncStatus(
            isSyncing: syncInProgress,
            lastSyncTime: lastSyncTime,
            pendingItemsCount: pending
        )
    }

    // MARK: - Private Methods

    private func syncUsers() async -> SyncCoordinatorResult {
        do {
            let context = ModelContext(modelContainer)
            let predicate = #Predicate<SyncMetadataEntity> { $0.entityType == "user" && $0.syncStatus != "synced" }
            let descriptor = FetchDescriptor(predicate: predicate)
            let pendingSync = try context.fetch(descriptor)

            var synced = 0

            for syncMeta in pendingSync {
                do {
                    try await syncMeta.markSyncStarted()
                    try await syncMeta.markSyncSuccess()
                    synced += 1
                } catch {
                    try await syncMeta.markSyncFailed(error: error.localizedDescription)
                }
            }

            return SyncCoordinatorResult(success: true, error: nil, itemsSynced: synced)
        } catch {
            return SyncCoordinatorResult(success: false, error: error.localizedDescription, itemsSynced: 0)
        }
    }

    private func syncProjects() async -> SyncCoordinatorResult {
        do {
            let context = ModelContext(modelContainer)
            let predicate = #Predicate<SyncMetadataEntity> { $0.entityType == "project" && $0.syncStatus != "synced" }
            let descriptor = FetchDescriptor(predicate: predicate)
            let pendingSync = try context.fetch(descriptor)

            var synced = 0

            for syncMeta in pendingSync {
                do {
                    try await syncMeta.markSyncStarted()
                    try await syncMeta.markSyncSuccess()
                    synced += 1
                } catch {
                    try await syncMeta.markSyncFailed(error: error.localizedDescription)
                }
            }

            return SyncCoordinatorResult(success: true, error: nil, itemsSynced: synced)
        } catch {
            return SyncCoordinatorResult(success: false, error: error.localizedDescription, itemsSynced: 0)
        }
    }

    private func syncSamples() async -> SyncCoordinatorResult {
        do {
            let context = ModelContext(modelContainer)
            let predicate = #Predicate<SyncMetadataEntity> { $0.entityType == "sample" && $0.syncStatus != "synced" }
            let descriptor = FetchDescriptor(predicate: predicate)
            let pendingSync = try context.fetch(descriptor)

            var synced = 0

            for syncMeta in pendingSync {
                do {
                    try await syncMeta.markSyncStarted()
                    try await syncMeta.markSyncSuccess()
                    synced += 1
                } catch {
                    try await syncMeta.markSyncFailed(error: error.localizedDescription)
                }
            }

            return SyncCoordinatorResult(success: true, error: nil, itemsSynced: synced)
        } catch {
            return SyncCoordinatorResult(success: false, error: error.localizedDescription, itemsSynced: 0)
        }
    }

    private func syncCaptures() async -> SyncCoordinatorResult {
        do {
            let context = ModelContext(modelContainer)
            let predicate = #Predicate<SyncMetadataEntity> { $0.entityType == "capture" && $0.syncStatus != "synced" }
            let descriptor = FetchDescriptor(predicate: predicate)
            let pendingSync = try context.fetch(descriptor)

            var synced = 0

            for syncMeta in pendingSync {
                do {
                    try await syncMeta.markSyncStarted()
                    try await syncMeta.markSyncSuccess()
                    synced += 1
                } catch {
                    try await syncMeta.markSyncFailed(error: error.localizedDescription)
                }
            }

            return SyncCoordinatorResult(success: true, error: nil, itemsSynced: synced)
        } catch {
            return SyncCoordinatorResult(success: false, error: error.localizedDescription, itemsSynced: 0)
        }
    }

    private func syncAnnotations() async -> SyncCoordinatorResult {
        do {
            let context = ModelContext(modelContainer)
            let predicate = #Predicate<SyncMetadataEntity> { $0.entityType == "annotation" && $0.syncStatus != "synced" }
            let descriptor = FetchDescriptor(predicate: predicate)
            let pendingSync = try context.fetch(descriptor)

            var synced = 0

            for syncMeta in pendingSync {
                do {
                    try await syncMeta.markSyncStarted()
                    try await syncMeta.markSyncSuccess()
                    synced += 1
                } catch {
                    try await syncMeta.markSyncFailed(error: error.localizedDescription)
                }
            }

            return SyncCoordinatorResult(success: true, error: nil, itemsSynced: synced)
        } catch {
            return SyncCoordinatorResult(success: false, error: error.localizedDescription, itemsSynced: 0)
        }
    }
}

// MARK: - Helper Extensions for SyncMetadataEntity

extension SyncMetadataEntity {
    @MainActor
    fileprivate func markSyncStarted() async throws {
        self.syncStatus = "syncing"
        self.lastSyncAttempt = Date()
        self.syncAttempts += 1
    }

    @MainActor
    fileprivate func markSyncSuccess() async throws {
        self.syncStatus = "synced"
        self.lastSyncSuccess = Date()
        self.syncError = nil
        self.hasConflict = false
        self.syncAttempts = 0
    }

    @MainActor
    fileprivate func markSyncFailed(error: String) async throws {
        self.syncError = error
        if syncAttempts >= maxSyncAttempts {
            self.syncStatus = "failed"
        } else {
            self.syncStatus = "pending"
        }
    }
}
