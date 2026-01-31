import Foundation
import ResearchKit

/// Factory for creating completion steps
enum CompletionStepFactory {
    // MARK: - Public Methods

    /// Create a basic completion step
    static func createCompletionStep(
        identifier: String,
        title: String,
        text: String,
        image: UIImage? = nil
    ) -> ORKCompletionStep {
        let step = ORKCompletionStep(identifier: identifier)
        step.title = title
        step.text = text
        step.image = image ?? UIImage(systemName: "checkmark.circle.fill")
        return step
    }

    /// Create a success completion step
    static func createSuccessCompletionStep(
        identifier: String,
        title: String = "Congratulations",
        message: String = "You have successfully completed the task"
    ) -> ORKCompletionStep {
        let step = ORKCompletionStep(identifier: identifier)
        step.title = title
        step.text = message
        step.image = UIImage(systemName: "checkmark.circle.fill")
        return step
    }

    /// Create a completion step with next steps
    static func createCompletionWithNextStepsStep(
        identifier: String,
        title: String,
        message: String,
        nextSteps: [String]
    ) -> ORKCompletionStep {
        let step = ORKCompletionStep(identifier: identifier)
        step.title = title

        var fullText = message + "\n\n"
        fullText += "Next steps:\n"
        for (index, nextStep) in nextSteps.enumerated() {
            fullText += "\n\(index + 1). \(nextStep)"
        }

        step.text = fullText
        step.image = UIImage(systemName: "checkmark.circle.fill")
        return step
    }

    /// Create a completion step with results summary
    static func createResultsSummaryCompletionStep(
        identifier: String,
        title: String,
        summary: [ResultSummaryItem]
    ) -> ORKCompletionStep {
        let step = ORKCompletionStep(identifier: identifier)
        step.title = title

        var summaryText = "Here's a summary of your submission:\n\n"
        for item in summary {
            summaryText += "• \(item.label): \(item.value)\n"
        }

        step.text = summaryText
        step.image = UIImage(systemName: "checkmark.circle.fill")
        return step
    }

    /// Create a thank you completion step
    static func createThankYouCompletionStep(
        identifier: String,
        gratitudeMessage: String = "Thank you for your participation",
        additionalMessage: String? = nil
    ) -> ORKCompletionStep {
        let step = ORKCompletionStep(identifier: identifier)
        step.title = "Thank You"
        step.text = gratitudeMessage

        if let additional = additionalMessage {
            step.text = gratitudeMessage + "\n\n" + additional
        }

        step.image = UIImage(systemName: "heart.fill")
        return step
    }

    /// Create a data submission confirmation step
    static func createSubmissionConfirmationStep(
        identifier: String,
        title: String = "Submission Confirmed",
        submissionID: String? = nil,
        nextAction: String? = nil
    ) -> ORKCompletionStep {
        let step = ORKCompletionStep(identifier: identifier)
        step.title = title

        var text = "Your data has been successfully submitted."

        if let submissionID = submissionID {
            text += "\n\nSubmission ID: \(submissionID)"
        }

        if let nextAction = nextAction {
            text += "\n\n\(nextAction)"
        }

        step.text = text
        step.image = UIImage(systemName: "checkmark.circle.fill")
        return step
    }

    /// Create a completion step with survey link
    static func createCompletionWithSurveyStep(
        identifier: String,
        title: String,
        mainMessage: String,
        surveyInvitation: String
    ) -> ORKCompletionStep {
        let step = ORKCompletionStep(identifier: identifier)
        step.title = title
        step.text = mainMessage + "\n\n" + surveyInvitation
        step.image = UIImage(systemName: "checkmark.circle.fill")
        return step
    }

