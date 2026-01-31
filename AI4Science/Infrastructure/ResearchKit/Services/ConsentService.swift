import Foundation
import ResearchKit

/// Service for managing informed consent workflows
actor ConsentService {
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.ai4science.researchkit", category: "ConsentService")

    // MARK: - Public Methods

    /// Create a complete consent task with document and signature
    func createConsentTask(studyTitle: String, studyDescription: String) throws -> ORKTask {
        logger.info("Creating consent task")

        let consentDocument = try createConsentDocument(studyTitle: studyTitle, studyDescription: studyDescription)
        let consentTask = ORKConsentReviewStep(identifier: "consentReview", signature: consentDocument.signatures.first, in: consentDocument)

        consentTask.text = "Review and sign the consent document"
        consentTask.reasonForConsent = "Your consent is required to participate in this study"

        let steps: [ORKStep] = [consentTask]
        let task = ORKOrderedTask(identifier: "consentTask", steps: steps)

        return task
    }

    /// Create a consent document with standard sections
    func createConsentDocument(studyTitle: String, studyDescription: String) throws -> ORKConsentDocument {
        logger.debug("Creating consent document")

        let document = ORKConsentDocument()
        document.title = studyTitle
        document.summary = studyDescription

        // Overview section
        let overviewSection = ORKConsentSection(type: .overview)
        overviewSection.summary = "Overview of the study"
        overviewSection.content = studyDescription

        // Data gathering section
        let dataSection = ORKConsentSection(type: .dataGathering)
        dataSection.summary = "Data Collection"
        dataSection.content = "This study will collect survey responses and research data. Your data will be securely stored and processed."

        // Privacy section
        let privacySection = ORKConsentSection(type: .privacy)
        privacySection.summary = "Privacy & Security"
        privacySection.content = "Your personal information will be kept confidential and used only for research purposes. We comply with HIPAA and GDPR regulations."

        // Data use section
        let dataUseSection = ORKConsentSection(type: .dataUse)
        dataUseSection.summary = "Data Use"
        dataUseSection.content = "Your data will be used for analysis and may be published in anonymized form for scientific purposes."

        // Time commitment section
        let timeSection = ORKConsentSection(type: .timeCommitment)
        timeSection.summary = "Time Commitment"
        timeSection.content = "The study will take approximately 30-45 minutes to complete."

        // Set sections
        document.sections = [
            overviewSection,
            dataSection,
            privacySection,
            dataUseSection,
            timeSection
        ]

        // Add signature for participant
        let signature = ORKConsentSignature(forPersonWithTitle: "Participant", dateFormatString: nil, identifier: "participantSignature")
        signature.signatureImage = nil
        signature.signatureDateString = nil

        document.addSignature(signature)

        return document
    }

    /// Handle consent completion
    func handleConsentCompletion(result: ORKTaskResult) throws -> ConsentResult {
        logger.debug("Handling consent completion")

        guard let consentReviewResult = result.results?.first as? ORKConsentSignatureResult else {
            throw ConsentServiceError.invalidResult
        }

        let consentGiven = consentReviewResult.consented
        let timestamp = Date()

        logger.info("Consent processed: \(consentGiven)")

        return ConsentResult(
            consentGiven: consentGiven,
            timestamp: timestamp,
            documentVersion: "1.0"
        )
    }

    /// Retrieve previously given consent
    func retrieveConsentStatus() async -> ConsentStatus {
        // This would typically check persistent storage
        logger.debug("Retrieving consent status")
        return .notGiven
    }

    /// Withdraw consent
    func withdrawConsent() async throws {
        logger.info("Withdrawing consent")
        // Implement consent withdrawal logic
    }
}

// MARK: - Models
struct ConsentResult: Codable, Sendable {
    let consentGiven: Bool
    let timestamp: Date
    let documentVersion: String
}

enum ConsentStatus: Sendable {
    case notGiven
    case given(Date)
    case withdrawn(Date)
}

// MARK: - Error Types
enum ConsentServiceError: LocalizedError {
    case invalidResult
    case consentNotGiven
    case documentCreationFailed

    var errorDescription: String? {
        switch self {
        case .invalidResult:
            return "Invalid consent result structure"
        case .consentNotGiven:
            return "Consent was not provided"
        case .documentCreationFailed:
            return "Failed to create consent document"
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
