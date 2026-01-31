import SwiftUI
import ResearchKit

/// Coordinates the consent flow in SwiftUI
@MainActor
final class ConsentViewCoordinator: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isPresented = false
    @Published var consentResult: ConsentResultData?
    @Published var error: Error?
    @Published var isLoading = false

    // MARK: - Properties
    private let consentService: ConsentService
    private let consentResultHandler: ConsentResultHandler
    let logger = Logger(subsystem: "com.ai4science.researchkit", category: "ConsentCoordinator")

    // MARK: - Initialization
    init(
        consentService: ConsentService = ConsentService(),
        consentResultHandler: ConsentResultHandler = ConsentResultHandler()
    ) {
        self.consentService = consentService
        self.consentResultHandler = consentResultHandler
        super.init()
    }

    // MARK: - Public Methods

    /// Present consent task
    func presentConsentTask(
        studyTitle: String,
        studyDescription: String
    ) {
        logger.info("Presenting consent task")
        isPresented = true
    }

    /// Handle consent completion
    func handleConsentCompletion(_ taskResult: ORKTaskResult) async {
        logger.debug("Processing consent completion")
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await consentResultHandler.processConsentResult(taskResult)
            self.consentResult = result

            // Verify consent validity
            let status = await consentResultHandler.verifyConsentValidity(result)
            switch status {
            case .valid:
                logger.info("Consent is valid")
            case .expired(let reason):
                logger.warning("Consent expired: \(reason)")
            case .notGiven(let reason):
                logger.warning("Consent not given: \(reason)")
            case .invalid(let reason):
                logger.error("Consent invalid: \(reason)")
            }

            // Archive consent record
            _ = try await consentResultHandler.archiveConsentRecord(result)

        } catch {
            logger.error("Failed to process consent: \(error.localizedDescription)")
            self.error = error
        }
    }

    /// Check if consent has been given
    func hasConsent() async -> Bool {
        return consentResult?.consentGiven ?? false
    }

    /// Get consent status
    func getConsentStatus() async -> ConsentValidityStatus {
        guard let result = consentResult else {
            return .notGiven(reason: "No consent record found")
        }
        return await consentResultHandler.verifyConsentValidity(result)
    }

    /// Withdraw consent
    func withdrawConsent() async {
        logger.info("Withdrawing consent")

        guard let result = consentResult else {
            logger.warning("No consent to withdraw")
            return
        }

        do {
            let withdrawalRecord = try await consentResultHandler.processConsentWithdrawal(
                originalConsentId: result.timestamp.ISO8601Format(),
                withdrawalReason: "User initiated"
            )
            logger.info("Consent withdrawn: \(withdrawalRecord.originalConsentId)")
            self.consentResult = nil
        } catch {
            logger.error("Failed to withdraw consent: \(error.localizedDescription)")
            self.error = error
        }
    }

    /// Get consent document info
    func getConsentDocumentInfo(_ taskResult: ORKTaskResult) async throws -> ConsentDocumentInfo {
        logger.debug("Extracting consent document info")
        return try await consentResultHandler.extractConsentDocumentInfo(taskResult)
    }
}

// MARK: - SwiftUI View
struct ConsentView: View {
    @StateObject private var coordinator = ConsentViewCoordinator()

    let studyTitle: String
    let studyDescription: String
    var onConsentGiven: (() -> Void)?
    var onCancel: (() -> Void)?

    var body: some View {
        ZStack {
            if coordinator.isPresented {
                ConsentTaskView(coordinator: coordinator, studyTitle: studyTitle, studyDescription: studyDescription)
                    .onDisappear {
                        if coordinator.consentResult?.consentGiven ?? false {
                            onConsentGiven?()
                        } else {
                            onCancel?()
                        }
                    }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("Informed Consent")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Please read and agree to the informed consent document before proceeding with the study.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)

                    Button(action: {
                        coordinator.presentConsentTask(
                            studyTitle: studyTitle,
                            studyDescription: studyDescription
                        )
                    }) {
                        Text("Review Consent Document")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    if let error = coordinator.error {
                        Text("Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
            }
        }
        .environmentObject(coordinator)
    }
}

// MARK: - Consent Task View
struct ConsentTaskView: View {
    @ObservedObject var coordinator: ConsentViewCoordinator
    let studyTitle: String
    let studyDescription: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            if coordinator.isLoading {
                ProgressView()
            } else {
                Text("Consent Task")
            }
        }
        .navigationTitle("Consent")
        .navigationBarTitleDisplayMode(.inline)
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
