import Foundation
import ResearchKit

/// Configuration for consent documents and workflows
struct ConsentConfiguration: Sendable {
    let studyTitle: String
    let studyDescription: String
    let principalInvestigator: String?
    let institution: String?
    let contactEmail: String?
    let contactPhone: String?
    let sections: [ConsentSectionConfiguration]
    let requireSignature: Bool
    let consentVersionNumber: String

    // MARK: - Initialization
    init(
        studyTitle: String,
        studyDescription: String,
        principalInvestigator: String? = nil,
        institution: String? = nil,
        contactEmail: String? = nil,
        contactPhone: String? = nil,
        sections: [ConsentSectionConfiguration]? = nil,
        requireSignature: Bool = true,
        consentVersionNumber: String = "1.0"
    ) {
        self.studyTitle = studyTitle
        self.studyDescription = studyDescription
        self.principalInvestigator = principalInvestigator
        self.institution = institution
        self.contactEmail = contactEmail
        self.contactPhone = contactPhone
        self.sections = sections ?? ConsentConfiguration.defaultSections()
        self.requireSignature = requireSignature
        self.consentVersionNumber = consentVersionNumber
    }

    // MARK: - Static Methods

    static func defaultSections() -> [ConsentSectionConfiguration] {
        return [
            ConsentSectionConfiguration(
                type: .overview,
                title: "Study Overview",
                summary: "Learn about this study",
                content: "This study involves research to advance scientific knowledge."
            ),
            ConsentSectionConfiguration(
                type: .dataGathering,
                title: "Data Collection",
                summary: "What data will be collected",
                content: """
                    We will collect:
                    - Survey responses
                    - Research samples
                    - Demographic information
                    """
            ),
            ConsentSectionConfiguration(
                type: .privacy,
                title: "Privacy & Confidentiality",
                summary: "How your data is protected",
                content: """
                    Your data is:
                    - Encrypted and securely stored
                    - Protected by strict privacy policies
                    - Compliant with HIPAA and GDPR
                    """
            ),
            ConsentSectionConfiguration(
                type: .dataUse,
                title: "Data Use",
                summary: "How your data will be used",
                content: """
                    Your data will be used for:
                    - Scientific research and analysis
                    - Publication in peer-reviewed journals
                    - Educational purposes
                    """
            ),
            ConsentSectionConfiguration(
                type: .timeCommitment,
                title: "Time Commitment",
                summary: "How much time is required",
                content: "This study will require approximately 45-60 minutes of your time."
            ),
            ConsentSectionConfiguration(
                type: .benefits,
                title: "Benefits",
                summary: "Potential benefits of participation",
                content: """
                    Benefits may include:
                    - Contributing to scientific knowledge
                    - Receiving feedback on your data
                    """
            ),
            ConsentSectionConfiguration(
                type: .risks,
                title: "Risks",
                summary: "Potential risks and discomforts",
                content: """
                    Risks are minimal:
                    - Time spent completing surveys
                    - Possible mild discomfort during sample collection
                    """
            )
        ]
    }

    static func aiScience() -> ConsentConfiguration {
        return ConsentConfiguration(
            studyTitle: "AI4Science Research Study",
            studyDescription: "This study aims to advance scientific research through artificial intelligence and community participation.",
            principalInvestigator: "Dr. Science",
            institution: "University of Advanced Science",
            contactEmail: "research@ai4science.org",
            contactPhone: "+1 (555) 123-4567"
        )
    }

    static func minimal() -> ConsentConfiguration {
        return ConsentConfiguration(
            studyTitle: "Research Study",
            studyDescription: "A research study for scientific purposes.",
            sections: [
                ConsentSectionConfiguration(
                    type: .overview,
                    title: "Study Overview",
                    summary: "Learn about this study",
                    content: "This study involves research to advance scientific knowledge."
                )
            ]
        )
    }
}

// MARK: - Section Configuration
struct ConsentSectionConfiguration: Sendable {
    let type: ORKConsentSectionType
    let title: String
    let summary: String
    let content: String
    let image: String?

    init(
        type: ORKConsentSectionType,
        title: String,
        summary: String,
        content: String,
        image: String? = nil
    ) {
        self.type = type
        self.title = title
        self.summary = summary
        self.content = content
        self.image = image
    }
}

// MARK: - Builder Pattern
struct ConsentConfigurationBuilder {
    private var config: ConsentConfiguration

    init(studyTitle: String, studyDescription: String) {
        self.config = ConsentConfiguration(
            studyTitle: studyTitle,
            studyDescription: studyDescription
        )
    }

