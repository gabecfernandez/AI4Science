import Foundation

/// Generates standardized metadata for research data
actor MetadataGenerator {
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.ai4science.openscience", category: "MetadataGenerator")

    // MARK: - Public Methods

    /// Generate Dublin Core metadata
    func generateDublinCoreMetadata(for data: DataPackage) async throws -> DublinCoreMetadata {
        logger.info("Generating Dublin Core metadata")

        return DublinCoreMetadata(
            identifier: data.identifier,
            title: data.metadata["title"] ?? "Untitled",
            creator: data.metadata["creator"] ?? "Unknown",
            subject: data.metadata["keywords"] ?? "Research Data",
            description: data.metadata["description"] ?? "No description",
            publisher: data.metadata["publisher"] ?? "AI4Science",
            date: data.creationDate,
            type: data.metadata["type"] ?? "Dataset",
            format: data.format ?? "Unknown",
            language: "en"
        )
    }

    /// Generate JSON-LD metadata
    func generateJSONLDMetadata(for data: DataPackage) async throws -> [String: Any] {
        logger.info("Generating JSON-LD metadata")

        let metadata: [String: Any] = [
            "@context": [
                "@vocab": "http://schema.org/",
                "ai4science": "http://ai4science.org/ontology/"
            ],
            "@type": "Dataset",
            "identifier": data.identifier,
            "name": data.metadata["title"] ?? "Untitled Dataset",
            "description": data.metadata["description"] ?? "No description",
            "creator": createCreatorObject(from: data.metadata["creator"]),
            "datePublished": data.creationDate.ISO8601Format(),
            "license": data.metadata["license"] ?? "CC-BY-4.0",
            "keywords": data.metadata["keywords"]?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? [],
            "distribution": data.files.map { file in
                [
                    "@type": "DataDownload",
                    "name": file.name,
                    "contentUrl": file.path,
                    "encodingFormat": file.format ?? "application/octet-stream",
                    "contentSize": file.size ?? 0
                ]
            }
        ]

        return metadata
    }

    /// Generate MIAPPE (plant phenotyping) metadata
    func generateMIAPPEMetadata(for data: DataPackage) async throws -> MIAPPEMetadata {
        logger.info("Generating MIAPPE metadata")

        return MIAPPEMetadata(
            investigationTitle: data.metadata["title"] ?? "Investigation",
            studyTitle: data.metadata["studyTitle"] ?? "Study",
            studyIdentifier: data.identifier,
            submissionDate: Date(),
            publicReleaseDate: data.creationDate,
            contacts: [],
            environment: EnvironmentDescription(
                environmentDescription: data.metadata["environment"] ?? "Not specified"
            ),
            experimentalDesign: data.metadata["experimentalDesign"] ?? "Not specified"
        )
    }

    /// Generate biosamples metadata
    func generateBiosamplesMetadata(for data: DataPackage) async throws -> BiosamplesMetadata {
        logger.info("Generating BioSamples metadata")

        return BiosamplesMetadata(
            accession: data.identifier,
            title: data.metadata["title"] ?? "Biosample",
            description: data.metadata["description"] ?? "No description",
            releaseDate: data.creationDate,
            organism: data.metadata["organism"] ?? "Unknown",
            attributes: parseBiosamplesAttributes(data.metadata)
        )
    }

    /// Generate data quality report
    func generateQualityReport(for data: DataPackage) async -> DataQualityReport {
        logger.info("Generating data quality report")

        var scores: [String: Double] = [:]

        // Check completeness
        scores["completeness"] = Double(data.files.count > 0 ? 1.0 : 0.0)

        // Check metadata richness
        let metadataFields = data.metadata.count
        scores["metadataRichness"] = min(Double(metadataFields) / 10.0, 1.0)

        // Check file diversity
        let uniqueFormats = Set(data.files.compactMap { $0.format }).count
        scores["formatDiversity"] = min(Double(uniqueFormats) / 5.0, 1.0)

        let overallScore = scores.values.reduce(0, +) / Double(scores.count)

        return DataQualityReport(
            datasetId: data.identifier,
            timestamp: Date(),
            scores: scores,
            overallScore: overallScore,
            issues: identifyQualityIssues(data)
        )
    }

    /// Validate metadata completeness
    func validateMetadataCompleteness(_ data: DataPackage) async -> MetadataValidation {
        logger.debug("Validating metadata completeness")

        let requiredFields = ["title", "description", "creator", "license"]
        var missing: [String] = []

        for field in requiredFields {
            if data.metadata[field] == nil || data.metadata[field]?.isEmpty ?? true {
                missing.append(field)
            }
        }

        let completeness = Double(requiredFields.count - missing.count) / Double(requiredFields.count)

        return MetadataValidation(
            isComplete: missing.isEmpty,
            completenessPercentage: completeness,
            missingFields: missing
        )
    }

    // MARK: - Private Methods

    private func createCreatorObject(from creatorString: String?) -> [String: Any] {
        guard let creatorString = creatorString else {
            return ["@type": "Person", "name": "Unknown"]
        }

        return [
            "@type": "Person",
            "name": creatorString
        ]
    }

    private func parseBiosamplesAttributes(_ metadata: [String: String]) -> [[String: String]] {
        var attributes: [[String: String]] = []

        for (key, value) in metadata {
            attributes.append(["tag": key, "value": value])
        }

        return attributes
    }

    private func identifyQualityIssues(_ data: DataPackage) -> [QualityIssue] {
        var issues: [QualityIssue] = []

        if data.metadata["title"]?.isEmpty ?? true {
            issues.append(QualityIssue(severity: .high, message: "Missing dataset title"))
        }

        if data.metadata["description"]?.isEmpty ?? true {
            issues.append(QualityIssue(severity: .high, message: "Missing dataset description"))
        }

        if data.files.isEmpty {
            issues.append(QualityIssue(severity: .high, message: "No data files included"))
        }

        if data.metadata["license"]?.isEmpty ?? true {
            issues.append(QualityIssue(severity: .medium, message: "No license specified"))
        }

        return issues
    }
}

