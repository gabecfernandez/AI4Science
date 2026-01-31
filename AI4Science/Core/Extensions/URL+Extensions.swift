import Foundation

public extension URL {
    /// Get the documents directory URL
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Get the cache directory URL
    static var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    /// Get the temporary directory URL
    static var temporaryDirectory: URL {
        FileManager.default.temporaryDirectory
    }

    /// Get the application support directory URL
    static var applicationSupportDirectory: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return paths[0]
    }

    /// Create directory if it doesn't exist
    func createDirectoryIfNeeded() throws {
        if !FileManager.default.fileExists(atPath: path) {
            try FileManager.default.createDirectory(at: self, withIntermediateDirectories: true)
        }
    }

    /// Check if URL exists
    var exists: Bool {
        FileManager.default.fileExists(atPath: path)
    }

    /// Check if URL is directory
    var isDirectory: Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return isDir.boolValue
    }

    /// Check if URL is file
    var isFile: Bool {
        exists && !isDirectory
    }

    /// Get file size in bytes
    var fileSize: Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }

    /// Get file size in MB
    var fileSizeInMB: Double {
        Double(fileSize) / (1024 * 1024)
    }

    /// Get creation date
    var creationDate: Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.creationDate] as? Date
        } catch {
            return nil
        }
    }

    /// Get modification date
    var modificationDate: Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }

    /// Get directory contents
    func directoryContents() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil)
    }

    /// Get directory contents recursively
    func directoryContentsRecursive() throws -> [URL] {
        guard let enumerator = FileManager.default.enumerator(at: self, includingPropertiesForKeys: nil) else {
            return []
        }
        return enumerator.compactMap { $0 as? URL }
    }

    /// Delete file or directory
    func delete() throws {
        try FileManager.default.removeItem(at: self)
    }

    /// Copy file to destination
    func copy(to destination: URL) throws {
        try FileManager.default.copyItem(at: self, to: destination)
    }

    /// Move file to destination
    func move(to destination: URL) throws {
        try FileManager.default.moveItem(at: self, to: destination)
    }

    /// Create URL in documents directory
    static func documentURL(filename: String) -> URL {
        documentsDirectory.appendingPathComponent(filename)
    }

    /// Create URL in cache directory
    static func cacheURL(filename: String) -> URL {
        cacheDirectory.appendingPathComponent(filename)
    }

    /// Create URL in temporary directory
    static func temporaryURL(filename: String) -> URL {
        temporaryDirectory.appendingPathComponent(filename)
    }

    /// Get all files in directory with extension
    func filesWithExtension(_ ext: String) throws -> [URL] {
        try directoryContents().filter { $0.pathExtension == ext }
    }

    /// Get total size of directory contents
    func directorySize() throws -> Int64 {
        try directoryContentsRecursive().reduce(0) { $0 + $1.fileSize }
    }

    /// Remove extension from filename
    var fileNameWithoutExtension: String {
        deletingPathExtension().lastPathComponent
    }
}
