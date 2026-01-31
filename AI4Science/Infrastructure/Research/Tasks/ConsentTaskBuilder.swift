import ResearchKit
import Foundation

/// Builds informed consent document tasks
final class ConsentTaskBuilder: TaskBuilder {
    // MARK: - Consent Task Creation

    static func buildTask(
        withID identifier: String,
        configuration: TaskConfiguration
    ) -> ORKTask? {
        let documentBuilder = ConsentDocumentBuilder()
        let consentDocument = ORKConsentDocument()

        consentDocument.title = configuration.title
        consentDocument.signaturePageTitle = "Consent"
        consentDocument.signaturePageContent = configuration.description

        // Add consent sections
        var sections: [ORKConsentSection] = []

        for stepConfig in configuration.steps {
            if let section = buildConsentSection(from: stepConfig) {
                sections.append(section)
            }
        }

        consentDocument.sections = sections

        // Create signature required
        let nameSignature = ORKConsentSignature(
            forPersonWithName: "Participant",
            forPersonWithTitle: nil
        )
        consentDocument.addSignature(nameSignature)

        let reviewStep = ORKConsentReviewStep(
            identifier: "\(identifier)_review",
            with: consentDocument
        )
        reviewStep.text = "Please review and sign the informed consent document"
        reviewStep.reasonForConsent = "We need your consent to proceed with this research study"

        let completionStep = createCompletionStep(
            identifier: "\(identifier)_completion",
            title: "Consent Provided",
            text: "Thank you for agreeing to participate in this research study"
        )

        return ORKOrderedTask(identifier: identifier, steps: [reviewStep, completionStep])
    }

    // MARK: - Consent Section Creation

    static func buildConsentSection(
        type: ORKConsentSectionType,
        title: String,
        content: String,
        image: UIImage? = nil,
        htmlContent: String? = nil,
        animation: ORKConsentSectionAnimation = .none
    ) -> ORKConsentSection {
        let section = ORKConsentSection(type: type)
        section.title = title
        section.content = content
        section.image = image
        section.htmlContent = htmlContent
        section.animation = animation
        return section
    }

    // MARK: - Common Consent Sections

    static func buildOverviewSection(
        title: String = "Overview",
        content: String
    ) -> ORKConsentSection {
        buildConsentSection(
            type: .overview,
            title: title,
            content: content
        )
    }

    static func buildDataGatheringSection(
        title: String = "Data Gathering",
        content: String
    ) -> ORKConsentSection {
        buildConsentSection(
            type: .dataGathering,
            title: title,
            content: content
        )
    }

    static func buildPrivacySection(
        title: String = "Privacy & Confidentiality",
        content: String
    ) -> ORKConsentSection {
        buildConsentSection(
            type: .privacy,
            title: title,
            content: content
        )
    }

    static func buildDataUseSection(
        title: String = "Data Use",
        content: String
    ) -> ORKConsentSection {
        buildConsentSection(
            type: .dataUse,
            title: title,
            content: content
        )
    }

    static func buildTimeCommitmentSection(
        title: String = "Time Commitment",
        content: String
    ) -> ORKConsentSection {
        buildConsentSection(
            type: .timeCommitment,
            title: title,
            content: content
        )
    }

    static func buildStudySurveySection(
        title: String = "Study Survey",
        content: String
    ) -> ORKConsentSection {
        buildConsentSection(
            type: .studySurvey,
            title: title,
            content: content
        )
    }

    static func buildStudyTasks(
        title: String = "Study Tasks",
        content: String
    ) -> ORKConsentSection {
        buildConsentSection(
            type: .studyTasks,
            title: title,
            content: content
        )
    }

    static func buildWithdrawalSection(
        title: String = "Withdrawal",
        content: String
    ) -> ORKConsentSection {
        buildConsentSection(
            type: .withdrawal,
            title: title,
            content: content
        )
    }

    static func buildOnlyInDocumentSection(
        title: String,
        content: String
    ) -> ORKConsentSection {
        buildConsentSection(
            type: .onlyInDocument,
            title: title,
            content: content
        )
    }

    static func buildCustomSection(
        title: String,
        content: String
    ) -> ORKConsentSection {
        buildConsentSection(
            type: .custom,
            title: title,
            content: content
        )
    }

    // MARK: - Multi-Language Consent

    static func buildMultiLanguageConsentTask(
        identifier: String,
        consentDocuments: [String: ORKConsentDocument],
        languages: [String]
    ) -> ORKTask? {
        // Create step for each language
        var steps: [ORKStep] = []

        for language in languages {
            guard let document = consentDocuments[language] else { continue }

            let reviewStep = ORKConsentReviewStep(
                identifier: "\(identifier)_\(language)",
                with: document
            )
            steps.append(reviewStep)
        }

        steps.append(createCompletionStep())

        return ORKOrderedTask(identifier: identifier, steps: steps)
    }

    // MARK: - Electronic Signature

    static func addElectronicSignature(
        to document: ORKConsentDocument,
        requiresNameSignature: Bool = true,
        requiresDateSignature: Bool = true
    ) {
        if requiresNameSignature {
            let nameSignature = ORKConsentSignature(
                forPersonWithName: "Participant",
                forPersonWithTitle: nil
            )
            document.addSignature(nameSignature)
        }

        if requiresDateSignature {
            let investigatorSignature = ORKConsentSignature(
                forPersonWithName: "Investigator",
                forPersonWithTitle: "Principal Investigator"
            )
            document.addSignature(investigatorSignature)
        }
    }

    // MARK: - Consent Animations

    static func createAnimatedConsentSection(
        type: ORKConsentSectionType,
        title: String,
        content: String,
        animation: ORKConsentSectionAnimation
    ) -> ORKConsentSection {
        let section = buildConsentSection(
            type: type,
            title: title,
            content: content
        )
        section.animation = animation
        return section
    }

    // MARK: - Visual Consent

    static func createVisualConsentSection(
        with image: UIImage,
        title: String,
        content: String
    ) -> ORKConsentSection {
        buildConsentSection(
            type: .onlyInDocument,
            title: title,
            content: content,
            image: image
        )
    }

    // MARK: - HTML-based Consent

    static func createHTMLConsentSection(
        title: String,
        htmlContent: String
    ) -> ORKConsentSection {
        let section = ORKConsentSection(type: .custom)
        section.title = title
        section.htmlContent = htmlContent
        return section
    }

    // MARK: - Private Helpers

    private static func buildConsentSection(from configuration: StepConfiguration) -> ORKConsentSection? {
        let section = ORKConsentSection(type: .custom)
        section.title = configuration.title ?? ""
        section.content = configuration.text ?? ""
        return section
    }
}

// MARK: - Consent Document Extensions

extension ORKConsentDocument {
    /// Add a custom privacy section
    func addPrivacySection(title: String, content: String) {
        let section = ORKConsentSection(type: .privacy)
        section.title = title
        section.content = content

        var sections = self.sections ?? []
        sections.append(section)
        self.sections = sections
    }

    /// Add data handling section
    func addDataHandlingSection(title: String, content: String) {
        let section = ORKConsentSection(type: .dataUse)
        section.title = title
        section.content = content

        var sections = self.sections ?? []
        sections.append(section)
        self.sections = sections
    }

    /// Prepare for offline signing
    func prepareForOfflineSigning() {
        signaturePageTitle = "Research Study Consent Form"
        signaturePageContent = "I have read and understood the information in this consent form and agree to participate in this research study."
    }
}
