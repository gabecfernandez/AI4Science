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
    /// - Throws: SyncError if resolution fails
    public func execute(
        conflict: SyncConflict,
        resolution: ConflictResolution
    ) async throws {
        try await syncRepository.resolveSyncConflict(conflict: conflict, resolution: resolution)
    }

    /// Automatically resolves conflicts using default strategy
    /// - Parameter conflicts: Array of conflicts to resolve
    /// - Returns: ConflictResolutionResult
    /// - Throws: SyncError if resolution fails
    public func autoResolve(conflicts: [SyncConflict]) async throws -> ConflictResolutionResult {
        guard !conflicts.isEmpty else {
            throw SyncError.validationFailed("At least one conflict is required.")
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
    /// - Parameter items: Items to check for conflicts
    /// - Returns: Array of detected conflicts
    /// - Throws: SyncError if detection fails
    public func detectConflicts(items: [SyncQueueItem]) async throws -> [SyncConflict] {
        guard !items.isEmpty else {
            return []
        }

        var conflicts: [SyncConflict] = []

        for item in items {
            // Placeholder for conflict detection logic
            // In production, this would compare local vs remote versions
            if item.retryCount >= 3 {
                conflicts.append(
                    SyncConflict(
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

    private func determineAutoResolution(for conflict: SyncConflict) -> ConflictResolution {
        switch conflict.type {
        case .versionMismatch:
            return .useRemote
        case .deletionConflict:
            return .keepLocal
        case .modificationConflict:
            return .useNewest
        }
    }
}

// MARK: - Supporting Types

public struct SyncConflict: Sendable, Identifiable {
    public let id: String
    public let type: ConflictType
    public let resourceId: String
    public let localVersion: Int
    public let remoteVersion: Int
    public let detectedAt: Date
    public let description: String?

    public init(
        id: String = UUID().uuidString,
        type: ConflictType,
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

public enum ConflictType: Sendable {
    case versionMismatch
    case deletionConflict
    case modificationConflict

    public var description: String {
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

public enum ConflictResolution: Sendable {
    case useLocal
    case useRemote
    case useNewest
    case custom(String)

    public var description: String {
        switch self {
        case .useLocal:
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

public struct ConflictResolutionResult: Sendable {
    public let totalConflicts: Int
    public let resolvedCount: Int
    public let failedCount: Int
    public let failedConflicts: [SyncConflict]

    public var resolutionRate: Float {
        guard totalConflicts > 0 else { return 1.0 }
        return Float(resolvedCount) / Float(totalConflicts)
    }

    public var isSuccessful: Bool {
        failedCount == 0
    }

    public init(
        totalConflicts: Int,
        resolvedCount: Int,
        failedCount: Int,
        failedConflicts: [SyncConflict]
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
