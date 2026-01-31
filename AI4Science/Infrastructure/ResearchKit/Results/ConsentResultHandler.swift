import Foundation
import ResearchKit

/// Handles consent-specific result processing
actor ConsentResultHandler {
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.ai4science.researchkit", category: "ConsentResultHandler")

    // MARK: - Public Methods

    /// Process consent task results
    func processConsentResult(_ taskResult: ORKTaskResult) throws -> ConsentResultData {
        logger.info("Processing consent result")

        guard let signatureResult = findConsentSignatureResult(in: taskResult) else {
            throw ConsentResultHandlerError.noSignatureFound
        }

        let consentGiven = signatureResult.consented
        let timestamp = Date()
        let signatureName = signatureResult.signature.signatureName ?? "Participant"

        logger.info("Consent processed: \(consentGiven)")

        return ConsentResultData(
            consentGiven: consentGiven,
            timestamp: timestamp,
            signatureName: signatureName,
            documentVersion: "1.0",
            ipAddress: getIPAddress(),
            userAgent: getUserAgent()
        )
    }

    /// Extract consent signature from results
    func extractConsentSignature(_ taskResult: ORKTaskResult) throws -> ConsentSignatureData {
        logger.debug("Extracting consent signature")

        guard let signatureResult = findConsentSignatureResult(in: taskResult) else {
            throw ConsentResultHandlerError.noSignatureFound
        }

        let signatureImage = signatureResult.signatureImage
        let signatureDate = signatureResult.signatureDate ?? Date()

        return ConsentSignatureData(
            name: signatureResult.signature.signatureName ?? "Unknown",
            date: signatureDate,
            image: signatureImage,
            identifier: signatureResult.identifier
        )
    }

    /// Get consent document information
    func extractConsentDocumentInfo(_ taskResult: ORKTaskResult) throws -> ConsentDocumentInfo {
        logger.debug("Extracting consent document information")

        var sections: [ConsentSectionInfo] = []

        if let results = taskResult.results {
            for result in results {
                if let consentReview = result as? ORKConsentSignatureResult {
                    // Extract section information from consent document
                    // This would require the document to be passed separately
                }
            }
        }

        return ConsentDocumentInfo(
            version: "1.0",
            acceptanceDate: Date(),
            sections: sections
        )
    }

    /// Verify consent validity
    func verifyConsentValidity(_ consentResult: ConsentResultData) -> ConsentValidityStatus {
        logger.debug("Verifying consent validity")

        guard consentResult.consentGiven else {
            return .notGiven(reason: "Participant did not provide consent")
        }

        // Check timestamp validity (not expired)
        let daysSinceConsent = Calendar.current.dateComponents([.day], from: consentResult.timestamp, to: Date()).day ?? 0

        if daysSinceConsent > 365 {
            return .expired(reason: "Consent is older than 1 year")
        }

        return .valid
    }

    /// Archive consent record
    func archiveConsentRecord(_ consentResult: ConsentResultData) throws -> ArchivedConsentRecord {
        logger.info("Archiving consent record")

        let archivedRecord = ArchivedConsentRecord(
            consentData: consentResult,
            archiveDate: Date(),
            archiveHash: generateConsistentHash(from: consentResult),
            retention: .indefinite
        )

        logger.info("Consent record archived")
        return archivedRecord
    }

    /// Handle consent withdrawal
    func processConsentWithdrawal(
        originalConsentId: String,
        withdrawalReason: String?
    ) throws -> ConsentWithdrawalRecord {
        logger.info("Processing consent withdrawal")

        let record = ConsentWithdrawalRecord(
            originalConsentId: originalConsentId,
            withdrawalDate: Date(),
            reason: withdrawalReason,
            dataRetention: .deleteAll
        )

        logger.info("Consent withdrawal processed: \(originalConsentId)")
        return record
    }

    // MARK: - Private Methods

    private func findConsentSignatureResult(in taskResult: ORKTaskResult) -> ORKConsentSignatureResult? {
        if let results = taskResult.results {
            for result in results {
                if let signatureResult = result as? ORKConsentSignatureResult {
                    return signatureResult
                }
            }
        }
        return nil
    }

    private func getIPAddress() -> String? {
        // In production, this would retrieve the actual IP address
        // For privacy, this is typically not collected in modern apps
        return nil
    }

    private func getUserAgent() -> String {
        let osVersion = UIDevice.current.systemVersion
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "AI4Science/\(appVersion) iOS/\(osVersion)"
    }

    private func generateConsistentHash(from consentResult: ConsentResultData) -> String {
        let data = "\(consentResult.timestamp)\(consentResult.signatureName)".data(using: .utf8) ?? Data()
        return data.base64EncodedString()
    }
}

// MARK: - Models
struct ConsentResultData: Codable, Sendable {
    let consentGiven: Bool
    let timestamp: Date
    let signatureName: String
    let documentVersion: String
    let ipAddress: String?
    let userAgent: String
}

struct ConsentSignatureData: Codable, Sendable {
    let name: String
    let date: Date
    let image: UIImage?
    let identifier: String

    enum CodingKeys: String, CodingKey {
        case name, date, identifier
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(date, forKey: .date)
        try container.encode(identifier, forKey: .identifier)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        date = try container.decode(Date.self, forKey: .date)
        identifier = try container.decode(String.self, forKey: .identifier)
        image = nil
    }

    init(name: String, date: Date, image: UIImage?, identifier: String) {
        self.name = name
        self.date = date
        self.image = image
        self.identifier = identifier
    }
}

struct ConsentDocumentInfo: Codable, Sendable {
    let version: String
    let acceptanceDate: Date
    let sections: [ConsentSectionInfo]
}

struct ConsentSectionInfo: Codable, Sendable {
    let title: String
    let content: String
    let type: String
}

struct ArchivedConsentRecord: Codable, Sendable {
    enum RetentionPolicy: String, Codable, Sendable {
        case indefinite
        case years(Int)
        case deleteAfterStudy
    }

    let consentData: ConsentResultData
    let archiveDate: Date
    let archiveHash: String
    let retention: RetentionPolicy
}

struct ConsentWithdrawalRecord: Codable, Sendable {
    enum DataRetentionAfterWithdrawal: String, Codable, Sendable {
        case deleteAll = "delete_all"
        case deleteIdentifiers = "delete_identifiers"
        case retainAnonymized = "retain_anonymized"
    }

    let originalConsentId: String
    let withdrawalDate: Date
    let reason: String?
    let dataRetention: DataRetentionAfterWithdrawal
}

enum ConsentValidityStatus: Sendable {
    case valid
    case expired(reason: String)
    case notGiven(reason: String)
    case invalid(reason: String)
}

// MARK: - Error Types
enum ConsentResultHandlerError: LocalizedError {
    case noSignatureFound
    case invalidSignature
    case documentNotFound
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .noSignatureFound:
            return "No consent signature found in results"
        case .invalidSignature:
            return "Consent signature is invalid"
        case .documentNotFound:
            return "Consent document not found"
        case .processingFailed(let reason):
            return "Failed to process consent: \(reason)"
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
