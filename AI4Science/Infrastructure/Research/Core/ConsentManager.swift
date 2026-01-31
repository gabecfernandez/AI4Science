#if canImport(ResearchKit)
import ResearchKit
#endif
import Foundation

/// Manages informed consent flows and documentation
@MainActor
final class ConsentManager: NSObject {
    // MARK: - Singleton

    static let shared = ConsentManager()

    // MARK: - Properties

    private let documentBuilder = ConsentDocumentBuilder()
    private let resultHandler = ConsentResultHandler()
    private let pdfGenerator = ConsentPDFGenerator()
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()

    private var consentResults: [String: ConsentData] = [:]

    // MARK: - Consent Task Building

    /// Build consent task for a study
    func buildConsentTask(for study: Study) async -> ORKTask {
        let document = await documentBuilder.buildConsentDocument(for: study)
        let reviewStep = ORKConsentReviewStep(
            identifier: "consentReviewStep",
            with: document
        )
        reviewStep.text = "Review and sign the informed consent document"
        reviewStep.reason = "We need your consent to proceed with this research study"

        return ORKOrderedTask(
            identifier: "consentTask",
            steps: [reviewStep]
        )
    }

    /// Process consent task result
    func processConsentResult(_ result: ORKTaskResult) async throws -> Bool {
        do {
            let consentData = try resultHandler.handleConsentResult(result)
            return consentData.signed
        } catch {
            throw error
        }
    }

    /// Save consent data with signature
    func saveConsentData(
        _ result: ORKTaskResult,
        for studyID: String,
        participantID: String
    ) async throws {
        do {
            let consentData = try resultHandler.handleConsentResult(result)
            var updatedData = consentData
            updatedData.studyID = studyID
            updatedData.participantID = participantID

            // Generate PDF with signature
            if let signatureImage = consentData.signatureImage {
                let pdfPath = try await pdfGenerator.generateConsentPDF(
                    studyID: studyID,
                    participantID: participantID,
                    signatureImage: signatureImage
                )
                updatedData.pdfPath = pdfPath
            }

            // Save consent data
            try persistConsentData(updatedData)
            consentResults[studyID] = updatedData

        } catch {
            throw error
        }
    }

    /// Get consent status for study
    func getConsentStatus(for studyID: String) -> ConsentStatus {
        guard let consentData = consentResults[studyID] else {
            return .notProvided
        }

        if consentData.signed {
            return .signed
        } else {
            return .pending
        }
    }

    /// Check if consent is valid
    func isConsentValid(for studyID: String) -> Bool {
        guard let consentData = consentResults[studyID] else {
            return false
        }

        // Check if signed and not expired
        let expirationDate = Calendar.current.date(
            byAdding: .year,
            value: 1,
            to: consentData.timestamp
        ) ?? Date.distantFuture

        return consentData.signed && Date() < expirationDate
    }

    /// Revoke consent
    func revokeConsent(for studyID: String) async throws {
        var consentData = consentResults[studyID]
        consentData?.signed = false
        consentData?.revokedDate = Date()

        if let data = consentData {
            try persistConsentData(data)
            consentResults[studyID] = data
        }
    }

    /// Get consent PDF path
    func getConsentPDFPath(for studyID: String) -> String? {
        consentResults[studyID]?.pdfPath
    }

    // MARK: - Private Helpers

    private func persistConsentData(_ consentData: ConsentData) throws {
        let baseURL = getConsentDirectory(for: consentData.studyID)

        let fileName = "consent_\(consentData.participantID).json"
        let fileURL = baseURL.appendingPathComponent(fileName)

        let data = try encoder.encode(consentData)
        try data.write(to: fileURL)
    }

    private func getConsentDirectory(for studyID: String) -> URL {
        let appSupportURL = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let baseURL = (appSupportURL ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("Studies")
            .appendingPathComponent(studyID)

        let consentURL = baseURL.appendingPathComponent("consent")

        try? fileManager.createDirectory(
            at: consentURL,
            withIntermediateDirectories: true
        )

        return consentURL
    }
}

// MARK: - Models

struct ConsentData: Codable {
    var studyID: String = ""
    var participantID: String = ""
    let timestamp: Date
    var revokedDate: Date?
    var signed: Bool = false
    let consentDocument: ConsentDocumentInfo
    var signatureImage: UIImage?
    var pdfPath: String?

    enum CodingKeys: String, CodingKey {
        case studyID, participantID, timestamp, revokedDate, signed, consentDocument, pdfPath
    }

    init(
        timestamp: Date,
        signed: Bool = false,
        consentDocument: ConsentDocumentInfo,
        signatureImage: UIImage? = nil
    ) {
        self.timestamp = timestamp
        self.signed = signed
        self.consentDocument = consentDocument
        self.signatureImage = signatureImage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        studyID = try container.decode(String.self, forKey: .studyID)
        participantID = try container.decode(String.self, forKey: .participantID)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        revokedDate = try container.decodeIfPresent(Date.self, forKey: .revokedDate)
        signed = try container.decode(Bool.self, forKey: .signed)
        consentDocument = try container.decode(ConsentDocumentInfo.self, forKey: .consentDocument)
        pdfPath = try container.decodeIfPresent(String.self, forKey: .pdfPath)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(studyID, forKey: .studyID)
        try container.encode(participantID, forKey: .participantID)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(revokedDate, forKey: .revokedDate)
        try container.encode(signed, forKey: .signed)
        try container.encode(consentDocument, forKey: .consentDocument)
        try container.encodeIfPresent(pdfPath, forKey: .pdfPath)
    }
}

struct ConsentDocumentInfo: Codable {
    let title: String
    let summary: String
    let investigator: String
    let institution: String
    let contactEmail: String
    let sections: [ConsentSectionInfo]
}

struct ConsentSectionInfo: Codable {
    let type: String
    let title: String
    let content: String
}

enum ConsentStatus: String {
    case notProvided = "Not Provided"
    case pending = "Pending"
    case signed = "Signed"
    case revoked = "Revoked"
}
