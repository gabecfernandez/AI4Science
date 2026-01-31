import Foundation

/// Service for Digital Object Identifier (DOI) integration
actor DOIService {
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.ai4science.openscience", category: "DOIService")
    private let doiPrefix = "10.80087"  // Example DOI prefix (would be real in production)

    // MARK: - Public Methods

    /// Register a new DOI for a dataset
    func registerDOI(
        for dataPackage: DataPackage,
        metadata: [String: String]
    ) async throws -> DOIRegistration {
        logger.info("Registering DOI for dataset: \(dataPackage.identifier)")

        let doi = generateDOI()

        let registration = DOIRegistration(
            doi: doi,
            datasetId: dataPackage.identifier,
            registrationDate: Date(),
            metadata: metadata,
            status: .registered,
            url: generateDOIURL(for: doi)
        )

        logger.info("DOI registered: \(doi)")
        return registration
    }

    /// Resolve DOI to dataset
    func resolveDOI(_ doi: String) async throws -> DOIResolution {
        logger.debug("Resolving DOI: \(doi)")

        guard doi.hasPrefix(doiPrefix) else {
            throw DOIServiceError.invalidDOI
        }

        return DOIResolution(
            doi: doi,
            url: generateDOIURL(for: doi),
            resolvedDate: Date(),
            status: .resolved
        )
    }

    /// Update DOI metadata
    func updateDOIMetadata(
        _ doi: String,
        metadata: [String: String]
    ) async throws -> DOIMetadataUpdate {
        logger.debug("Updating DOI metadata: \(doi)")

        let update = DOIMetadataUpdate(
            doi: doi,
            updateDate: Date(),
            metadata: metadata,
            status: .updated
        )

        logger.info("DOI metadata updated: \(doi)")
        return update
    }

    /// Retrieve DOI record
    func getDOIRecord(_ doi: String) async throws -> DOIRecord {
        logger.debug("Retrieving DOI record: \(doi)")

        let record = DOIRecord(
            doi: doi,
            creationDate: Date(),
            creators: [],
            title: "Research Dataset",
            description: "A research dataset",
            publicationYear: Calendar.current.component(.year, from: Date()),
            resourceType: "Dataset",
            url: generateDOIURL(for: doi),
            version: "1.0"
        )

        return record
    }

    /// Search DOI records
    func searchDOI(query: String) async throws -> [DOIRecord] {
        logger.debug("Searching DOIs with query: \(query)")

        // This would integrate with DataCite API in production
        return []
    }

    /// Create citation for DOI
    func generateCitation(
        for doi: String,
        format: CitationFormat
    ) async throws -> String {
        logger.debug("Generating citation for DOI: \(doi)")

        let record = try await getDOIRecord(doi)

        switch format {
        case .apa:
            return generateAPACitation(record)
        case .mla:
            return generateMLACitation(record)
        case .chicago:
            return generateChicagoCitation(record)
        case .bibtex:
            return generateBibTexCitation(record)
        }
    }

    /// Validate DOI format
    func validateDOI(_ doi: String) -> Bool {
        let doiPattern = "^10\\.\\d{4,}/\\S+$"
        let regex = try? NSRegularExpression(pattern: doiPattern)
        let range = NSRange(doi.startIndex..<doi.endIndex, in: doi)
        return regex?.firstMatch(in: doi, range: range) != nil
    }

    // MARK: - Private Methods

    private func generateDOI() -> String {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12)
        return "\(doiPrefix)/ai4science-\(uuid)"
    }

    private func generateDOIURL(for doi: String) -> URL? {
        return URL(string: "https://doi.org/\(doi)")
    }

    private func generateAPACitation(_ record: DOIRecord) -> String {
        var citation = ""
        if !record.creators.isEmpty {
            citation += record.creators.map { $0.name }.joined(separator: ", ")
            citation += " (\(record.publicationYear)). "
        }
        citation += "\(record.title). "
        citation += "Retrieved from \(record.url?.absoluteString ?? record.doi)"
        return citation
    }

    private func generateMLACitation(_ record: DOIRecord) -> String {
        var citation = ""
        if !record.creators.isEmpty {
            citation += record.creators.map { $0.name }.joined(separator: ", and ")
            citation += ". "
        }
        citation += "\"\(record.title).\" \(record.publicationYear). "
        citation += "https://doi.org/\(record.doi)"
        return citation
    }

    private func generateChicagoCitation(_ record: DOIRecord) -> String {
        var citation = ""
        if !record.creators.isEmpty {
            citation += record.creators.map { $0.name }.joined(separator: ", ")
            citation += ". "
        }
        citation += "\"\(record.title).\" Accessed \(Date().formatted(date: .abbreviated, time: .omitted)). "
        citation += "https://doi.org/\(record.doi)."
        return citation
    }

    private func generateBibTexCitation(_ record: DOIRecord) -> String {
        let key = record.title.prefix(4).lowercased()
        let authors = record.creators.map { $0.name }.joined(separator: " and ")

        return """
            @dataset{\(key)\(record.publicationYear),
              title = {\(record.title)},
              author = {\(authors)},
              year = {\(record.publicationYear)},
              doi = {\(record.doi)},
              url = {\(record.url?.absoluteString ?? "")}
            }
            """
    }
}

// MARK: - Models
struct DOIRegistration: Codable, Sendable {
    enum Status: String, Codable, Sendable {
        case pending
        case registered
        case failed
    }

    let doi: String
    let datasetId: String
    let registrationDate: Date
    let metadata: [String: String]
    let status: Status
    let url: URL?
}

struct DOIResolution: Codable, Sendable {
    enum Status: String, Codable, Sendable {
        case resolved
        case notFound
        case error
    }

    let doi: String
    let url: URL
    let resolvedDate: Date
    let status: Status
}

struct DOIMetadataUpdate: Codable, Sendable {
    enum Status: String, Codable, Sendable {
        case updated
        case failed
    }

    let doi: String
    let updateDate: Date
    let metadata: [String: String]
    let status: Status
}

struct DOIRecord: Codable, Sendable {
    let doi: String
    let creationDate: Date
    let creators: [Creator]
    let title: String
    let description: String
    let publicationYear: Int
    let resourceType: String
    let url: URL?
    let version: String
}

struct Creator: Codable, Sendable {
    let name: String
    let affiliation: String?
    let orcid: String?

    init(name: String, affiliation: String? = nil, orcid: String? = nil) {
        self.name = name
        self.affiliation = affiliation
        self.orcid = orcid
    }
}

enum CitationFormat: String, Sendable {
    case apa = "APA"
    case mla = "MLA"
    case chicago = "Chicago"
    case bibtex = "BibTeX"
}

// MARK: - Error Types
enum DOIServiceError: LocalizedError {
    case invalidDOI
    case registrationFailed(String)
    case resolutionFailed
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidDOI:
            return "Invalid DOI format"
        case .registrationFailed(let reason):
            return "Failed to register DOI: \(reason)"
        case .resolutionFailed:
            return "Failed to resolve DOI"
        case .networkError:
            return "Network error occurred"
        }
    }
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