// MARK: - Models
struct DublinCoreMetadata: Codable, Sendable {
    let identifier: String
    let title: String
    let creator: String
    let subject: String
    let description: String
    let publisher: String
    let date: Date
    let type: String
    let format: String
    let language: String
}

struct MIAPPEMetadata: Codable, Sendable {
    let investigationTitle: String
    let studyTitle: String
    let studyIdentifier: String
    let submissionDate: Date
    let publicReleaseDate: Date
    let contacts: [Contact]
    let environment: EnvironmentDescription
    let experimentalDesign: String
}

struct EnvironmentDescription: Codable, Sendable {
    let environmentDescription: String
}

struct Contact: Codable, Sendable {
    let name: String
    let email: String?
    let institution: String?
}

struct BiosamplesMetadata: Codable, Sendable {
    let accession: String
    let title: String
    let description: String
    let releaseDate: Date
    let organism: String
    let attributes: [[String: String]]
}

struct DataQualityReport: Codable, Sendable {
    enum Severity: String, Codable, Sendable {
        case high, medium, low
    }

    let datasetId: String
    let timestamp: Date
    let scores: [String: Double]
    let overallScore: Double
    let issues: [QualityIssue]
}

struct QualityIssue: Codable, Sendable {
    enum Severity: String, Codable, Sendable {
        case high, medium, low
    }

    let severity: Severity
    let message: String
    let timestamp: Date

    init(severity: Severity, message: String) {
        self.severity = severity
        self.message = message
        self.timestamp = Date()
    }
}

struct MetadataValidation: Sendable {
    let isComplete: Bool
    let completenessPercentage: Double
    let missingFields: [String]
}

// MARK: - Logger Helper
private struct Logger {
    private let subsystem: String
    private let category: String

    init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }

    func debug(_ message: String) {
        os_log("%{public}@", log: getLog(), type: .debug, message)
    }

    func info(_ message: String) {
        os_log("%{public}@", log: getLog(), type: .info, message)
    }

    func error(_ message: String) {
        os_log("%{public}@", log: getLog(), type: .error, message)
    }

    private func getLog() -> os.OSLog {
        return OSLog(subsystem: subsystem, category: category)
    }
}

import os