    mutating func setPrincipalInvestigator(_ name: String) -> Self {
        var newConfig = config
        newConfig = ConsentConfiguration(
            studyTitle: config.studyTitle,
            studyDescription: config.studyDescription,
            principalInvestigator: name,
            institution: config.institution,
            contactEmail: config.contactEmail,
            contactPhone: config.contactPhone,
            sections: config.sections,
            requireSignature: config.requireSignature,
            consentVersionNumber: config.consentVersionNumber
        )
        return self
    }

    mutating func setInstitution(_ name: String) -> Self {
        var newConfig = config
        newConfig = ConsentConfiguration(
            studyTitle: config.studyTitle,
            studyDescription: config.studyDescription,
            principalInvestigator: config.principalInvestigator,
            institution: name,
            contactEmail: config.contactEmail,
            contactPhone: config.contactPhone,
            sections: config.sections,
            requireSignature: config.requireSignature,
            consentVersionNumber: config.consentVersionNumber
        )
        return self
    }

    mutating func setContact(email: String, phone: String?) -> Self {
        var newConfig = config
        newConfig = ConsentConfiguration(
            studyTitle: config.studyTitle,
            studyDescription: config.studyDescription,
            principalInvestigator: config.principalInvestigator,
            institution: config.institution,
            contactEmail: email,
            contactPhone: phone,
            sections: config.sections,
            requireSignature: config.requireSignature,
            consentVersionNumber: config.consentVersionNumber
        )
        return self
    }

    mutating func addSection(_ section: ConsentSectionConfiguration) -> Self {
        var newConfig = config
        var sections = config.sections
        sections.append(section)
        newConfig = ConsentConfiguration(
            studyTitle: config.studyTitle,
            studyDescription: config.studyDescription,
            principalInvestigator: config.principalInvestigator,
            institution: config.institution,
            contactEmail: config.contactEmail,
            contactPhone: config.contactPhone,
            sections: sections,
            requireSignature: config.requireSignature,
            consentVersionNumber: config.consentVersionNumber
        )
        return self
    }

    mutating func setRequireSignature(_ require: Bool) -> Self {
        var newConfig = config
        newConfig = ConsentConfiguration(
            studyTitle: config.studyTitle,
            studyDescription: config.studyDescription,
            principalInvestigator: config.principalInvestigator,
            institution: config.institution,
            contactEmail: config.contactEmail,
            contactPhone: config.contactPhone,
            sections: config.sections,
            requireSignature: require,
            consentVersionNumber: config.consentVersionNumber
        )
        return self
    }

    func build() -> ConsentConfiguration {
        return config
    }
}

// MARK: - Predefined Configurations
extension ConsentConfiguration {
    static let biomedical = ConsentConfiguration(
        studyTitle: "Biomedical Research Study",
        studyDescription: "A biomedical research study investigating health outcomes.",
        sections: [
            ConsentSectionConfiguration(
                type: .overview,
                title: "Study Overview",
                summary: "Overview",
                content: "This biomedical research study aims to investigate health outcomes and treatment efficacy."
            ),
            ConsentSectionConfiguration(
                type: .risks,
                title: "Medical Risks",
                summary: "Potential medical risks",
                content: "Participation may involve standard medical procedures with minimal risks."
            )
        ]
    )

    static let environmental = ConsentConfiguration(
        studyTitle: "Environmental Research Study",
        studyDescription: "An environmental research study examining ecological systems.",
        sections: [
            ConsentSectionConfiguration(
                type: .overview,
                title: "Study Overview",
                summary: "Overview",
                content: "This environmental research study examines ecological systems and environmental factors."
            ),
            ConsentSectionConfiguration(
                type: .dataGathering,
                title: "Data Collection Methods",
                summary: "How we collect data",
                content: "Data will be collected through field observations and environmental measurements."
            )
        ]
    )

    static let behavioral = ConsentConfiguration(
        studyTitle: "Behavioral Research Study",
        studyDescription: "A behavioral research study investigating human behavior and cognition.",
        sections: [
            ConsentSectionConfiguration(
                type: .overview,
                title: "Study Overview",
                summary: "Overview",
                content: "This behavioral research study investigates human behavior and cognition."
            ),
            ConsentSectionConfiguration(
                type: .privacy,
                title: "Psychological Privacy",
                summary: "Privacy protections",
                content: "All psychological data is treated with utmost confidentiality."
            )
        ]
    )
}
