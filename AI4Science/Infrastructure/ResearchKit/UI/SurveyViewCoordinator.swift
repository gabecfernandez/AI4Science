import SwiftUI
import ResearchKit

/// Coordinates the survey flow in SwiftUI
@MainActor
final class SurveyViewCoordinator: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isPresented = false
    @Published var surveyResult: SurveyResultData?
    @Published var error: Error?
    @Published var isLoading = false
    @Published var progress: Double = 0

    // MARK: - Properties
    private let surveyService: SurveyService
    private let surveyResultHandler: SurveyResultHandler
    let logger = Logger(subsystem: "com.ai4science.researchkit", category: "SurveyCoordinator")

    // MARK: - Initialization
    init(
        surveyService: SurveyService = SurveyService(),
        surveyResultHandler: SurveyResultHandler = SurveyResultHandler()
    ) {
        self.surveyService = surveyService
        self.surveyResultHandler = surveyResultHandler
        super.init()
    }

    // MARK: - Public Methods

    /// Present a survey task
    func presentSurvey(
        identifier: String,
        title: String,
        questions: [SurveyQuestion]
    ) async {
        logger.info("Presenting survey: \(identifier)")
        isPresented = true
    }

    /// Present onboarding survey
    func presentOnboardingSurvey() async {
        logger.info("Presenting onboarding survey")
        isPresented = true
    }

    /// Present demographics survey
    func presentDemographicsSurvey() async {
        logger.info("Presenting demographics survey")
        isPresented = true
    }

    /// Handle survey completion
    func handleSurveyCompletion(_ taskResult: ORKTaskResult) async {
        logger.debug("Processing survey completion")
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await surveyResultHandler.processSurveyResult(taskResult)
            self.surveyResult = result

            // Validate responses
            let validation = try await surveyResultHandler.validateSurveyResponses(result)
            if validation.isValid {
                logger.info("Survey responses validated successfully")
            } else {
                logger.warning("Survey validation found errors: \(validation.errors)")
            }

            // Calculate statistics
            let statistics = await surveyResultHandler.calculateSurveyStatistics(result)
            logger.info("Survey stats - Responses: \(statistics.totalResponses), Completion: \(statistics.completionPercentage)%")

        } catch {
            logger.error("Failed to process survey: \(error.localizedDescription)")
            self.error = error
        }
    }

    /// Get survey statistics
    func getSurveyStatistics() -> SurveyStatistics? {
        guard let result = surveyResult else { return nil }
        return Task {
            return await surveyResultHandler.calculateSurveyStatistics(result)
        }.result == nil ? nil : surveyResult.map { _ in
            // Statistics would be calculated here
            SurveyStatistics(
                totalResponses: surveyResult?.responses.count ?? 0,
                completionPercentage: 100.0,
                averageScales: [:],
                choiceFrequency: [:],
                textResponseCount: 0,
                completionTime: surveyResult?.duration ?? 0
            )
        } as? SurveyStatistics
    }

    /// Export survey results
    func exportSurveyResults(format: ResultExportFormat) async throws -> Data {
        guard let result = surveyResult else {
            throw SurveyCoordinatorError.noSurveyResults
        }

        logger.debug("Exporting survey results in format: \(format.rawValue)")

        switch format {
        case .csv:
            return try await surveyResultHandler.exportToCSV(result).data(using: .utf8) ?? Data()
        case .json:
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(result)
        default:
            return try encoder.encode(result)
        }
    }

    /// Get response for specific question
    func getResponse(for questionId: String) -> SurveyResponse? {
        guard let result = surveyResult else { return nil }
        return Task {
            return await surveyResultHandler.getResponse(for: questionId, from: result)
        }.result ?? nil
    }

    /// Create response summary
    func getResponseSummary() async -> ResponseSummary? {
        guard let result = surveyResult else { return nil }
        return await surveyResultHandler.createResponseSummary(result)
    }

    private let encoder = JSONEncoder()
}

// MARK: - SwiftUI View
struct SurveyView: View {
    @StateObject private var coordinator = SurveyViewCoordinator()

    let surveyIdentifier: String
    let surveyTitle: String
    var questions: [SurveyQuestion]?
    var onCompletion: ((SurveyResultData) -> Void)?
    var onCancel: (() -> Void)?

    var body: some View {
        ZStack {
            if coordinator.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Processing Survey")
                        .font(.headline)

                    Text("Analyzing your responses...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else if let result = coordinator.surveyResult {
                SurveyCompletionView(result: result)
            } else {
                SurveyStartView(
                    title: surveyTitle,
                    onStart: {
                        Task {
                            await coordinator.presentSurvey(
                                identifier: surveyIdentifier,
                                title: surveyTitle,
                                questions: questions ?? []
                            )
                        }
                    }
                )
            }

            if let error = coordinator.error {
                ErrorBanner(error: error)
            }
        }
        .environmentObject(coordinator)
    }
}

// MARK: - Survey Start View
struct SurveyStartView: View {
    let title: String
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.clipboard.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text(title)
                .font(.title)
                .fontWeight(.bold)

            Text("Your responses will help us better understand the research community.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            Button(action: onStart) {
                Text("Start Survey")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Survey Completion View
struct SurveyCompletionView: View {
    let result: SurveyResultData

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Survey Complete")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Responses Recorded:")
                    Spacer()
                    Text("\(result.responseCount)")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Time Spent:")
                    Spacer()
                    Text(formatDuration(result.duration))
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Status:")
                    Spacer()
                    Text(result.completionStatus.rawValue.capitalized)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)

            Text("Thank you for completing the survey!")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Error Banner
struct ErrorBanner: View {
    let error: Error

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)

                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemRed).opacity(0.1))
        .cornerRadius(8)
        .padding()
    }
}

// MARK: - Helper Functions
private func formatDuration(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds) / 60
    let remainingSeconds = Int(seconds) % 60

    if minutes > 0 {
        return "\(minutes)m \(remainingSeconds)s"
    } else {
        return "\(remainingSeconds)s"
    }
}

// MARK: - Error Types
enum SurveyCoordinatorError: LocalizedError {
    case noSurveyResults

    var errorDescription: String? {
        switch self {
        case .noSurveyResults:
            return "No survey results available"
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

    func warning(_ message: String) {
        os_log("%{public}@", log: getLog(), type: .default, message)
    }

    func error(_ message: String) {
        os_log("%{public}@", log: getLog(), type: .error, message)
    }

    private func getLog() -> os.OSLog {
        return OSLog(subsystem: subsystem, category: category)
    }
}

import os
