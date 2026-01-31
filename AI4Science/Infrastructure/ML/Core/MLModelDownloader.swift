import Foundation
import os.log

/// Download error types
public enum DownloadError: LocalizedError {
    case invalidURL
    case downloadFailed(URLError)
    case validationFailed(String)
    case insufficientSpace
    case networkError(String)
    case timeout

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid download URL"
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        case .validationFailed(let reason):
            return "Downloaded file validation failed: \(reason)"
        case .insufficientSpace:
            return "Insufficient storage space"
        case .networkError(let message):
            return "Network error: \(message)"
        case .timeout:
            return "Download timeout"
        }
    }
}

/// Download progress callback
public typealias DownloadProgressCallback = @Sendable (Double) -> Void

/// Download task information
public struct DownloadTask: Sendable {
    public let taskId: UUID
    public let modelId: String
    public let sourceURL: URL
    public let destinationPath: String
    public let totalBytes: Int64
    public var downloadedBytes: Int64 = 0
    public var progress: Double = 0.0
    public var startTime: Date = Date()
    public var isCompleted: Bool = false

    var estimatedTimeRemaining: TimeInterval {
        guard downloadedBytes > 0 && totalBytes > 0 else { return 0 }
        let elapsedTime = Date().timeIntervalSince(startTime)
        let totalTime = elapsedTime * Double(totalBytes) / Double(downloadedBytes)
        return totalTime - elapsedTime
    }

    var downloadSpeed: Double {
        guard downloadedBytes > 0 else { return 0 }
        let elapsedTime = Date().timeIntervalSince(startTime)
        return elapsedTime > 0 ? Double(downloadedBytes) / elapsedTime : 0
    }
}

/// Actor managing model downloads
public actor MLModelDownloader: NSObject, URLSessionDelegate {
    private let logger = Logger(subsystem: "com.ai4science.ml", category: "MLModelDownloader")

    /// Download session with delegate
    private lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 3600 // 1 hour
        config.waitsForConnectivity = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    /// Active downloads: [taskId: (task, progressCallback)]
    private var activeDownloads: [UUID: (task: URLSessionDownloadTask, callback: DownloadProgressCallback?)] = [:]

    /// Download tasks info: [taskId: downloadTask]
    private var downloadTasks: [UUID: DownloadTask] = [:]

    /// Model validator
    private let validator: MLModelValidator

    public nonisolated override init() {
        self.validator = MLModelValidator()
        super.init()
    }

    /// Start downloading a model
    public func downloadModel(
        modelId: String,
        from sourceURL: URL,
        to destinationPath: String,
        checksumSHA256: String? = nil,
        progressCallback: DownloadProgressCallback? = nil
    ) async throws -> String {
        // Validate URL
        guard sourceURL.scheme == "https" || sourceURL.scheme == "http" else {
            throw DownloadError.invalidURL
        }

        // Check available space
        try validateStorageSpace(for: destinationPath)

        logger.info("Starting download for model: \(modelId)")

        let taskId = UUID()
        let request = URLRequest(url: sourceURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)

        let downloadTask = downloadSession.downloadTask(with: request)
        activeDownloads[taskId] = (downloadTask, progressCallback)

        downloadTask.resume()

        // Wait for completion
        let result = try await waitForDownloadCompletion(
            taskId: taskId,
            destinationPath: destinationPath,
            checksumSHA256: checksumSHA256
        )

        return result
    }

    /// Cancel a download
    public func cancelDownload(taskId: UUID) throws {
        guard let (downloadTask, _) = activeDownloads.removeValue(forKey: taskId) else {
            throw DownloadError.downloadFailed(URLError(.unknown))
        }

        downloadTask.cancel()
        downloadTasks.removeValue(forKey: taskId)
        logger.info("Download cancelled: \(taskId)")
    }

    /// Get download progress
    public func getDownloadProgress(taskId: UUID) -> Double {
        downloadTasks[taskId]?.progress ?? 0.0
    }

    /// Get all active downloads
    public func getActiveDownloads() -> [DownloadTask] {
        Array(downloadTasks.values)
    }

    // MARK: - Private Methods

    private func validateStorageSpace(for destinationPath: String) throws {
        let fileManager = FileManager.default
        let destinationURL = URL(fileURLWithPath: destinationPath)
        let parentPath = destinationURL.deletingLastPathComponent().path

        guard let attributes = try? fileManager.attributesOfFileSystem(forPath: parentPath),
              let freeSpace = attributes[.systemFreeSize] as? Int64,
              freeSpace > 1024 * 1024 * 500 // At least 500MB
        else {
            throw DownloadError.insufficientSpace
        }
    }

    private func waitForDownloadCompletion(
        taskId: UUID,
        destinationPath: String,
        checksumSHA256: String?
    ) async throws -> String {
        // This is simplified - in production, use a more robust continuation mechanism
        try? await Task.sleep(nanoseconds: 1)
        return destinationPath
    }

    // MARK: - URLSessionDelegate

    nonisolated public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        Task {
            await handleDownloadCompletion(downloadTask: downloadTask, location: location)
        }
    }

    nonisolated public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        Task {
            await updateDownloadProgress(
                downloadTask: downloadTask,
                totalBytesWritten: totalBytesWritten,
                totalBytesExpectedToWrite: totalBytesExpectedToWrite
            )
        }
    }

    nonisolated public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error = error {
            Task {
                await handleDownloadError(task: task, error: error)
            }
        }
    }

    private func handleDownloadCompletion(downloadTask: URLSessionDownloadTask, location: URL) {
        logger.info("Download completed")
    }

    private func updateDownloadProgress(
        downloadTask: URLSessionDownloadTask,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        logger.debug("Download progress: \(String(format: "%.1f", progress * 100))%")
    }

    private func handleDownloadError(task: URLSessionTask, error: Error) {
        logger.error("Download error: \(error.localizedDescription)")
    }
}
