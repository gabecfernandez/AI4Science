import Foundation
import ResearchKit

/// Central manager for ResearchKit operations across the application
@MainActor
final class ResearchKitManager: NSObject, Sendable {
    // MARK: - Singleton
    static let shared = ResearchKitManager()

    // MARK: - Properties
    private let consentService: ConsentService
    private let surveyService: SurveyService
    private let taskService: TaskService
    private let resultProcessor: ResultProcessor

    private let logger = Logger(subsystem: "com.ai4science.researchkit", category: "Manager")

    // MARK: - Initialization
    override init() {
        self.consentService = ConsentService()
        self.surveyService = SurveyService()
        self.taskService = TaskService()
        self.resultProcessor = ResultProcessor()
        super.init()
    }

    // MARK: - Public Methods

    /// Initialize and configure ResearchKit
    func configure() async throws {
        logger.info("Configuring ResearchKit manager")

        // Configure appearance
        ResearchKitConfiguration.configure()

        // Verify framework availability
        try validateResearchKit()

        logger.info("ResearchKit configuration complete")
    }

    /// Create and return a consent task
    func createConsentTask(studyTitle: String, studyDescription: String) throws -> ORKTask {
        logger.debug("Creating consent task for study: \(studyTitle)")
        return try consentService.createConsentTask(studyTitle: studyTitle, studyDescription: studyDescription)
    }

    /// Create an onboarding survey task
    func createOnboardingSurvey() throws -> ORKTask {
        logger.debug("Creating onboarding survey task")
        return try surveyService.createOnboardingSurvey()
    }

    /// Create a demographic survey task
    func createDemographicsSurvey() throws -> ORKTask {
        logger.debug("Creating demographics survey task")
        return try surveyService.createDemographicsSurvey()
    }

    /// Create a custom survey with the specified questions
    func createCustomSurvey(identifier: String, title: String, questions: [SurveyQuestion]) throws -> ORKTask {
        logger.debug("Creating custom survey: \(identifier)")
        return try surveyService.createCustomSurvey(identifier: identifier, title: title, questions: questions)
    }

    /// Create a sample collection task
    func createSampleCollectionTask() throws -> ORKTask {
        logger.debug("Creating sample collection task")
        return try taskService.createSampleCollectionTask()
    }

    /// Create a quality assessment task
    func createQualityAssessmentTask() throws -> ORKTask {
        logger.debug("Creating quality assessment task")
        return try taskService.createQualityAssessmentTask()
    }

    /// Process task results
    func processTaskResult(_ taskResult: ORKTaskResult) async throws -> ProcessedResult {
        logger.debug("Processing task result: \(taskResult.identifier)")
        let processed = try resultProcessor.process(taskResult)
        logger.info("Task result processed successfully")
        return processed
    }

    /// Export task result in specified format
    func exportResult(_ taskResult: ORKTaskResult, format: ResultExportFormat) async throws -> Data {
        logger.debug("Exporting result in format: \(format)")
        let processed = try resultProcessor.process(taskResult)
        return try ResultExporter.export(processed, format: format)
    }

    // MARK: - Private Methods

    private func validateResearchKit() throws {
        // Validate that required ResearchKit features are available
        guard NSClassFromString("ORKTaskViewController") != nil else {
            throw ResearchKitManagerError.frameworkUnavailable
        }
    }
}

// MARK: - Error Types
enum ResearchKitManagerError: LocalizedError {
    case frameworkUnavailable
    case invalidConfiguration
    case taskCreationFailed(String)
    case resultProcessingFailed(String)

    var errorDescription: String? {
        switch self {
        case .frameworkUnavailable:
            return "ResearchKit framework is not available"
        case .invalidConfiguration:
            return "ResearchKit configuration is invalid"
        case .taskCreationFailed(let reason):
            return "Failed to create task: \(reason)"
        case .resultProcessingFailed(let reason):
            return "Failed to process result: \(reason)"
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
