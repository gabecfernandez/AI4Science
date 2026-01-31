import Foundation

extension URL {
    /// Get document directory
    public static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Get cache directory
    public static var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    /// Get temporary directory
    public static var temporaryDirectory: URL {
        FileManager.default.temporaryDirectory
    }

    /// Get application support directory
    public static var applicationSupportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    /// Append path component
    public func appending(_ pathComponent: String) -> URL {
        appendingPathComponent(pathComponent)
    }

    /// Append multiple path components
    public func appending(pathComponents: [String]) -> URL {
        var url = self
        for component in pathComponents {
            url.appendPathComponent(component)
        }
        return url
    }

    /// Check if file exists
    public var fileExists: Bool {
        FileManager.default.fileExists(atPath: path)
    }

    /// Check if URL is directory
    public var isDirectory: Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return isDir.boolValue
    }

    /// Get file size in bytes
    public var fileSizeBytes: Int64 {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path) else {
            return 0
        }
        return attributes[.size] as? Int64 ?? 0
    }

    /// Get file size in MB
    public var fileSizeMB: Double {
        Double(fileSizeBytes) / (1024 * 1024)
    }

    /// Get file name with extension
    public var fileName: String {
        lastPathComponent
    }

    /// Get file name without extension
    public var fileNameWithoutExtension: String {
        deletingPathExtension().lastPathComponent
    }

    /// Get file extension
    public var fileExtension: String {
        pathExtension
    }

    /// Get parent directory
    public var parent: URL {
        deletingLastPathComponent()
    }

    /// Create directories if needed
    @discardableResult
    public func createDirectories() throws -> URL {
        try FileManager.default.createDirectory(at: self, withIntermediateDirectories: true)
        return self
    }

    /// Remove file or directory
    public func remove() throws {
        try FileManager.default.removeItem(at: self)
    }

    /// Copy to destination
    public func copy(to destination: URL) throws {
        try FileManager.default.copyItem(at: self, to: destination)
    }

    /// Move to destination
    public func move(to destination: URL) throws {
        try FileManager.default.moveItem(at: self, to: destination)
    }

    /// List directory contents
    public func listContents() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil)
    }

    /// Get modification date
    public var modificationDate: Date? {
        try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date
    }

    /// Get creation date
    public var creationDate: Date? {
        try? FileManager.default.attributesOfItem(atPath: path)[.creationDate] as? Date
    }
}
