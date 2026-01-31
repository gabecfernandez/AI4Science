import Foundation
import os.log

/// Service for managing file paths and naming conventions for captures
actor MediaFileManager {
    static let shared = MediaFileManager()

    private let logger = Logger(subsystem: "com.ai4science.media", category: "MediaFileManager")

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH-mm-ss-SSSS"
        return formatter
    }()

    private let fileManager = FileManager.default

    enum FileManagerError: LocalizedError {
        case invalidPath
        case pathCreationFailed

        var errorDescription: String? {
            switch self {
            case .invalidPath:
                return "Invalid file path"
            case .pathCreationFailed:
                return "Failed to create file path"
            }
        }
    }

    nonisolated init() {
        // Empty init for actor
    }

    /// Generate unique filename for image
    func generateImageFilename(with timestamp: Date = Date()) -> String {
        let dateString = dateFormatter.string(from: timestamp)
        return "IMG_\(dateString).heic"
    }

    /// Generate unique filename for video
    func generateVideoFilename(with timestamp: Date = Date()) -> String {
        let dateString = dateFormatter.string(from: timestamp)
        return "VID_\(dateString).mp4"
    }

    /// Generate unique filename for RAW image
    func generateRawImageFilename(with timestamp: Date = Date()) -> String {
        let dateString = dateFormatter.string(from: timestamp)
        return "RAW_\(dateString).dng"
    }

    /// Generate unique filename for thumbnail
    func generateThumbnailFilename(for originalFilename: String) -> String {
        let nameWithoutExtension = (originalFilename as NSString).deletingPathExtension
        return "\(nameWithoutExtension)_thumb.jpg"
    }

    /// Get image directory path
    func getImageDirectoryPath() -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imageDirectory = documentsDirectory.appendingPathComponent("Images", isDirectory: true)

        try? fileManager.createDirectory(at: imageDirectory, withIntermediateDirectories: true)

        return imageDirectory
    }

    /// Get video directory path
    func getVideoDirectoryPath() -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoDirectory = documentsDirectory.appendingPathComponent("Videos", isDirectory: true)

        try? fileManager.createDirectory(at: videoDirectory, withIntermediateDirectories: true)

        return videoDirectory
    }

    /// Get RAW image directory path
    func getRawImageDirectoryPath() -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let rawDirectory = documentsDirectory.appendingPathComponent("RawImages", isDirectory: true)

        try? fileManager.createDirectory(at: rawDirectory, withIntermediateDirectories: true)

        return rawDirectory
    }

    /// Get thumbnail directory path
    func getThumbnailDirectoryPath() -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let thumbnailDirectory = documentsDirectory.appendingPathComponent("Thumbnails", isDirectory: true)

        try? fileManager.createDirectory(at: thumbnailDirectory, withIntermediateDirectories: true)

        return thumbnailDirectory
    }

    /// Get archive directory path
    func getArchiveDirectoryPath() -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let archiveDirectory = documentsDirectory.appendingPathComponent("Archive", isDirectory: true)

        try? fileManager.createDirectory(at: archiveDirectory, withIntermediateDirectories: true)

        return archiveDirectory
    }

    /// Get full path for image
    func getImagePath(filename: String) -> URL {
        return getImageDirectoryPath().appendingPathComponent(filename)
    }

    /// Get full path for video
    func getVideoPath(filename: String) -> URL {
        return getVideoDirectoryPath().appendingPathComponent(filename)
    }

    /// Get full path for RAW image
    func getRawImagePath(filename: String) -> URL {
        return getRawImageDirectoryPath().appendingPathComponent(filename)
    }

    /// Get full path for thumbnail
    func getThumbnailPath(filename: String) -> URL {
        return getThumbnailDirectoryPath().appendingPathComponent(filename)
    }

    /// Get full path for archive
    func getArchivePath(filename: String) -> URL {
        return getArchiveDirectoryPath().appendingPathComponent(filename)
    }

    /// Get temporary file path
    func getTemporaryFilePath(filename: String) -> URL {
        let tempDirectory = fileManager.temporaryDirectory
        return tempDirectory.appendingPathComponent(filename)
    }

    /// Parse timestamp from filename
    func parseTimestamp(from filename: String) -> Date? {
        let components = filename.split(separator: "_")
        guard components.count >= 2 else {
            return nil
        }

        let timestampWithExtension = String(components.dropFirst().joined(separator: "_"))
        let timestamp = (timestampWithExtension as NSString).deletingPathExtension

        return dateFormatter.date(from: timestamp)
    }

    /// Get all images in directory
    func getAllImages() throws -> [MediaFileInfo] {
        return try getAllFilesInDirectory(getImageDirectoryPath())
    }

    /// Get all videos in directory
    func getAllVideos() throws -> [MediaFileInfo] {
        return try getAllFilesInDirectory(getVideoDirectoryPath())
    }

    /// Get all RAW images
    func getAllRawImages() throws -> [MediaFileInfo] {
        return try getAllFilesInDirectory(getRawImageDirectoryPath())
    }

    /// Create session directory for organizing captures
    func createSessionDirectory(sessionId: String) throws -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let sessionDirectory = documentsDirectory
            .appendingPathComponent("Sessions", isDirectory: true)
            .appendingPathComponent(sessionId, isDirectory: true)

        try fileManager.createDirectory(at: sessionDirectory, withIntermediateDirectories: true)

        logger.info("Session directory created: \(sessionId)")
        return sessionDirectory
    }

    /// Get session media directory
    func getSessionMediaDirectory(sessionId: String) throws -> URL {
        let sessionDirectory = try createSessionDirectory(sessionId: sessionId)
        let mediaDirectory = sessionDirectory.appendingPathComponent("Media", isDirectory: true)

        try fileManager.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)

        return mediaDirectory
    }

    // MARK: - Private Methods

    private func getAllFilesInDirectory(_ directory: URL) throws -> [MediaFileInfo] {
        guard fileManager.fileExists(atPath: directory.path) else {
            return []
        }

        let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)

        var mediaFiles: [MediaFileInfo] = []

        for file in files {
            let attributes = try fileManager.attributesOfItem(atPath: file.path)

            let fileInfo = MediaFileInfo(
                url: file,
                filename: file.lastPathComponent,
                fileSize: attributes[.size] as? Int64 ?? 0,
                createdDate: attributes[.creationDate] as? Date,
                modifiedDate: attributes[.modificationDate] as? Date
            )

            mediaFiles.append(fileInfo)
        }

        return mediaFiles.sorted { ($0.modifiedDate ?? Date()) > ($1.modifiedDate ?? Date()) }
    }
}

struct MediaFileInfo {
    let url: URL
    let filename: String
    let fileSize: Int64
    let createdDate: Date?
    let modifiedDate: Date?

    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    var pathExtension: String {
        return url.pathExtension.lowercased()
    }

    var isImage: Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "heic", "tiff", "gif"]
        return imageExtensions.contains(pathExtension)
    }

    var isVideo: Bool {
        let videoExtensions = ["mp4", "mov", "m4v", "avi", "mkv"]
        return videoExtensions.contains(pathExtension)
    }

    var isRaw: Bool {
        let rawExtensions = ["dng", "raw", "cr2", "nef"]
        return rawExtensions.contains(pathExtension)
    }
}