    /// Create a next session scheduled completion step
    static func createScheduledCompletionStep(
        identifier: String,
        nextSessionDate: Date,
        instructions: String? = nil
    ) -> ORKCompletionStep {
        let step = ORKCompletionStep(identifier: identifier)
        step.title = "Session Complete"

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let dateString = formatter.string(from: nextSessionDate)

        var text = "Your session is complete.\n\n"
        text += "Your next session is scheduled for: \(dateString)\n\n"

        if let instructions = instructions {
            text += instructions
        }

        step.text = text
        step.image = UIImage(systemName: "calendar.badge.checkmark")
        return step
    }

    /// Create a referral completion step
    static func createReferralCompletionStep(
        identifier: String,
        referralCode: String? = nil
    ) -> ORKCompletionStep {
        let step = ORKCompletionStep(identifier: identifier)
        step.title = "Help Us Grow"
        step.text = "Thank you for completing the study! Refer friends and earn rewards.\n\n"

        if let code = referralCode {
            step.text! += "Your referral code: \(code)"
        }

        step.image = UIImage(systemName: "person.badge.plus.fill")
        return step
    }

    /// Create a sample shipping completion step
    static func createSampleShippingCompletionStep(
        identifier: String,
        shippingAddress: String,
        trackingInfo: String? = nil
    ) -> ORKCompletionStep {
        let step = ORKCompletionStep(identifier: identifier)
        step.title = "Sample Collection Complete"

        var text = "Thank you for collecting your sample.\n\n"
        text += "Please ship to:\n\(shippingAddress)\n\n"
        text += "We will send shipping instructions and prepaid shipping label via email."

        if let tracking = trackingInfo {
            text += "\n\nTracking Information:\n\(tracking)"
        }

        step.text = text
        step.image = UIImage(systemName: "shippingbox.fill")
        return step
    }

    /// Create a data analysis completion step
    static func createDataAnalysisCompletionStep(
        identifier: String,
        estimatedTimeframe: String = "2-4 weeks"
    ) -> ORKCompletionStep {
        let step = ORKCompletionStep(identifier: identifier)
        step.title = "Data Received"
        step.text = """
            Your data has been received and will be analyzed shortly.

            Estimated timeframe for results: \(estimatedTimeframe)

            We'll notify you when results are available through the app.

            Thank you for your valuable contribution to science!
            """
        step.image = UIImage(systemName: "chart.xyaxis.circle.fill")
        return step
    }

    /// Create a contact support completion step
    static func createContactSupportCompletionStep(
        identifier: String,
        supportEmail: String,
        supportPhone: String? = nil
    ) -> ORKCompletionStep {
        let step = ORKCompletionStep(identifier: identifier)
        step.title = "Need Help?"
        step.text = "If you have any questions, please contact us:\n\n"
        step.text! += "Email: \(supportEmail)"

        if let phone = supportPhone {
            step.text! += "\nPhone: \(phone)"
        }

        step.image = UIImage(systemName: "questionmark.circle.fill")
        return step
    }

    /// Create a milestone completion step
    static func createMilestoneCompletionStep(
        identifier: String,
        milestoneTitle: String,
        unlockedBenefits: [String]
    ) -> ORKCompletionStep {
        let step = ORKCompletionStep(identifier: identifier)
        step.title = "Milestone Reached"
        step.text = "Congratulations! You've reached: \(milestoneTitle)\n\n"

        step.text! += "Unlocked benefits:\n"
        for benefit in unlockedBenefits {
            step.text! += "✓ \(benefit)\n"
        }

        step.image = UIImage(systemName: "star.fill")
        return step
    }

    /// Create a research results availability completion step
    static func createResultsAvailableCompletionStep(
        identifier: String,
        resultsDescription: String,
        checkDate: Date? = nil
    ) -> ORKCompletionStep {
        let step = ORKCompletionStep(identifier: identifier)
        step.title = "Results Available"
        step.text = resultsDescription

        if let date = checkDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let dateString = formatter.string(from: date)
            step.text! += "\n\nResults published on: \(dateString)"
        }

        step.image = UIImage(systemName: "book.circle.fill")
        return step
    }
}

// MARK: - Supporting Types
struct ResultSummaryItem: Sendable {
    let label: String
    let value: String

    init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}
