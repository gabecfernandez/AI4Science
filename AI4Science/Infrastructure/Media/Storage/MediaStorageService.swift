import Foundation
import os.log

/// Actor for managing media file storage operations
actor MediaStorageService {
    static let shared = MediaStorageService()

    private let logger = Logger(subsystem: "com.ai4science.media", category: "MediaStorageService")

    private let documentsDirectory: URL
    private let mediaDirectory: URL
    private let cacheDirectory: URL

    enum StorageError: LocalizedError {
        case directoryCreationFailed
        case saveFailed(String)
        case loadFailed(String)
        case deleteFailed(String)
        case insufficientSpace

        var errorDescription: String? {
            switch self {
            case .directoryCreationFailed:
                return "Failed to create storage directories"
            case .saveFailed(let reason):
                return "Failed to save media: \(reason)"
            case .loadFailed(let reason):
                return "Failed to load media: \(reason)"
            case .deleteFailed(let reason):
                return "Failed to delete media: \(reason)"
            case .insufficientSpace:
                return "Insufficient storage space"
            }
        }
    }

    init() {
        let fileManager = FileManager.default

        // Setup directories
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        mediaDirectory = documentsDirectory.appendingPathComponent("Media", isDirectory: true)
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MediaCache", isDirectory: true)

        // Create directories if they don't exist
        try? fileManager.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        logger.info("MediaStorageService initialized")
    }

    /// Save image data to storage
    func saveImage(
        data: Data,
        filename: String
    ) async throws -> URL {
        let fileURL = mediaDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            logger.info("Image saved: \(filename) (\(data.count) bytes)")
            return fileURL
        } catch {
            logger.error("Failed to save image: \(error.localizedDescription)")
            throw StorageError.saveFailed(error.localizedDescription)
        }
    }

    /// Save video file to storage
    func saveVideo(
        from sourceURL: URL,
        filename: String
    ) async throws -> URL {
        let destinationURL = mediaDirectory.appendingPathComponent(filename)

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

            let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0

            logger.info("Video saved: \(filename) (\(fileSize) bytes)")
            return destinationURL
        } catch {
            logger.error("Failed to save video: \(error.localizedDescription)")
            throw StorageError.saveFailed(error.localizedDescription)
        }
    }

    /// Load image data from storage
    func loadImage(filename: String) async throws -> Data {
        let fileURL = mediaDirectory.appendingPathComponent(filename)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw StorageError.loadFailed("File not found: \(filename)")
        }

        do {
            let data = try Data(contentsOf: fileURL)
            logger.info("Image loaded: \(filename) (\(data.count) bytes)")
            return data
        } catch {
            logger.error("Failed to load image: \(error.localizedDescription)")
            throw StorageError.loadFailed(error.localizedDescription)
        }
    }

    /// Load video file from storage
    func loadVideo(filename: String) async throws -> URL {
        let fileURL = mediaDirectory.appendingPathComponent(filename)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw StorageError.loadFailed("File not found: \(filename)")
        }

        logger.info("Video loaded: \(filename)")
        return fileURL
    }

    /// Delete media file
    func deleteMedia(filename: String) async throws {
        let fileURL = mediaDirectory.appendingPathComponent(filename)

        do {
            try FileManager.default.removeItem(at: fileURL)
            logger.info("Media deleted: \(filename)")
        } catch {
            logger.error("Failed to delete media: \(error.localizedDescription)")
            throw StorageError.deleteFailed(error.localizedDescription)
        }
    }

    /// Get all media files
    func getAllMediaFiles() async throws -> [MediaFile] {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: mediaDirectory, includingPropertiesForKeys: nil)

            var mediaFiles: [MediaFile] = []

            for file in files {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)

                let mediaFile = MediaFile(
                    url: file,
                    filename: file.lastPathComponent,
                    fileSize: attributes[.size] as? Int64 ?? 0,
                    createdDate: attributes[.creationDate] as? Date,
                    modifiedDate: attributes[.modificationDate] as? Date,
                    type: getMediaType(from: file)
                )

                mediaFiles.append(mediaFile)
            }

            return mediaFiles.sorted { ($0.modifiedDate ?? Date()) > ($1.modifiedDate ?? Date()) }
        } catch {
            logger.error("Failed to get media files: \(error.localizedDescription)")
            throw StorageError.loadFailed(error.localizedDescription)
        }
    }

    /// Get available storage space
    func getAvailableStorageSpace() throws -> Int64 {
        let fileManager = FileManager.default

        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: documentsDirectory.path)
            guard let availableSpace = attributes[.systemFreeSize] as? Int64 else {
                throw StorageError.loadFailed("Unable to determine available space")
            }

            return availableSpace
        } catch {
            logger.error("Failed to get available space: \(error.localizedDescription)")
            throw error
        }
    }

    /// Check if sufficient space is available
    func checkAvailableSpace(requiredBytes: Int64) async throws -> Bool {
        let availableSpace = try getAvailableStorageSpace()
        return availableSpace >= requiredBytes
    }

    /// Get storage usage
    func getStorageUsage() async throws -> StorageUsage {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: mediaDirectory, includingPropertiesForKeys: nil)

            var totalSize: Int64 = 0
            var imageCount = 0
            var videoCount = 0

            for file in files {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                totalSize += fileSize

                let type = getMediaType(from: file)
                switch type {
                case .image:
                    imageCount += 1
                case .video:
                    videoCount += 1
                case .unknown:
                    break
                }
            }

            let availableSpace = try getAvailableStorageSpace()

            return StorageUsage(
                totalUsed: totalSize,
                totalAvailable: availableSpace,
                imageCount: imageCount,
                videoCount: videoCount,
                fileCount: files.count
            )
        } catch {
            logger.error("Failed to get storage usage: \(error.localizedDescription)")
            throw error
        }
    }

    /// Clear cache
    func clearCache() async throws {
        do {
            let cacheFiles = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)

            for file in cacheFiles {
                try FileManager.default.removeItem(at: file)
            }

            logger.info("Cache cleared")
        } catch {
            logger.error("Failed to clear cache: \(error.localizedDescription)")
            throw StorageError.deleteFailed(error.localizedDescription)
        }
    }

    // MARK: - Private Methods

    private func getMediaType(from url: URL) -> MediaFileType {
        let pathExtension = url.pathExtension.lowercased()

        switch pathExtension {
        case "jpg", "jpeg", "png", "heic", "tiff":
            return .image
        case "mp4", "mov", "m4v", "avi", "mkv":
            return .video
        default:
            return .unknown
        }
    }
}

struct MediaFile {
    let url: URL
    let filename: String
    let fileSize: Int64
    let createdDate: Date?
    let modifiedDate: Date?
    let type: MediaFileType

    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

enum MediaFileType {
    case image
    case video
    case unknown
}

struct StorageUsage {
    let totalUsed: Int64
    let totalAvailable: Int64
    let imageCount: Int
    let videoCount: Int
    let fileCount: Int

    var percentageUsed: Double {
        let total = totalUsed + totalAvailable
        return Double(totalUsed) / Double(total) * 100
    }

    var usedFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalUsed)
    }

    var availableFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalAvailable)
    }
}
