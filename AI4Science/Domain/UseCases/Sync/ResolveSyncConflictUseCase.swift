import Foundation

public struct ResolveSyncConflictUseCase: Sendable {
    private let syncRepository: any SyncRepositoryProtocol

    public init(syncRepository: any SyncRepositoryProtocol) {
        self.syncRepository = syncRepository
    }

    /// Resolves a sync conflict with specified strategy
    /// - Parameters:
    ///   - conflict: The sync conflict to resolve
    ///   - resolution: Resolution strategy
    /// - Throws: SyncUseCaseError if resolution fails
    func execute(
        conflict: UseCaseSyncConflict,
        resolution: UseCaseConflictResolution
    ) async throws {
        // Convert to repository types and resolve
        try await syncRepository.resolveSyncConflict(
            conflictId: conflict.id,
            resolution: mapResolution(resolution)
        )
    }

    /// Automatically resolves conflicts using default strategy
    /// - Parameter conflicts: Array of conflicts to resolve
    /// - Returns: UseCaseConflictResolutionResult
    /// - Throws: SyncUseCaseError if resolution fails
    func autoResolve(conflicts: [UseCaseSyncConflict]) async throws -> UseCaseConflictResolutionResult {
        guard !conflicts.isEmpty else {
            throw SyncUseCaseError.validationFailed("At least one conflict is required.")
        }

        var resolvedCount = 0
        var failedConflicts: [UseCaseSyncConflict] = []

        for conflict in conflicts {
            do {
                let resolution = determineAutoResolution(for: conflict)
                try await execute(conflict: conflict, resolution: resolution)
                resolvedCount += 1
            } catch {
                failedConflicts.append(conflict)
            }
        }

        return UseCaseConflictResolutionResult(
            totalConflicts: conflicts.count,
            resolvedCount: resolvedCount,
            failedCount: failedConflicts.count,
            failedConflicts: failedConflicts
        )
    }

    /// Detects conflicts between local and remote versions
    /// - Parameter items: Items to check for conflicts
    /// - Returns: Array of detected conflicts
    /// - Throws: SyncUseCaseError if detection fails
    func detectConflicts(items: [SyncQueueItem]) async throws -> [UseCaseSyncConflict] {
        guard !items.isEmpty else {
            return []
        }

        var conflicts: [UseCaseSyncConflict] = []

        for item in items {
            // Placeholder for conflict detection logic
            // In production, this would compare local vs remote versions
            if item.retryCount >= 3 {
                conflicts.append(
                    UseCaseSyncConflict(
                        id: UUID().uuidString,
                        type: .versionMismatch,
                        resourceId: item.resourceId,
                        localVersion: item.retryCount,
                        remoteVersion: 0,
                        detectedAt: Date()
                    )
                )
            }
        }

        return conflicts
    }

    // MARK: - Private Methods

    private func determineAutoResolution(for conflict: UseCaseSyncConflict) -> UseCaseConflictResolution {
        switch conflict.type {
        case .versionMismatch:
            return .useRemote
        case .deletionConflict:
            return .keepLocal
        case .modificationConflict:
            return .useNewest
        }
    }

    private func mapResolution(_ resolution: UseCaseConflictResolution) -> SyncResolutionType {
        switch resolution {
        case .useLocal, .keepLocal:
            return .useLocal
        case .useRemote:
            return .useRemote
        case .useNewest, .custom:
            return .merge
        }
    }
}

// MARK: - Supporting Types (Local to this Use Case)

/// Sync conflict representation for this use case
struct UseCaseSyncConflict: Sendable, Identifiable {
    let id: String
    let type: UseCaseConflictType
    let resourceId: String
    let localVersion: Int
    let remoteVersion: Int
    let detectedAt: Date
    let description: String?

    init(
        id: String = UUID().uuidString,
        type: UseCaseConflictType,
        resourceId: String,
        localVersion: Int,
        remoteVersion: Int,
        detectedAt: Date = Date(),
        description: String? = nil
    ) {
        self.id = id
        self.type = type
        self.resourceId = resourceId
        self.localVersion = localVersion
        self.remoteVersion = remoteVersion
        self.detectedAt = detectedAt
        self.description = description
    }
}

enum UseCaseConflictType: Sendable {
    case versionMismatch
    case deletionConflict
    case modificationConflict

    var description: String {
        switch self {
        case .versionMismatch:
            return "Version Mismatch"
        case .deletionConflict:
            return "Deletion Conflict"
        case .modificationConflict:
            return "Modification Conflict"
        }
    }
}

enum UseCaseConflictResolution: Sendable {
    case useLocal
    case useRemote
    case useNewest
    case keepLocal
    case custom(String)

    var description: String {
        switch self {
        case .useLocal, .keepLocal:
            return "Use local version"
        case .useRemote:
            return "Use remote version"
        case .useNewest:
            return "Use newest version"
        case .custom(let strategy):
            return "Custom: \(strategy)"
        }
    }
}

struct UseCaseConflictResolutionResult: Sendable {
    let totalConflicts: Int
    let resolvedCount: Int
    let failedCount: Int
    let failedConflicts: [UseCaseSyncConflict]

    var resolutionRate: Float {
        guard totalConflicts > 0 else { return 1.0 }
        return Float(resolvedCount) / Float(totalConflicts)
    }

    var isSuccessful: Bool {
        failedCount == 0
    }

    init(
        totalConflicts: Int,
        resolvedCount: Int,
        failedCount: Int,
        failedConflicts: [UseCaseSyncConflict]
    ) {
        self.totalConflicts = totalConflicts
        self.resolvedCount = resolvedCount
        self.failedCount = failedCount
        self.failedConflicts = failedConflicts
    }
}

public struct ConflictStrategy: Sendable {
    public let strategyName: String
    public let description: String
    public let isAutomatic: Bool
    public let requiresUserInput: Bool

    public init(
        strategyName: String,
        description: String,
        isAutomatic: Bool = true,
        requiresUserInput: Bool = false
    ) {
        self.strategyName = strategyName
        self.description = description
        self.isAutomatic = isAutomatic
        self.requiresUserInput = requiresUserInput
    }
}
