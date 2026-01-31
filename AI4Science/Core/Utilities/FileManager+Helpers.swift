import Foundation

public extension FileManager {
    /// Create documents directory path
    var documentsPath: URL {
        urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Create cache directory path
    var cachePath: URL {
        urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    /// Create temporary directory path
    var temporaryPath: URL {
        temporaryDirectory
    }

    /// Create application support directory path
    var applicationSupportPath: URL {
        let paths = urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return paths[0]
    }

    // MARK: - Document Directory Helpers

    /// Get or create subdirectory in documents
    func documentsSubdirectory(named name: String) throws -> URL {
        let url = documentsPath.appendingPathComponent(name)
        try createDirectoryIfNeeded(url)
        return url
    }

    /// Save file to documents directory
    func saveToDocuments(
        fileName: String,
        data: Data,
        subdirectory: String? = nil
    ) throws {
        let url: URL
        if let subdirectory = subdirectory {
            url = try documentsSubdirectory(named: subdirectory).appendingPathComponent(fileName)
        } else {
            url = documentsPath.appendingPathComponent(fileName)
        }

        try data.write(to: url, options: .atomic)
    }

    /// Load file from documents directory
    func loadFromDocuments(fileName: String, subdirectory: String? = nil) throws -> Data {
        let url: URL
        if let subdirectory = subdirectory {
            url = try documentsSubdirectory(named: subdirectory).appendingPathComponent(fileName)
        } else {
            url = documentsPath.appendingPathComponent(fileName)
        }

        return try Data(contentsOf: url)
    }

    /// Delete file from documents directory
    func deleteFromDocuments(fileName: String, subdirectory: String? = nil) throws {
        let url: URL
        if let subdirectory = subdirectory {
            url = try documentsSubdirectory(named: subdirectory).appendingPathComponent(fileName)
        } else {
            url = documentsPath.appendingPathComponent(fileName)
        }

        try removeItem(at: url)
    }

    // MARK: - Cache Directory Helpers

    /// Get or create subdirectory in cache
    func cacheSubdirectory(named name: String) throws -> URL {
        let url = cachePath.appendingPathComponent(name)
        try createDirectoryIfNeeded(url)
        return url
    }

    /// Save file to cache directory
    func saveToCache(
        fileName: String,
        data: Data,
        subdirectory: String? = nil
    ) throws {
        let url: URL
        if let subdirectory = subdirectory {
            url = try cacheSubdirectory(named: subdirectory).appendingPathComponent(fileName)
        } else {
            url = cachePath.appendingPathComponent(fileName)
        }

        try data.write(to: url, options: .atomic)
    }

    /// Load file from cache directory
    func loadFromCache(fileName: String, subdirectory: String? = nil) throws -> Data {
        let url: URL
        if let subdirectory = subdirectory {
            url = try cacheSubdirectory(named: subdirectory).appendingPathComponent(fileName)
        } else {
            url = cachePath.appendingPathComponent(fileName)
        }

        return try Data(contentsOf: url)
    }

    /// Delete file from cache directory
    func deleteFromCache(fileName: String, subdirectory: String? = nil) throws {
        let url: URL
        if let subdirectory = subdirectory {
            url = try cacheSubdirectory(named: subdirectory).appendingPathComponent(fileName)
        } else {
            url = cachePath.appendingPathComponent(fileName)
        }

        try removeItem(at: url)
    }

    /// Clear all cache
    func clearCache() throws {
        try removeItem(at: cachePath)
        try createDirectoryIfNeeded(cachePath)
    }

    // MARK: - Directory Operations

    /// Create directory if it doesn't exist
    func createDirectoryIfNeeded(_ url: URL) throws {
        if !fileExists(atPath: url.path) {
            try createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    /// Get size of directory
    func directorySize(_ url: URL) throws -> Int64 {
        guard let enumerator = enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: Int64 = 0
        for case let file as URL in enumerator {
            let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = attributes.fileSize {
                totalSize += Int64(fileSize)
            }
        }
        return totalSize
    }

    /// Remove files older than specified date in directory
    func removeOldFiles(in directory: URL, olderThan date: Date) throws {
        guard let enumerator = enumerator(at: directory, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return
        }

        for case let file as URL in enumerator {
            let attributes = try file.resourceValues(forKeys: [.contentModificationDateKey])
            if let modificationDate = attributes.contentModificationDate, modificationDate < date {
                try removeItem(at: file)
            }
        }
    }

    // MARK: - File Operations

    /// Check if file exists
    func fileExists(at url: URL) -> Bool {
        fileExists(atPath: url.path)
    }

    /// Copy file
    func copy(from source: URL, to destination: URL) throws {
        try createDirectoryIfNeeded(destination.deletingLastPathComponent())
        try copyItem(at: source, to: destination)
    }

    /// Move file
    func move(from source: URL, to destination: URL) throws {
        try createDirectoryIfNeeded(destination.deletingLastPathComponent())
        try moveItem(at: source, to: destination)
    }

    /// Get file size
    func fileSize(at url: URL) throws -> Int64 {
        let attributes = try attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }

    /// Get modification date
    func modificationDate(at url: URL) throws -> Date? {
        let attributes = try attributesOfItem(atPath: url.path)
        return attributes[.modificationDate] as? Date
    }

    // MARK: - Utility

    /// Get available disk space
    func availableDiskSpace() throws -> Int64 {
        let attributes = try attributesOfFileSystem(forPath: NSHomeDirectory())
        return attributes[.systemFreeSize] as? Int64 ?? 0
    }

    /// Get total disk space
    func totalDiskSpace() throws -> Int64 {
        let attributes = try attributesOfFileSystem(forPath: NSHomeDirectory())
        return attributes[.systemSize] as? Int64 ?? 0
    }
}
