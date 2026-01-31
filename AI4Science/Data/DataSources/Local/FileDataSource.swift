import Foundation

/// Data source for file-based operations (media, documents)
actor FileDataSource: Sendable {
    // MARK: - Properties

    private let fileManager: FileManager
    private let baseDirectory: URL

    // MARK: - Initialization

    init(fileManager: FileManager = .default) throws {
        self.fileManager = fileManager

        // Use app's Documents directory
        let documentDirectory = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        self.baseDirectory = documentDirectory.appendingPathComponent("AI4Science")

        // Create base directory if needed
        try fileManager.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true
        )
    }

    init(baseDirectory: URL, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        self.baseDirectory = baseDirectory

        try fileManager.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Public Methods

    /// Save file to disk
    /// - Parameters:
    ///   - data: File data
    ///   - filename: Filename
    ///   - subdirectory: Optional subdirectory
    /// - Returns: File URL
    func saveFile(
        _ data: Data,
        filename: String,
        subdirectory: String? = nil
    ) async throws -> URL {
        let directory = subdirectory.map { baseDirectory.appendingPathComponent($0) } ?? baseDirectory

        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let fileURL = directory.appendingPathComponent(filename)
        try data.write(to: fileURL)

        Logger.info("Saved file: \(fileURL.lastPathComponent)")
        return fileURL
    }

    /// Load file from disk
    /// - Parameter url: File URL
    /// - Returns: File data
    func loadFile(from url: URL) async throws -> Data {
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileDataSourceError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        Logger.info("Loaded file: \(url.lastPathComponent) (\(data.count) bytes)")
        return data
    }

    /// Delete file
    /// - Parameter url: File URL
    func deleteFile(_ url: URL) async throws {
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileDataSourceError.fileNotFound
        }

        try fileManager.removeItem(at: url)
        Logger.info("Deleted file: \(url.lastPathComponent)")
    }

    /// Check if file exists
    /// - Parameter url: File URL
    /// - Returns: True if file exists
    func fileExists(_ url: URL) async -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    /// Get file size
    /// - Parameter url: File URL
    /// - Returns: File size in bytes
    func getFileSize(_ url: URL) async throws -> Int64 {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        return (attributes[.size] as? NSNumber)?.int64Value ?? 0
    }

    /// List files in subdirectory
    /// - Parameter subdirectory: Subdirectory path
    /// - Returns: Array of file URLs
    func listFiles(in subdirectory: String? = nil) async throws -> [URL] {
        let directory = subdirectory.map { baseDirectory.appendingPathComponent($0) } ?? baseDirectory

        guard fileManager.fileExists(atPath: directory.path) else {
            return []
        }

        let fileURLs = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )

        return fileURLs.filter { !$0.lastPathComponent.hasPrefix(".") }
    }

    /// Clear directory
    /// - Parameter subdirectory: Subdirectory to clear
    func clearDirectory(_ subdirectory: String? = nil) async throws {
        let directory = subdirectory.map { baseDirectory.appendingPathComponent($0) } ?? baseDirectory

        let files = try fileManager.contentsOfDirectory(atPath: directory.path)

        for file in files {
            let fileURL = directory.appendingPathComponent(file)
            try fileManager.removeItem(at: fileURL)
        }

        Logger.warning("Cleared directory: \(directory.lastPathComponent)")
    }

    /// Get disk usage
    /// - Returns: Total used space in bytes
    func getDiskUsage() async throws -> Int64 {
        let fileURLs = try fileManager.contentsOfDirectory(
            at: baseDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        )

        var totalSize: Int64 = 0

        for url in fileURLs {
            if let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }

        return totalSize
    }

    /// Create directory
    /// - Parameter subdirectory: Subdirectory path
    func createDirectory(_ subdirectory: String) async throws {
        let directory = baseDirectory.appendingPathComponent(subdirectory)
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
    }

    /// Copy file
    /// - Parameters:
    ///   - source: Source file URL
    ///   - destination: Destination file URL
    func copyFile(from source: URL, to destination: URL) async throws {
        try fileManager.copyItem(at: source, to: destination)
        Logger.info("Copied file from \(source.lastPathComponent) to \(destination.lastPathComponent)")
    }

    /// Move file
    /// - Parameters:
    ///   - source: Source file URL
    ///   - destination: Destination file URL
    func moveFile(from source: URL, to destination: URL) async throws {
        try fileManager.moveItem(at: source, to: destination)
        Logger.info("Moved file from \(source.lastPathComponent) to \(destination.lastPathComponent)")
    }
}

// MARK: - Error Types

enum FileDataSourceError: LocalizedError {
    case fileNotFound
    case invalidPath
    case writeFailed
    case readFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File not found"
        case .invalidPath:
            return "Invalid file path"
        case .writeFailed:
            return "Failed to write file"
        case .readFailed:
            return "Failed to read file"
        case .deleteFailed:
            return "Failed to delete file"
        }
    }
}
