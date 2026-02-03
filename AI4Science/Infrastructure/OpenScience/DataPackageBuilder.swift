import Foundation

/// Builder for creating FAIR-compliant data packages
actor DataPackageBuilder {
    // MARK: - Properties
    private let logger = DataPackageLogger(subsystem: "com.ai4science.openscience", category: "DataPackageBuilder")
    private var dataPackage: DataPackage

    // MARK: - Initialization
    init(identifier: String) {
        self.dataPackage = DataPackage(
            identifier: identifier,
            creationDate: Date(),
            metadata: [:],
            files: [],
            format: nil
        )
    }

    // MARK: - Public Methods

    /// Set package metadata
    func setMetadata(_ metadata: [String: String]) -> DataPackageBuilder {
        logger.debug("Setting metadata for package: \(dataPackage.identifier)")
        dataPackage = DataPackage(
            identifier: dataPackage.identifier,
            creationDate: dataPackage.creationDate,
            metadata: metadata,
            files: dataPackage.files,
            format: dataPackage.format
        )
        return self
    }

    /// Add metadata field
    func addMetadata(key: String, value: String) -> DataPackageBuilder {
        logger.debug("Adding metadata: \(key)")
        var metadata = dataPackage.metadata
        metadata[key] = value
        dataPackage = DataPackage(
            identifier: dataPackage.identifier,
            creationDate: dataPackage.creationDate,
            metadata: metadata,
            files: dataPackage.files,
            format: dataPackage.format
        )
        return self
    }

    /// Set data format
    func setFormat(_ format: String) -> DataPackageBuilder {
        logger.debug("Setting format: \(format)")
        dataPackage = DataPackage(
            identifier: dataPackage.identifier,
            creationDate: dataPackage.creationDate,
            metadata: dataPackage.metadata,
            files: dataPackage.files,
            format: format
        )
        return self
    }

    /// Add file to package
    func addFile(_ file: DataFile) -> DataPackageBuilder {
        logger.debug("Adding file: \(file.name)")
        var files = dataPackage.files
        files.append(file)
        dataPackage = DataPackage(
            identifier: dataPackage.identifier,
            creationDate: dataPackage.creationDate,
            metadata: dataPackage.metadata,
            files: files,
            format: dataPackage.format
        )
        return self
    }

    /// Add files
    func addFiles(_ files: [DataFile]) -> DataPackageBuilder {
        logger.debug("Adding \(files.count) files")
        var allFiles = dataPackage.files
        allFiles.append(contentsOf: files)
        dataPackage = DataPackage(
            identifier: dataPackage.identifier,
            creationDate: dataPackage.creationDate,
            metadata: dataPackage.metadata,
            files: allFiles,
            format: dataPackage.format
        )
        return self
    }

    /// Set creator/author
    func setCreator(_ name: String, email: String? = nil, organization: String? = nil) -> DataPackageBuilder {
        logger.debug("Setting creator: \(name)")
        var creator = "name: \(name)"
        if let email = email {
            creator += ", email: \(email)"
        }
        if let org = organization {
            creator += ", organization: \(org)"
        }
        return addMetadata(key: "creator", value: creator)
    }

    /// Set license
    func setLicense(_ license: String) -> DataPackageBuilder {
        logger.debug("Setting license: \(license)")
        return addMetadata(key: "license", value: license)
    }

    /// Set description
    func setDescription(_ description: String) -> DataPackageBuilder {
        logger.debug("Setting description")
        return addMetadata(key: "description", value: description)
    }

    /// Set title
    func setTitle(_ title: String) -> DataPackageBuilder {
        logger.debug("Setting title: \(title)")
        return addMetadata(key: "title", value: title)
    }

    /// Set keywords
    func setKeywords(_ keywords: [String]) -> DataPackageBuilder {
        logger.debug("Setting keywords: \(keywords.count)")
        return addMetadata(key: "keywords", value: keywords.joined(separator: ", "))
    }

    /// Set temporal coverage
    func setTemporalCoverage(startDate: Date, endDate: Date) -> DataPackageBuilder {
        logger.debug("Setting temporal coverage")
        let range = "\(startDate.ISO8601Format())/\(endDate.ISO8601Format())"
        return addMetadata(key: "temporalCoverage", value: range)
    }

    /// Set spatial coverage
    func setSpatialCoverage(_ coverage: String) -> DataPackageBuilder {
        logger.debug("Setting spatial coverage: \(coverage)")
        return addMetadata(key: "spatialCoverage", value: coverage)
    }

    /// Build the data package
    func build() throws -> DataPackage {
        logger.info("Building data package: \(dataPackage.identifier)")

        // Validate required fields
        if dataPackage.metadata["title"] == nil {
            logger.warning("Missing title in data package")
        }

        if dataPackage.metadata["description"] == nil {
            logger.warning("Missing description in data package")
        }

        if dataPackage.files.isEmpty {
            logger.warning("Data package contains no files")
        }

        return dataPackage
    }
}

// MARK: - Models
struct DataPackage: Codable, Sendable {
    let identifier: String
    let creationDate: Date
    let metadata: [String: String]
    let files: [DataFile]
    let format: String?

    var fileCount: Int {
        return files.count
    }

    var totalSize: Int64 {
        return files.reduce(0) { $0 + ($1.size ?? 0) }
    }
}

struct DataFile: Codable, Sendable {
    let name: String
    let path: String
    let size: Int64?
    let checksum: String?
    let format: String?
    let description: String?
    let createdDate: Date

    init(
        name: String,
        path: String,
        size: Int64? = nil,
        checksum: String? = nil,
        format: String? = nil,
        description: String? = nil,
        createdDate: Date = Date()
    ) {
        self.name = name
        self.path = path
        self.size = size
        self.checksum = checksum
        self.format = format
        self.description = description
        self.createdDate = createdDate
    }
}

// MARK: - Predefined Builders
// NOTE: These factory methods are async because DataPackageBuilder is an actor
extension DataPackageBuilder {
    /// Create builder for biological sample data
    static func biologicalSample() async -> DataPackageBuilder {
        let builder = DataPackageBuilder(identifier: UUID().uuidString)
        _ = await builder.setFormat("JSON-LD")
        _ = await builder.addMetadata(key: "type", value: "BiologicalSample")
        return builder
    }

    /// Create builder for environmental data
    static func environmental() async -> DataPackageBuilder {
        let builder = DataPackageBuilder(identifier: UUID().uuidString)
        _ = await builder.setFormat("NetCDF")
        _ = await builder.addMetadata(key: "type", value: "EnvironmentalData")
        return builder
    }

    /// Create builder for survey data
    static func survey() async -> DataPackageBuilder {
        let builder = DataPackageBuilder(identifier: UUID().uuidString)
        _ = await builder.setFormat("CSV")
        _ = await builder.addMetadata(key: "type", value: "SurveyData")
        return builder
    }
}

// MARK: - Logger Helper
private struct DataPackageLogger: Sendable {
    private let subsystem: String
    private let category: String

    nonisolated init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }

    nonisolated func debug(_ message: String) {
        os_log("%{public}@", log: getLog(), type: .debug, message)
    }

    nonisolated func info(_ message: String) {
        os_log("%{public}@", log: getLog(), type: .info, message)
    }

    nonisolated func warning(_ message: String) {
        os_log("%{public}@", log: getLog(), type: .default, message)
    }

    nonisolated func error(_ message: String) {
        os_log("%{public}@", log: getLog(), type: .error, message)
    }

    private nonisolated func getLog() -> os.OSLog {
        return OSLog(subsystem: subsystem, category: category)
    }
}

import os
