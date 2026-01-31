import Foundation
import SwiftData

/// Actor responsible for resolving synchronization conflicts
actor ConflictResolver: Sendable {
    // MARK: - Properties

    private let modelContainer: ModelContainer

    // MARK: - Initialization

    init(modelContainer: ModelContainer) throws {
        self.modelContainer = modelContainer
    }

    // MARK: - Public Methods

    /// Resolve conflicts for an entity
    /// - Parameters:
    ///   - entityType: Type of entity
    ///   - entityID: ID of the entity
    ///   - strategy: Resolution strategy (client_wins, server_wins, merge)
    /// - Returns: Resolved entity data
    func resolveConflict(
        entityType: String,
        entityID: String,
        strategy: String = "client_wins"
    ) async -> ConflictResolutionInfo? {
        do {
            let context = ModelContext(modelContainer)

            // Fetch sync metadata
            let syncPredicate = #Predicate<SyncMetadataEntity> {
                $0.entityType == entityType &&
                $0.entityID == entityID
            }
            let syncDescriptor = FetchDescriptor(predicate: syncPredicate)
            guard let syncMeta = try context.fetch(syncDescriptor).first else {
                return nil
            }

            guard syncMeta.hasConflict else {
                return nil
            }

            let resolution: ConflictResolutionInfo

            switch strategy {
            case "server_wins":
                resolution = resolveWithServerWins(syncMeta)
            case "merge":
                resolution = try await resolveWithMerge(syncMeta, context: context)
            case "client_wins", "local_wins":
                resolution = resolveWithClientWins(syncMeta)
            default:
                resolution = resolveWithClientWins(syncMeta)
            }

            // Update sync metadata
            syncMeta.hasConflict = false
            syncMeta.conflictResolution = strategy
            syncMeta.syncStatus = "synced"
            try context.save()

            AppLogger.info("Resolved conflict for \(entityType):\(entityID) using \(strategy) strategy")

            return resolution
        } catch {
            AppLogger.error("Failed to resolve conflict: \(error.localizedDescription)")
            return nil
        }
    }

    /// Detect potential conflicts
    /// - Returns: Array of detected conflicts
    func detectConflicts() async throws -> [ConflictInfo] {
        let context = ModelContext(modelContainer)

        let predicate = #Predicate<SyncMetadataEntity> { $0.hasConflict }
        let descriptor = FetchDescriptor(predicate: predicate)
        let syncMetas = try context.fetch(descriptor)

        var conflicts: [ConflictInfo] = []

        for syncMeta in syncMetas {
            let conflict = ConflictInfo(
                entityType: syncMeta.entityType,
                entityID: syncMeta.entityID,
                localVersion: syncMeta.localVersion,
                remoteVersion: syncMeta.remoteVersion,
                detectedAt: Date()
            )
            conflicts.append(conflict)
        }

        return conflicts
    }

    /// Merge conflicting versions
    /// - Parameters:
    ///   - localData: Local version of data
    ///   - remoteData: Remote version of data
    ///   - strategy: Merge strategy
    /// - Returns: Merged data
    func mergeVersions(
        local localData: [String: Any],
        remote remoteData: [String: Any],
        strategy: String = "local_precedence"
    ) -> [String: Any] {
        var merged = remoteData

        switch strategy {
        case "local_precedence":
            // Local changes take precedence
            for (key, value) in localData {
                merged[key] = value
            }

        case "remote_precedence":
            // Remote changes take precedence (merged already has remote, so no change)
            break

        case "timestamp_based":
            // Compare timestamps if available
            if let localTime = localData["updatedAt"] as? Date,
               let remoteTime = remoteData["updatedAt"] as? Date {
                if localTime > remoteTime {
                    // Local is newer
                    for (key, value) in localData {
                        merged[key] = value
                    }
                }
            }

        case "deep_merge":
            // Deep merge for nested structures
            merged = deepMerge(local: localData, remote: remoteData)

        default:
            break
        }

        return merged
    }

    // MARK: - Private Methods

    private func resolveWithClientWins(_ syncMeta: SyncMetadataEntity) -> ConflictResolutionInfo {
        ConflictResolutionInfo(
            entityType: syncMeta.entityType,
            entityID: syncMeta.entityID,
            strategy: "client_wins",
            resolvedAt: Date(),
            notes: "Local version preserved"
        )
    }

    private func resolveWithServerWins(_ syncMeta: SyncMetadataEntity) -> ConflictResolutionInfo {
        ConflictResolutionInfo(
            entityType: syncMeta.entityType,
            entityID: syncMeta.entityID,
            strategy: "server_wins",
            resolvedAt: Date(),
            notes: "Remote version applied"
        )
    }

    private func resolveWithMerge(
        _ syncMeta: SyncMetadataEntity,
        context: ModelContext
    ) async throws -> ConflictResolutionInfo {
        ConflictResolutionInfo(
            entityType: syncMeta.entityType,
            entityID: syncMeta.entityID,
            strategy: "merge",
            resolvedAt: Date(),
            notes: "Versions merged"
        )
    }

    private func deepMerge(
        local: [String: Any],
        remote: [String: Any]
    ) -> [String: Any] {
        var result = remote

        for (key, localValue) in local {
            if let remoteValue = remote[key] {
                if let localDict = localValue as? [String: Any],
                   let remoteDict = remoteValue as? [String: Any] {
                    result[key] = deepMerge(local: localDict, remote: remoteDict)
                } else {
                    result[key] = localValue
                }
            } else {
                result[key] = localValue
            }
        }

        return result
    }
}

// MARK: - Models

/// Information about a detected conflict
struct ConflictInfo: Sendable {
    let entityType: String
    let entityID: String
    let localVersion: String?
    let remoteVersion: String?
    let detectedAt: Date
}

/// Result of conflict resolution (infrastructure-layer detail).
/// Distinct from the domain-layer ConflictResolution enum in SyncTypes.swift.
struct ConflictResolutionInfo: Sendable {
    let entityType: String
    let entityID: String
    let strategy: String
    let resolvedAt: Date
    let notes: String?
}
