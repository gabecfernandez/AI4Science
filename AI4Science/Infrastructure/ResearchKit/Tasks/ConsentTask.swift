import Foundation
import ResearchKit

/// Task for managing informed consent workflows
struct ConsentTask: Sendable {
    // MARK: - Properties
    let studyTitle: String
    let studyDescription: String
    let principalInvestigator: String?
    let institution: String?
    let contactEmail: String?
    let contactPhone: String?

    // MARK: - Initialization
    init(
        studyTitle: String,
        studyDescription: String,
        principalInvestigator: String? = nil,
        institution: String? = nil,
        contactEmail: String? = nil,
        contactPhone: String? = nil
    ) {
        self.studyTitle = studyTitle
        self.studyDescription = studyDescription
        self.principalInvestigator = principalInvestigator
        self.institution = institution
        self.contactEmail = contactEmail
        self.contactPhone = contactPhone
    }

    // MARK: - Methods

    /// Create the ORKTask for consent workflow
    func buildTask() throws -> ORKTask {
        var steps: [ORKStep] = []

        // Introduction step
        let introductionStep = InstructionStepFactory.createInstructionStep(
            identifier: "consentIntroduction",
            title: "Research Study",
            text: "You are invited to participate in a research study. Please review the information below."
        )
        steps.append(introductionStep)

        // Create consent document
        let consentDocument = try createConsentDocument()

        // Visual consent steps
        let visualConsentSteps = try createVisualConsentSteps()
        steps.append(contentsOf: visualConsentSteps)

        // Consent review step with signature
        let consentReviewStep = ORKConsentReviewStep(
            identifier: "consentReview",
            signature: consentDocument.signatures.first,
            in: consentDocument
        )
        consentReviewStep.text = "Please review and sign the consent form"
        consentReviewStep.reasonForConsent = "Your signature confirms that you understand the study and agree to participate"
        steps.append(consentReviewStep)

        // Final confirmation
        let confirmationStep = ORKQuestionStep(
            identifier: "consentConfirmation",
            title: "Final Confirmation",
            answer: ORKAnswerFormat.booleanAnswerFormat()
        )
        confirmationStep.text = "Do you consent to participate in this study?"
        steps.append(confirmationStep)

        // Completion
        let completionStep = CompletionStepFactory.createCompletionStep(
            identifier: "consentCompletion",
            title: "Consent Accepted",
            text: "Thank you for your consent. You may now proceed to the study."
        )
        steps.append(completionStep)

        return ORKOrderedTask(identifier: "consentTask", steps: steps)
    }

    // MARK: - Private Methods

    private func createConsentDocument() throws -> ORKConsentDocument {
        let document = ORKConsentDocument()
        document.title = studyTitle
        document.summary = studyDescription

        var sections: [ORKConsentSection] = []

        // Overview
        let overviewSection = ORKConsentSection(type: .overview)
        overviewSection.summary = "Study Overview"
        overviewSection.content = createOverviewContent()
        sections.append(overviewSection)

        // Data gathering
        let dataGatheringSection = ORKConsentSection(type: .dataGathering)
        dataGatheringSection.summary = "What Data Will Be Collected"
        dataGatheringSection.content = """
            We will collect:
            - Survey responses
            - Research samples
            - Environmental data
            - Demographic information
            - Study-related measurements

            All data will be treated as confidential and stored securely.
            """
        sections.append(dataGatheringSection)

        // Privacy
        let privacySection = ORKConsentSection(type: .privacy)
        privacySection.summary = "Privacy & Confidentiality"
        privacySection.content = """
            Your privacy is important to us. We follow strict data protection guidelines:
            - Your data is encrypted and stored securely
            - Access is restricted to authorized research personnel
            - Your identity will be kept confidential
            - We comply with HIPAA and GDPR regulations
            """
        sections.append(privacySection)

        // Data use
        let dataUseSection = ORKConsentSection(type: .dataUse)
        dataUseSection.summary = "How Your Data Will Be Used"
        dataUseSection.content = """
            Your data will be used for:
            - Scientific research and analysis
            - Publication in peer-reviewed journals
            - Educational purposes
            - Collaboration with other researchers

            All published data will be anonymized.
            """
        sections.append(dataUseSection)

        // Time commitment
        let timeSection = ORKConsentSection(type: .timeCommitment)
        timeSection.summary = "Time Commitment"
        timeSection.content = "This study will require approximately 45-60 minutes of your time."
        sections.append(timeSection)

        // Benefits
        let benefitsSection = ORKConsentSection(type: .benefits)
        benefitsSection.summary = "Potential Benefits"
        benefitsSection.content = """
            Benefits of participation may include:
            - Contributing to scientific knowledge
            - Receiving feedback on your participation
            - Personal reports of your data
            """
        sections.append(benefitsSection)

        // Risks
        let risksSection = ORKConsentSection(type: .risks)
        risksSection.summary = "Potential Risks"
        risksSection.content = """
            This study involves minimal risk. Potential discomforts include:
            - Time spent completing surveys
            - Possible mild discomfort during sample collection

            These risks are considered minimal and temporary.
            """
        sections.append(risksSection)

        document.sections = sections

        // Add participant signature
        let participantSignature = ORKConsentSignature(
            forPersonWithTitle: "Participant",
            dateFormatString: nil,
            identifier: "participantSignature"
        )
        document.addSignature(participantSignature)

        // Add investigator signature if available
        if let investigator = principalInvestigator {
            let investigatorSignature = ORKConsentSignature(
                forPersonWithTitle: "Principal Investigator: \(investigator)",
                dateFormatString: nil,
                identifier: "investigatorSignature"
            )
            document.addSignature(investigatorSignature)
        }

        return document
    }

    private func createVisualConsentSteps() throws -> [ORKStep] {
        var steps: [ORKStep] = []

        // Visual step for data collection
        let dataStep = ORKInstructionStep(identifier: "consentData")
        dataStep.title = "Data Collection"
        dataStep.text = "We will collect survey responses and biological samples to advance scientific research."
        dataStep.image = UIImage(systemName: "doc.text.fill")
        steps.append(dataStep)

        // Visual step for privacy
        let privacyStep = ORKInstructionStep(identifier: "consentPrivacy")
        privacyStep.title = "Your Privacy Matters"
        privacyStep.text = "Your data is encrypted, confidential, and protected by strict privacy policies."
        privacyStep.image = UIImage(systemName: "lock.fill")
        steps.append(privacyStep)

        // Visual step for participation
        let participationStep = ORKInstructionStep(identifier: "consentParticipation")
        participationStep.title = "Voluntary Participation"
        participationStep.text = "Your participation is completely voluntary. You can withdraw at any time without penalty."
        participationStep.image = UIImage(systemName: "checkmark.circle.fill")
        steps.append(participationStep)

        return steps
    }

    private func createOverviewContent() -> String {
        var content = "Study Title: \(studyTitle)\n\n"
        content += studyDescription + "\n\n"

        if let investigator = principalInvestigator {
            content += "Principal Investigator: \(investigator)\n"
        }

        if let institution = institution {
            content += "Institution: \(institution)\n"
        }

        if let email = contactEmail {
            content += "Contact Email: \(email)\n"
        }

        if let phone = contactPhone {
            content += "Contact Phone: \(phone)\n"
        }

        return content
    }
}

// MARK: - Error Types
enum ConsentTaskError: LocalizedError {
    case documentCreationFailed
    case invalidSignature

    var errorDescription: String? {
        switch self {
        case .documentCreationFailed:
            return "Failed to create consent document"
        case .invalidSignature:
            return "Invalid consent signature"
        }
    }
}
