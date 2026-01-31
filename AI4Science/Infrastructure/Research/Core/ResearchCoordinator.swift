import ResearchKit
import Foundation

/// Main coordinator for managing ResearchKit flows and study participation
@MainActor
final class ResearchCoordinator: NSObject {
    // MARK: - Properties

    private let studyManager: StudyManager
    private let consentManager: ConsentManager
    private let eligibilityChecker: EligibilityChecker
    private let resultProcessor: ResultProcessor

    weak var delegate: ResearchCoordinatorDelegate?

    var currentStudy: Study? {
        didSet {
            if let study = currentStudy {
                Task {
                    await studyManager.loadStudy(study)
                }
            }
        }
    }

    var participantID: String?
    var isEligible: Bool = false
    var hasConsented: Bool = false

    // MARK: - Initialization

    init(
        studyManager: StudyManager = .shared,
        consentManager: ConsentManager = .shared,
        eligibilityChecker: EligibilityChecker = .shared,
        resultProcessor: ResultProcessor = .shared
    ) {
        self.studyManager = studyManager
        self.consentManager = consentManager
        self.eligibilityChecker = eligibilityChecker
        self.resultProcessor = resultProcessor
        super.init()
    }

    // MARK: - Study Initialization

    /// Start a new research study
    func startStudy(_ study: Study) async throws {
        currentStudy = study
        participantID = UUID().uuidString

        do {
            try await studyManager.initializeStudy(
                study,
                participantID: participantID ?? ""
            )
            await delegate?.researchCoordinator(self, didStartStudy: study)
        } catch {
            await delegate?.researchCoordinator(self, didFailWithError: error)
            throw error
        }
    }

    // MARK: - Eligibility Flow

    /// Check participant eligibility
    func checkEligibility() async throws -> Bool {
        guard let study = currentStudy else {
            throw ResearchError.noActiveStudy
        }

        do {
            isEligible = try await eligibilityChecker.checkEligibility(for: study)
            await delegate?.researchCoordinator(self, eligibilityDidChange: isEligible)
            return isEligible
        } catch {
            await delegate?.researchCoordinator(self, didFailWithError: error)
            throw error
        }
    }

    /// Get eligibility task
    func getEligibilityTask() -> ORKTask? {
        guard let study = currentStudy else { return nil }
        return EligibilityStepBuilder.buildEligibilityTask(for: study)
    }

    // MARK: - Consent Flow

    /// Get informed consent task
    func getConsentTask() async -> ORKTask? {
        guard let study = currentStudy else { return nil }

        do {
            return await consentManager.buildConsentTask(for: study)
        } catch {
            await delegate?.researchCoordinator(self, didFailWithError: error)
            return nil
        }
    }

    /// Process consent result
    func processConsentResult(_ result: ORKTaskResult) async throws {
        do {
            let consented = try await consentManager.processConsentResult(result)
            hasConsented = consented

            if consented {
                await delegate?.researchCoordinator(self, consentDidChange: true)
            }
        } catch {
            await delegate?.researchCoordinator(self, didFailWithError: error)
            throw error
        }
    }

    // MARK: - Task Management

    /// Get next research task in the study protocol
    func getNextTask() async -> ORKTask? {
        guard let study = currentStudy else { return nil }
        guard hasConsented, isEligible else { return nil }

        do {
            return try await studyManager.getNextTask(for: study)
        } catch {
            await delegate?.researchCoordinator(self, didFailWithError: error)
            return nil
        }
    }

    /// Get all tasks for current study
    func getStudyTasks() async -> [ORKTask]? {
        guard let study = currentStudy else { return nil }

        do {
            return try await studyManager.getAllTasks(for: study)
        } catch {
            await delegate?.researchCoordinator(self, didFailWithError: error)
            return nil
        }
    }

    // MARK: - Result Processing

    /// Process completed task result
    func processTaskResult(_ result: ORKTaskResult) async throws {
        guard let participantID = participantID else {
            throw ResearchError.missingParticipantID
        }

        do {
            let processedResult = try await resultProcessor.processResult(
                result,
                participantID: participantID,
                studyID: currentStudy?.id ?? ""
            )

            try await studyManager.saveResult(processedResult)
            await delegate?.researchCoordinator(self, didCompleteTask: result)
        } catch {
            await delegate?.researchCoordinator(self, didFailWithError: error)
            throw error
        }
    }

    // MARK: - Study Completion

    /// Complete study participation
    func completeStudy() async throws {
        guard let study = currentStudy else {
            throw ResearchError.noActiveStudy
        }

        do {
            try await studyManager.completeStudy(study)
            await delegate?.researchCoordinator(self, didCompleteStudy: study)
        } catch {
            await delegate?.researchCoordinator(self, didFailWithError: error)
            throw error
        }
    }

    /// Withdraw from study
    func withdrawFromStudy() async throws {
        guard let study = currentStudy else {
            throw ResearchError.noActiveStudy
        }

        do {
            try await studyManager.withdrawStudy(study)
            await delegate?.researchCoordinator(self, didWithdrawFromStudy: study)
        } catch {
            await delegate?.researchCoordinator(self, didFailWithError: error)
            throw error
        }
    }
}

// MARK: - Delegate Protocol

@MainActor
protocol ResearchCoordinatorDelegate: AnyObject {
    func researchCoordinator(_ coordinator: ResearchCoordinator, didStartStudy study: Study)
    func researchCoordinator(_ coordinator: ResearchCoordinator, eligibilityDidChange isEligible: Bool)
    func researchCoordinator(_ coordinator: ResearchCoordinator, consentDidChange hasConsented: Bool)
    func researchCoordinator(_ coordinator: ResearchCoordinator, didCompleteTask result: ORKTaskResult)
    func researchCoordinator(_ coordinator: ResearchCoordinator, didCompleteStudy study: Study)
    func researchCoordinator(_ coordinator: ResearchCoordinator, didWithdrawFromStudy study: Study)
    func researchCoordinator(_ coordinator: ResearchCoordinator, didFailWithError error: Error)
}

// MARK: - Models

struct Study: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let investigator: String
    let institution: String
    let contactEmail: String
    let consentDocumentPath: String?
    let estimatedDuration: Int // minutes
    let taskIDs: [String]
    let eligibilityCriteria: [String: AnyCodable]
}

enum ResearchError: LocalizedError {
    case noActiveStudy
    case missingParticipantID
    case taskNotFound
    case invalidResult
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .noActiveStudy:
            return "No active study set"
        case .missingParticipantID:
            return "Participant ID not initialized"
        case .taskNotFound:
            return "Requested task not found"
        case .invalidResult:
            return "Invalid task result"
        case .processingFailed(let reason):
            return "Processing failed: \(reason)"
        }
    }
}

struct AnyCodable: Codable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let intVal = value as? Int {
            try container.encode(intVal)
        } else if let doubleVal = value as? Double {
            try container.encode(doubleVal)
        } else if let stringVal = value as? String {
            try container.encode(stringVal)
        } else if let boolVal = value as? Bool {
            try container.encode(boolVal)
        }
    }
}
