import Foundation

/// Protocol for entities that support offline sync
/// Note: SyncStatus enum is defined in Core/Models/SyncStatus.swift
public protocol Syncable: Sendable {
    var isSyncPending: Bool { get }
    var lastSyncDate: Date? { get }
    var syncStatus: SyncStatus { get }
}

/// Protocol for sync operations
public protocol SyncEngine: Sendable {
    /// Sync all pending changes
    func syncAll() async throws

    /// Sync specific entity
    func sync<T: Identifiable>(entity: T) async throws where T.ID == UUID

    /// Get sync status
    func getSyncStatus() async -> SyncStatus

    /// Get pending changes count
    func getPendingChangesCount() async throws -> Int

    /// Resolve sync conflict
    func resolveConflict<T: Identifiable>(
        localEntity: T,
        remoteEntity: T,
        strategy: ConflictResolutionStrategy
    ) async throws where T.ID == UUID

    /// Clear sync history
    func clearSyncHistory() async throws

    /// Enable/disable automatic sync
    func setAutoSyncEnabled(_ enabled: Bool) async
}

/// Strategy for resolving sync conflicts
@frozen
public enum ConflictResolutionStrategy: String, Sendable {
    case keepLocal
    case keepRemote
    case keepNewest
    case manual
}
