import Foundation

public struct DownloadMLModelUseCase: Sendable {
    private let mlRepository: any MLRepositoryProtocol

    public init(mlRepository: any MLRepositoryProtocol) {
        self.mlRepository = mlRepository
    }

    /// Downloads an ML model for offline use
    /// - Parameter modelId: Model identifier
    /// - Returns: ModelDownloadProgress tracking download completion
    /// - Throws: MLError if download fails
    public func execute(modelId: String) async throws -> ModelDownloadProgress {
        guard !modelId.isEmpty else {
            throw MLError.validationFailed("Model ID is required.")
        }

        let progress = try await mlRepository.downloadModel(modelId: modelId)
        return progress
    }

    /// Downloads multiple models concurrently
    /// - Parameter modelIds: Array of model identifiers
    /// - Returns: BatchDownloadResult with all progress info
    /// - Throws: MLError if operation fails
    public func downloadMultiple(modelIds: [String]) async throws -> BatchDownloadResult {
        guard !modelIds.isEmpty else {
            throw MLError.validationFailed("At least one model ID is required.")
        }

        let startTime = Date()
        var downloads: [ModelDownloadProgress] = []
        var failedIds: [String] = []

        // Download models in parallel
        let downloadResults: [(String, ModelDownloadProgress?)] = try await withThrowingTaskGroup(
            of: (String, ModelDownloadProgress?).self
        ) { taskGroup in
            for modelId in modelIds {
                taskGroup.addTask {
                    do {
                        let progress = try await self.mlRepository.downloadModel(modelId: modelId)
                        return (modelId, progress)
                    } catch {
                        return (modelId, nil)
                    }
                }
            }

            var allResults: [(String, ModelDownloadProgress?)] = []
            for try await result in taskGroup {
                allResults.append(result)
            }
            return allResults
        }

        for (modelId, progress) in downloadResults {
            if let progress = progress {
                downloads.append(progress)
            } else {
                failedIds.append(modelId)
            }
        }

        let totalSize = downloads.reduce(0) { $0 + $1.totalSize }
        let downloadedSize = downloads.reduce(0) { $0 + $1.downloadedSize }

        return BatchDownloadResult(
            totalModelsCount: modelIds.count,
            successCount: downloads.count,
            failureCount: failedIds.count,
            downloads: downloads,
            failedModelIds: failedIds,
            totalSize: totalSize,
            downloadedSize: downloadedSize,
            startTime: startTime
        )
    }

    /// Cancels an ongoing model download
    /// - Parameter modelId: Model identifier
    /// - Throws: MLError if cancellation fails
    public func cancel(modelId: String) async throws {
        guard !modelId.isEmpty else {
            throw MLError.validationFailed("Model ID is required.")
        }

        // Implementation would cancel the download
        // This is a placeholder for repository method
    }
}

// MARK: - Supporting Types

public struct ModelDownloadProgress: Sendable {
    public let modelId: String
    public let modelName: String
    public let totalSize: Int
    public let downloadedSize: Int
    public let status: DownloadStatus
    public let estimatedTimeRemaining: TimeInterval?
    public let downloadSpeed: Int? // bytes per second

    public var progress: Float {
        guard totalSize > 0 else { return 0 }
        return Float(downloadedSize) / Float(totalSize)
    }

    public var isComplete: Bool {
        status == .completed
    }

    public init(
        modelId: String,
        modelName: String,
        totalSize: Int,
        downloadedSize: Int,
        status: DownloadStatus,
        estimatedTimeRemaining: TimeInterval? = nil,
        downloadSpeed: Int? = nil
    ) {
        self.modelId = modelId
        self.modelName = modelName
        self.totalSize = totalSize
        self.downloadedSize = downloadedSize
        self.status = status
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.downloadSpeed = downloadSpeed
    }
}

public enum DownloadStatus: Sendable, Equatable {
    case pending
    case downloading
    case paused
    case completed
    case failed(String)
    case cancelled

    public var isActive: Bool {
        self == .downloading
    }
}

public struct BatchDownloadResult: Sendable {
    public let totalModelsCount: Int
    public let successCount: Int
    public let failureCount: Int
    public let downloads: [ModelDownloadProgress]
    public let failedModelIds: [String]
    public let totalSize: Int
    public let downloadedSize: Int
    public let startTime: Date

    public var overallProgress: Float {
        guard totalSize > 0 else { return 0 }
        return Float(downloadedSize) / Float(totalSize)
    }

    public var averageDownloadSpeed: Int {
        let elapsed = Date().timeIntervalSince(startTime)
        guard elapsed > 0 else { return 0 }
        return Int(Double(downloadedSize) / elapsed)
    }

    public var estimatedTotalTime: TimeInterval {
        let avgSpeed = Double(averageDownloadSpeed)
        guard avgSpeed > 0 else { return 0 }
        return Double(totalSize) / avgSpeed
    }

    public var isSuccessful: Bool {
        failureCount == 0
    }

    public init(
        totalModelsCount: Int,
        successCount: Int,
        failureCount: Int,
        downloads: [ModelDownloadProgress],
        failedModelIds: [String],
        totalSize: Int,
        downloadedSize: Int,
        startTime: Date
    ) {
        self.totalModelsCount = totalModelsCount
        self.successCount = successCount
        self.failureCount = failureCount
        self.downloads = downloads
        self.failedModelIds = failedModelIds
        self.totalSize = totalSize
        self.downloadedSize = downloadedSize
        self.startTime = startTime
    }
}

public struct DownloadOptions: Sendable {
    public let cellularAllowed: Bool
    public let lowPowerMode: Bool
    public let maxConcurrentDownloads: Int

    public init(
        cellularAllowed: Bool = false,
        lowPowerMode: Bool = false,
        maxConcurrentDownloads: Int = 3
    ) {
        self.cellularAllowed = cellularAllowed
        self.lowPowerMode = lowPowerMode
        self.maxConcurrentDownloads = maxConcurrentDownloads
    }
}
