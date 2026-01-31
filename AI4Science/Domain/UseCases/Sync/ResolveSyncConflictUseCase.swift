import Foundation

public struct ResolveSyncConflictUseCase: Sendable {
    private let syncRepository: any SyncRepositoryProtocol

    public init(syncRepository: any SyncRepositoryProtocol) {
        self.syncRepository = syncRepository
    }

    /// Resolves a sync conflict with specified strategy
    public func execute(
        conflict: SyncConflict,
        resolution: ConflictResolution
    ) async throws {
        try await syncRepository.resolveSyncConflict(conflict: conflict, resolution: resolution)
    }

    /// Automatically resolves conflicts using default strategy
    public func autoResolve(conflicts: [SyncConflict]) async throws -> ConflictResolutionResult {
        guard !conflicts.isEmpty else {
            throw SyncUseCaseError.validationFailed("At least one conflict is required.")
        }

        var resolvedCount = 0
        var failedConflicts: [SyncConflict] = []

        for conflict in conflicts {
            do {
                let resolution = determineAutoResolution(for: conflict)
                try await execute(conflict: conflict, resolution: resolution)
                resolvedCount += 1
            } catch {
                failedConflicts.append(conflict)
            }
        }

        return ConflictResolutionResult(
            totalConflicts: conflicts.count,
            resolvedCount: resolvedCount,
            failedCount: failedConflicts.count,
            failedConflicts: failedConflicts
        )
    }

    /// Detects conflicts between local and remote versions
    public func detectConflicts(items: [SyncQueueItem]) async throws -> [SyncConflict] {
        guard !items.isEmpty else { return [] }

        var conflicts: [SyncConflict] = []
        for item in items {
            if item.retryCount >= 3 {
                conflicts.append(
                    SyncConflict(
                        entityId: UUID(uuidString: item.resourceId) ?? UUID(),
                        entityType: "unknown",
                        type: .versionMismatch,
                        resourceId: item.resourceId,
                        localVersion: item.retryCount,
                        remoteVersion: 0
                    )
                )
            }
        }
        return conflicts
    }

    // MARK: - Private

    private func determineAutoResolution(for conflict: SyncConflict) -> ConflictResolution {
        switch conflict.type {
        case .versionMismatch:
            return .useRemote
        case .deletionConflict:
            return .useLocal
        case .modificationConflict:
            return .useNewest
        }
    }
}
