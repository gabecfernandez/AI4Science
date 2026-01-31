import Foundation

public struct UpdateMLModelUseCase: Sendable {
    private let mlRepository: any MLRepositoryProtocol

    public init(mlRepository: any MLRepositoryProtocol) {
        self.mlRepository = mlRepository
    }

    /// Checks if updates are available for a model
    /// - Parameter modelId: Model identifier
    /// - Returns: ModelUpdateInfo if update available, nil otherwise
    /// - Throws: MLError if check fails
    public func checkForUpdates(modelId: String) async throws -> ModelUpdateInfo? {
        guard !modelId.isEmpty else {
            throw MLError.validationFailed("Model ID is required.")
        }

        return try await mlRepository.checkModelUpdates(modelId: modelId)
    }

    /// Checks for updates across multiple models
    /// - Parameter modelIds: Array of model identifiers
    /// - Returns: Array of available updates
    /// - Throws: MLError if check fails
    public func checkForUpdates(modelIds: [String]) async throws -> [ModelUpdateInfo] {
        guard !modelIds.isEmpty else {
            throw MLError.validationFailed("At least one model ID is required.")
        }

        var updates: [ModelUpdateInfo] = []

        for modelId in modelIds {
            if let update = try await checkForUpdates(modelId: modelId) {
                updates.append(update)
            }
        }

        return updates
    }

    /// Checks for updates for all installed models
    /// - Returns: Array of available updates
    /// - Throws: MLError if check fails
    public func checkForAllUpdates() async throws -> [ModelUpdateInfo] {
        let allModels = try await mlRepository.listAvailableModels()
        let modelIds = allModels.map { $0.id }
        return try await checkForUpdates(modelIds: modelIds)
    }

    /// Downloads and installs a model update
    /// - Parameter updateInfo: Update information
    /// - Returns: Updated LoadedModelInfo
    /// - Throws: MLError if update fails
    public func installUpdate(_ updateInfo: ModelUpdateInfo) async throws -> LoadedModelInfo {
        guard !updateInfo.modelId.isEmpty else {
            throw MLError.validationFailed("Model ID is required.")
        }

        guard !updateInfo.newVersion.isEmpty else {
            throw MLError.validationFailed("New version is required.")
        }

        // Download and install the update
        let progress = try await mlRepository.downloadModel(modelId: updateInfo.modelId)

        guard progress.status == .completed else {
            throw MLError.serverError(message: "Update download failed")
        }

        // Verify the update
        let modelInfo = try await mlRepository.getModelInfo(modelId: updateInfo.modelId)
        return modelInfo
    }

    /// Automatically installs all available updates
    /// - Returns: UpdateInstallationResult
    /// - Throws: MLError if operation fails
    public func installAllUpdates() async throws -> UpdateInstallationResult {
        let availableUpdates = try await checkForAllUpdates()

        guard !availableUpdates.isEmpty else {
            return UpdateInstallationResult(
                totalUpdatesAvailable: 0,
                successCount: 0,
                failureCount: 0,
                failedUpdates: [],
                startTime: Date()
            )
        }

        let startTime = Date()
        var successCount = 0
        var failedUpdates: [ModelUpdateInfo] = []

        // Install updates in parallel
        let updateResults: [(ModelUpdateInfo, Bool)] = try await withThrowingTaskGroup(
            of: (ModelUpdateInfo, Bool).self
        ) { taskGroup in
            for update in availableUpdates {
                taskGroup.addTask {
                    do {
                        _ = try await self.installUpdate(update)
                        return (update, true)
                    } catch {
                        return (update, false)
                    }
                }
            }

            var allResults: [(ModelUpdateInfo, Bool)] = []
            for try await result in taskGroup {
                allResults.append(result)
            }
            return allResults
        }

        for (update, success) in updateResults {
            if success {
                successCount += 1
            } else {
                failedUpdates.append(update)
            }
        }

        return UpdateInstallationResult(
            totalUpdatesAvailable: availableUpdates.count,
            successCount: successCount,
            failureCount: failedUpdates.count,
            failedUpdates: failedUpdates,
            startTime: startTime
        )
    }
}

// MARK: - Supporting Types

public struct ModelUpdateInfo: Sendable {
    public let modelId: String
    public let modelName: String
    public let currentVersion: String
    public let newVersion: String
    public let releaseDate: Date
    public let changeLog: String
    public let fileSize: Int
    public let improvementNotes: [String]
    public let isSecurityUpdate: Bool

    public var versionBump: String {
        "\(currentVersion) → \(newVersion)"
    }

    public init(
        modelId: String,
        modelName: String,
        currentVersion: String,
        newVersion: String,
        releaseDate: Date,
        changeLog: String,
        fileSize: Int,
        improvementNotes: [String],
        isSecurityUpdate: Bool = false
    ) {
        self.modelId = modelId
        self.modelName = modelName
        self.currentVersion = currentVersion
        self.newVersion = newVersion
        self.releaseDate = releaseDate
        self.changeLog = changeLog
        self.fileSize = fileSize
        self.improvementNotes = improvementNotes
        self.isSecurityUpdate = isSecurityUpdate
    }
}

public struct UpdateInstallationResult: Sendable {
    public let totalUpdatesAvailable: Int
    public let successCount: Int
    public let failureCount: Int
    public let failedUpdates: [ModelUpdateInfo]
    public let startTime: Date

    public var isSuccessful: Bool {
        failureCount == 0
    }

    public var partialSuccess: Bool {
        successCount > 0 && failureCount > 0
    }

    public var totalProcessingTime: TimeInterval {
        Date().timeIntervalSince(startTime)
    }

    public init(
        totalUpdatesAvailable: Int,
        successCount: Int,
        failureCount: Int,
        failedUpdates: [ModelUpdateInfo],
        startTime: Date
    ) {
        self.totalUpdatesAvailable = totalUpdatesAvailable
        self.successCount = successCount
        self.failureCount = failureCount
        self.failedUpdates = failedUpdates
        self.startTime = startTime
    }
}

public struct VersionInfo: Sendable, Codable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public var description: String {
        "\(major).\(minor).\(patch)"
    }

    public func isOlderThan(_ other: VersionInfo) -> Bool {
        if major != other.major {
            return major < other.major
        }
        if minor != other.minor {
            return minor < other.minor
        }
        return patch < other.patch
    }

    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
}
