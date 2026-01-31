import Foundation
import ResearchKit

/// Factory for creating review steps
enum ReviewStepFactory {
    // MARK: - Public Methods

    /// Create a basic review step
    static func createReviewStep(
        identifier: String,
        title: String,
        text: String
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = title
        step.text = text
        step.image = UIImage(systemName: "checkmark.circle.fill")
        return step
    }

    /// Create a data review step
    static func createDataReviewStep(
        identifier: String,
        dataItems: [ReviewDataItem]
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = "Review Your Data"
        step.text = "Please review the following information before submitting:\n\n"

        for item in dataItems {
            step.text! += "• \(item.label): \(item.value)\n"
        }

        step.text! += "\nIf any information is incorrect, you can go back and edit it."
        step.image = UIImage(systemName: "list.clipboard.fill")
        return step
    }

    /// Create a consent review confirmation step
    static func createConsentReviewStep(
        identifier: String
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = "Review Consent"
        step.text = """
            Please review the consent document carefully. By proceeding, you confirm that:

            ✓ You have read and understood the study information
            ✓ You have had the opportunity to ask questions
            ✓ You voluntarily agree to participate
            ✓ You understand that you can withdraw at any time

            Tap Continue to provide your digital signature.
            """
        step.image = UIImage(systemName: "doc.text.fill")
        return step
    }

    /// Create a protocol compliance review step
    static func createProtocolComplianceReviewStep(
        identifier: String,
        protocols: [ProtocolItem]
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = "Protocol Compliance Review"
        step.text = "Please confirm that you followed all protocols:\n\n"

        for protocol in protocols {
            step.text! += "✓ \(protocol.name)\n"
            step.text! += "   \(protocol.description)\n\n"
        }

        step.image = UIImage(systemName: "list.clipboard.fill")
        return step
    }

    /// Create a quality assurance review step
    static func createQualityAssuranceReviewStep(
        identifier: String,
        qualityChecks: [QualityCheckItem]
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = "Quality Assurance Review"
        step.text = "Quality checks performed:\n\n"

        for check in qualityChecks {
            let status = check.passed ? "✓ PASS" : "✗ FAIL"
            step.text! += "\(status): \(check.name)\n"
            if let notes = check.notes {
                step.text! += "   Notes: \(notes)\n"
            }
            step.text! += "\n"
        }

        step.image = UIImage(systemName: "checkmark.seal.fill")
        return step
    }

    /// Create a summary review step
    static func createSummaryReviewStep(
        identifier: String,
        summaryTitle: String,
        sections: [ReviewSection]
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = summaryTitle
        step.text = ""

        for section in sections {
            step.text! += "** \(section.title) **\n"
            for item in section.items {
                step.text! += "• \(item.label): \(item.value)\n"
            }
            step.text! += "\n"
        }

        step.text! += "Please review all information before submitting."
        step.image = UIImage(systemName: "doc.richtext.fill")
        return step
    }

    /// Create a survey response review step
    static func createSurveyReviewStep(
        identifier: String,
        responses: [SurveyResponseItem]
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = "Review Survey Responses"
        step.text = "Here are your survey responses:\n\n"

        for response in responses {
            step.text! += "Q: \(response.question)\n"
            step.text! += "A: \(response.answer)\n\n"
        }

        step.text! += "If you need to make changes, go back to the previous steps."
        step.image = UIImage(systemName: "questionmark.circle.fill")
        return step
    }

    /// Create a submission confirmation review step
    static func createSubmissionReviewStep(
        identifier: String,
        submissionDetails: SubmissionDetails
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = "Submission Review"

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let dateString = formatter.string(from: submissionDetails.submissionTime)

        step.text = """
            Submission Details:

            • Study: \(submissionDetails.studyName)
            • Submission Time: \(dateString)
            • Data Files: \(submissionDetails.fileCount)
            • Total Size: \(submissionDetails.totalSize)
            • Status: \(submissionDetails.status)

            Please review before final submission.
            """

        step.image = UIImage(systemName: "checkmark.circle.fill")
        return step
    }

    /// Create a data integrity review step
    static func createDataIntegrityReviewStep(
        identifier: String,
        integrityChecks: [IntegrityCheckResult]
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = "Data Integrity Verification"
        step.text = "Data integrity checks:\n\n"

        for check in integrityChecks {
            step.text! += "• \(check.checkName): \(check.result ? "Valid" : "Invalid")\n"
            if let errorMessage = check.errorMessage {
                step.text! += "  ⚠️ \(errorMessage)\n"
            }
        }

        step.image = UIImage(systemName: "checkmark.seal.fill")
        return step
    }

    /// Create a disclaimer review step
    static func createDisclaimerReviewStep(
        identifier: String,
        disclaimer: String
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = "Important Disclaimer"
        step.text = disclaimer
        step.image = UIImage(systemName: "exclamationmark.triangle.fill")
        return step
    }

    /// Create a payment/compensation review step
    static func createCompensationReviewStep(
        identifier: String,
        amount: String,
        compensationType: String
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = "Compensation Details"
        step.text = """
            For your participation, you will receive:

            Amount: \(amount)
            Type: \(compensationType)

            Payment will be processed within 5 business days of study completion.

            Please review your compensation details.
            """
        step.image = UIImage(systemName: "dollarsign.circle.fill")
        return step
    }

    /// Create a withdrawal review step
    static func createWithdrawalReviewStep(
        identifier: String
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = "Confirm Withdrawal"
        step.text = """
            You are about to withdraw from this study.

            Please note:
            • Your data collected so far may still be used (unless you request deletion)
            • You will be removed from future study communications
            • You can re-enroll later if you change your mind

            Are you sure you want to withdraw?
            """
        step.image = UIImage(systemName: "xmark.circle.fill")
        return step
    }
}

// MARK: - Supporting Types
struct ReviewDataItem: Sendable {
    let label: String
    let value: String

    init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

struct ProtocolItem: Sendable {
    let name: String
    let description: String

    init(name: String, description: String) {
        self.name = name
        self.description = description
    }
}

struct QualityCheckItem: Sendable {
    let name: String
    let passed: Bool
    let notes: String?

    init(name: String, passed: Bool, notes: String? = nil) {
        self.name = name
        self.passed = passed
        self.notes = notes
    }
}

struct ReviewSection: Sendable {
    let title: String
    let items: [ReviewDataItem]

    init(title: String, items: [ReviewDataItem]) {
        self.title = title
        self.items = items
    }
}

struct SurveyResponseItem: Sendable {
    let question: String
    let answer: String

    init(question: String, answer: String) {
        self.question = question
        self.answer = answer
    }
}

struct SubmissionDetails: Sendable {
    let studyName: String
    let submissionTime: Date
    let fileCount: Int
    let totalSize: String
    let status: String

    init(studyName: String, submissionTime: Date, fileCount: Int, totalSize: String, status: String) {
        self.studyName = studyName
        self.submissionTime = submissionTime
        self.fileCount = fileCount
        self.totalSize = totalSize
        self.status = status
    }
}

struct IntegrityCheckResult: Sendable {
    let checkName: String
    let result: Bool
    let errorMessage: String?

    init(checkName: String, result: Bool, errorMessage: String? = nil) {
        self.checkName = checkName
        self.result = result
        self.errorMessage = errorMessage
    }
}
