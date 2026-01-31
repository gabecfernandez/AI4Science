import Foundation
import os.log

/// Download error types
public enum MLDownloadError: LocalizedError {
    case invalidURL
    case downloadFailed(String)
    case validationFailed(String)
    case insufficientSpace
    case networkError(String)
    case timeout

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid download URL"
        case .downloadFailed(let error):
            return "Download failed: \(error)"
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
public struct DownloadTaskInfo: Sendable {
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
public actor MLModelDownloader {
    private let logger = Logger(subsystem: "com.ai4science.ml", category: "MLModelDownloader")

    /// Download tasks info: [taskId: downloadTask]
    private var downloadTasks: [UUID: DownloadTaskInfo] = [:]

    /// Active URL tasks
    private var activeURLTasks: [UUID: Task<String, Error>] = [:]

    public init() {
        logger.info("MLModelDownloader initialized")
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
            throw MLDownloadError.invalidURL
        }

        // Check available space
        try validateStorageSpace(for: destinationPath)

        logger.info("Starting download for model: \(modelId)")

        let taskId = UUID()

        // Use URLSession async methods
        let (downloadURL, response) = try await URLSession.shared.download(from: sourceURL)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw MLDownloadError.downloadFailed("Invalid response")
        }

        // Move to destination
        let destinationURL = URL(fileURLWithPath: destinationPath)
        let fileManager = FileManager.default

        // Remove existing file if present
        if fileManager.fileExists(atPath: destinationPath) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.moveItem(at: downloadURL, to: destinationURL)

        logger.info("Download completed for model: \(modelId)")
        return destinationPath
    }

    /// Cancel a download
    public func cancelDownload(taskId: UUID) throws {
        guard let task = activeURLTasks.removeValue(forKey: taskId) else {
            throw MLDownloadError.downloadFailed("Task not found")
        }

        task.cancel()
        downloadTasks.removeValue(forKey: taskId)
        logger.info("Download cancelled: \(taskId)")
    }

    /// Get download progress
    public func getDownloadProgress(taskId: UUID) -> Double {
        downloadTasks[taskId]?.progress ?? 0.0
    }

    /// Get all active downloads
    public func getActiveDownloads() -> [DownloadTaskInfo] {
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
            throw MLDownloadError.insufficientSpace
        }
    }
}
