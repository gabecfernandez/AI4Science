import Foundation
import os.log

/// Service for downloading and caching ML models locally
/// Manages model downloads, caching, and versioning
actor ModelDownloadService {
    static let shared = ModelDownloadService()

    private let logger = Logger(subsystem: "com.ai4science.ml", category: "ModelDownloadService")
    private let modelCacheDirectory: URL
    private let modelRegistry: ModelRegistry
    private var activeDownloads: [String: Task<Void, Error>] = [:]

    private init(registry: ModelRegistry = .shared) {
        self.modelRegistry = registry

        // Create cache directory
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        self.modelCacheDirectory = paths[0].appendingPathComponent("AIModels", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: modelCacheDirectory, withIntermediateDirectories: true)
            logger.debug("Model cache directory created: \(self.modelCacheDirectory.path)")
        } catch {
            logger.error("Failed to create model cache directory: \(error.localizedDescription)")
        }
    }

    // MARK: - Model Download

    /// Download a model from remote URL and cache it locally
    /// - Parameters:
    ///   - modelName: Name of the model
    ///   - url: Remote URL to download from
    ///   - progress: Closure to report download progress
    /// - Throws: DownloadError if download fails
    func downloadModel(
        named modelName: String,
        from url: URL,
        progress: @escaping (Double) -> Void = { _ in }
    ) async throws {
        // Check if already cached
        if isModelCached(modelName) {
            logger.debug("Model already cached: \(modelName)")
            progress(1.0)
            return
        }

        // Prevent duplicate downloads
        if activeDownloads[modelName] != nil {
            logger.debug("Model download already in progress: \(modelName)")
            try await activeDownloads[modelName]?.value
            return
        }

        let task = Task {
            let destination = modelCacheDirectory.appendingPathComponent(modelName)
            try await performDownload(from: url, to: destination, progress: progress)
            logger.debug("Model downloaded successfully: \(modelName)")
        }

        activeDownloads[modelName] = task

        defer {
            activeDownloads.removeValue(forKey: modelName)
        }
        try await task.value
    }

    /// Download multiple models concurrently
    /// - Parameters:
    ///   - models: Dictionary of model names to URLs
    ///   - progress: Closure reporting overall progress
    /// - Throws: DownloadError if any download fails
    func downloadModels(
        _ models: [String: URL],
        progress: @escaping (String, Double) -> Void = { _, _ in }
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (modelName, url) in models {
                group.addTask {
                    try await self.downloadModel(
                        named: modelName,
                        from: url,
                        progress: { modelProgress in
                            progress(modelName, modelProgress)
                        }
                    )
                }
            }

            try await group.waitForAll()
        }
    }

    // MARK: - Cache Management

    /// Check if a model is cached locally
    /// - Parameter modelName: Name of the model
    /// - Returns: true if model exists in cache
    func isModelCached(_ modelName: String) -> Bool {
        let modelPath = modelCacheDirectory.appendingPathComponent(modelName)
        return FileManager.default.fileExists(atPath: modelPath.path)
    }

    /// Get the local URL of a cached model
    /// - Parameter modelName: Name of the model
    /// - Returns: URL to cached model or nil if not cached
    func getCachedModelURL(_ modelName: String) -> URL? {
        guard isModelCached(modelName) else { return nil }
        return modelCacheDirectory.appendingPathComponent(modelName)
    }

    /// Get cache size information
    /// - Returns: CacheSizeInfo with total and per-model sizes
    func getCacheInfo() -> CacheSizeInfo {
        let fileManager = FileManager.default

        do {
            let files = try fileManager.contentsOfDirectory(
                at: modelCacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey]
            )

            var totalSize: Int64 = 0
            var modelSizes: [String: Int64] = [:]

            for file in files {
                let resourceValues = try file.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = resourceValues.fileSize {
                    let size = Int64(fileSize)
                    totalSize += size
                    modelSizes[file.lastPathComponent] = size
                }
            }

            return CacheSizeInfo(
                totalSize: totalSize,
                modelCount: files.count,
                modelSizes: modelSizes
            )
        } catch {
            logger.error("Failed to get cache info: \(error.localizedDescription)")
            return CacheSizeInfo(totalSize: 0, modelCount: 0, modelSizes: [:])
        }
    }

    /// Clear a specific cached model
    /// - Parameter modelName: Name of the model to clear
    /// - Throws: FileManagerError if deletion fails
    func clearCachedModel(_ modelName: String) throws {
        let modelPath = modelCacheDirectory.appendingPathComponent(modelName)
        try FileManager.default.removeItem(at: modelPath)
        logger.debug("Cleared cached model: \(modelName)")
    }

    /// Clear all cached models
    /// - Throws: FileManagerError if deletion fails
    func clearAllCachedModels() throws {
        try FileManager.default.removeItem(at: modelCacheDirectory)
        try FileManager.default.createDirectory(at: modelCacheDirectory, withIntermediateDirectories: true)
        logger.debug("Cleared all cached models")
    }

    // MARK: - Model Validation

    /// Validate a downloaded model
    /// - Parameter modelName: Name of the model to validate
    /// - Returns: true if model is valid
    func validateModel(_ modelName: String) -> Bool {
        guard let modelURL = getCachedModelURL(modelName) else {
            logger.warning("Model not found: \(modelName)")
            return false
        }

        let fileManager = FileManager.default

        // Check file exists
        guard fileManager.fileExists(atPath: modelURL.path) else {
            return false
        }

        // Check file size
        do {
            let resourceValues = try modelURL.resourceValues(forKeys: [.fileSizeKey])
            guard let fileSize = resourceValues.fileSize, fileSize > 0 else {
                return false
            }
        } catch {
            logger.error("Failed to validate model: \(error.localizedDescription)")
            return false
        }

        return true
    }

    // MARK: - Private Helpers

    private func performDownload(
        from url: URL,
        to destination: URL,
        progress: @escaping (Double) -> Void
    ) async throws {
        let urlSession = URLSession(configuration: .default)
        let delegate = DownloadDelegate(progress: progress)

        let (downloadURL, response) = try await urlSession.download(from: url, delegate: delegate)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw DownloadError.invalidResponse
        }

        try FileManager.default.moveItem(at: downloadURL, to: destination)
    }
}

// MARK: - Download Delegate

private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let progress: (Double) -> Void
    private var totalBytesExpectedToWrite: Int64 = 0

    init(progress: @escaping (Double) -> Void) {
        self.progress = progress
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // Handled by async/await
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        self.totalBytesExpectedToWrite = totalBytesExpectedToWrite
        let progressValue = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progress(progressValue)
        }
    }
}

// MARK: - Result Types

struct CacheSizeInfo: Sendable {
    let totalSize: Int64
    let modelCount: Int
    let modelSizes: [String: Int64]

    var totalSizeInMB: Double {
        Double(totalSize) / (1024 * 1024)
    }
}

// MARK: - Error Types

enum DownloadError: LocalizedError {
    case invalidURL
    case invalidResponse
    case downloadFailed(String)
    case fileSystemError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid download URL"
        case .invalidResponse:
            return "Invalid server response"
        case .downloadFailed(let reason):
            return "Download failed: \(reason)"
        case .fileSystemError(let reason):
            return "File system error: \(reason)"
        }
    }
}
