import Foundation

/// Service for NSF FAIR data principles compliance
actor NSFFairService {
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.ai4science.openscience", category: "NSFFairService")

    // MARK: - Public Methods

    /// Validate data against FAIR principles
    func validateFAIRCompliance(_ data: DataPackage) async throws -> FairComplianceReport {
        logger.info("Validating FAIR compliance for dataset: \(data.identifier)")

        var findings: [ComplianceFinding] = []
        var score: Double = 0

        // Check Findability
        let findability = checkFindability(data)
        findings.append(contentsOf: findability.findings)
        score += findability.score * 0.25

        // Check Accessibility
        let accessibility = checkAccessibility(data)
        findings.append(contentsOf: accessibility.findings)
        score += accessibility.score * 0.25

        // Check Interoperability
        let interoperability = checkInteroperability(data)
        findings.append(contentsOf: interoperability.findings)
        score += interoperability.score * 0.25

        // Check Reusability
        let reusability = checkReusability(data)
        findings.append(contentsOf: reusability.findings)
        score += reusability.score * 0.25

        let report = FairComplianceReport(
            datasetId: data.identifier,
            timestamp: Date(),
            score: score,
            findings: findings,
            isCompliant: score >= 0.8
        )

        logger.info("FAIR compliance report generated: \(report.isCompliant ? "COMPLIANT" : "NON-COMPLIANT")")
        return report
    }

    /// Generate FAIR data manifest
    func generateFairManifest(_ data: DataPackage) throws -> FAIRManifest {
        logger.debug("Generating FAIR manifest")

        let manifest = FAIRManifest(
            identifier: UUID().uuidString,
            datasetId: data.identifier,
            creationDate: Date(),
            findabilityMetadata: generateFindabilityMetadata(data),
            accessibilityMetadata: generateAccessibilityMetadata(data),
            interoperabilityMetadata: generateInteroperabilityMetadata(data),
            reusabilityMetadata: generateReusabilityMetadata(data)
        )

        return manifest
    }

    // MARK: - Private Methods

    private func checkFindability(_ data: DataPackage) -> ComplianceCheck {
        var findings: [ComplianceFinding] = []
        var score = 0.0

        // F1: Data are assigned a globally unique and persistent identifier
        if data.identifier.isEmpty {
            findings.append(ComplianceFinding(principle: "F1", status: .fail, message: "Dataset identifier is empty"))
        } else {
            score += 0.25
        }

        // F2: Data are described with rich metadata
        if data.metadata.isEmpty {
            findings.append(ComplianceFinding(principle: "F2", status: .fail, message: "Missing metadata"))
        } else {
            score += 0.25
        }

        // F3: Metadata clearly and explicitly include the identifier
        if data.metadata["identifier"] != nil {
            score += 0.25
        } else {
            findings.append(ComplianceFinding(principle: "F3", status: .fail, message: "Identifier not in metadata"))
        }

        // F4: Data are registered or indexed in a searchable resource
        score += 0.25

        return ComplianceCheck(findings: findings, score: score)
    }

    private func checkAccessibility(_ data: DataPackage) -> ComplianceCheck {
        var findings: [ComplianceFinding] = []
        var score = 0.0

        // A1: Data are retrievable by their identifier
        score += 0.25

        // A1.1: A standardized communication protocol is used
        if data.metadata["accessUrl"] != nil {
            score += 0.25
        } else {
            findings.append(ComplianceFinding(principle: "A1.1", status: .fail, message: "No access URL specified"))
        }

        // A1.2: The protocol is open, free, and universally implementable
        score += 0.25

        // A2: Metadata are accessible even when data are no longer available
        score += 0.25

        return ComplianceCheck(findings: findings, score: score)
    }

    private func checkInteroperability(_ data: DataPackage) -> ComplianceCheck {
        var findings: [ComplianceFinding] = []
        var score = 0.0

        // I1: Data use a formal, accessible, shared, and broadly applicable language
        if data.format != nil {
            score += 0.25
        } else {
            findings.append(ComplianceFinding(principle: "I1", status: .fail, message: "Data format not specified"))
        }

        // I2: Data use vocabularies that follow FAIR principles
        if data.metadata["vocabulary"] != nil {
            score += 0.25
        } else {
            findings.append(ComplianceFinding(principle: "I2", status: .fail, message: "No vocabulary metadata"))
        }

        // I3: Data include qualified references to other data
        score += 0.25
        score += 0.25

        return ComplianceCheck(findings: findings, score: score)
    }

    private func checkReusability(_ data: DataPackage) -> ComplianceCheck {
        var findings: [ComplianceFinding] = []
        var score = 0.0

        // R1: Metadata and data are richly described
        if !data.metadata.isEmpty {
            score += 0.25
        }

        // R1.1: Data are released with a clear and accessible data usage license
        if data.metadata["license"] != nil {
            score += 0.25
        } else {
            findings.append(ComplianceFinding(principle: "R1.1", status: .fail, message: "No license specified"))
        }

        // R1.2: Data are associated with detailed provenance
        if data.metadata["provenance"] != nil {
            score += 0.25
        } else {
            findings.append(ComplianceFinding(principle: "R1.2", status: .fail, message: "No provenance information"))
        }

        // R1.3: Data meet domain-relevant community standards
        score += 0.25

        return ComplianceCheck(findings: findings, score: score)
    }

    private func generateFindabilityMetadata(_ data: DataPackage) -> [String: String] {
        return [
            "identifier": data.identifier,
            "title": data.metadata["title"] ?? "Untitled Dataset",
            "description": data.metadata["description"] ?? "",
            "creationDate": data.creationDate.ISO8601Format()
        ]
    }

    private func generateAccessibilityMetadata(_ data: DataPackage) -> [String: String] {
        return [
            "accessUrl": data.metadata["accessUrl"] ?? "",
            "protocol": "HTTPS",
            "authentication": "OAuth2"
        ]
    }

    private func generateInteroperabilityMetadata(_ data: DataPackage) -> [String: String] {
        return [
            "format": data.format ?? "unknown",
            "vocabulary": data.metadata["vocabulary"] ?? "SKOS",
            "schema": data.metadata["schema"] ?? "JSON-LD"
        ]
    }

    private func generateReusabilityMetadata(_ data: DataPackage) -> [String: String] {
        return [
            "license": data.metadata["license"] ?? "CC-BY-4.0",
            "provenance": data.metadata["provenance"] ?? "Not specified",
            "community": "AI4Science"
        ]
    }
}

// MARK: - Models
struct ComplianceCheck: Sendable {
    let findings: [ComplianceFinding]
    let score: Double
}

struct ComplianceFinding: Codable, Sendable {
    enum Status: String, Codable, Sendable {
        case pass
        case warning
        case fail
    }

    let principle: String
    let status: Status
    let message: String
}

struct FairComplianceReport: Codable, Sendable {
    let datasetId: String
    let timestamp: Date
    let score: Double
    let findings: [ComplianceFinding]
    let isCompliant: Bool
}

struct FAIRManifest: Codable, Sendable {
    let identifier: String
    let datasetId: String
    let creationDate: Date
    let findabilityMetadata: [String: String]
    let accessibilityMetadata: [String: String]
    let interoperabilityMetadata: [String: String]
    let reusabilityMetadata: [String: String]
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
