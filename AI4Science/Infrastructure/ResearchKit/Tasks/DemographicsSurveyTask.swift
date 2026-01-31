import Foundation
import ResearchKit

/// Task for collecting demographic information
struct DemographicsSurveyTask: Sendable {
    // MARK: - Properties
    let identifier = "demographicsSurvey"
    let title = "Demographic Information"

    // MARK: - Methods

    /// Build the demographics survey task
    func buildTask() throws -> ORKTask {
        var steps: [ORKStep] = []

        // Welcome step
        let welcomeStep = InstructionStepFactory.createInstructionStep(
            identifier: "demographics_welcome",
            title: "Demographic Information",
            text: "This information helps us understand the diversity of our research community. All responses are confidential."
        )
        steps.append(welcomeStep)

        // Personal information section
        let personalStep = ORKFormStep(identifier: "personalInfo", title: "Personal Information", text: "Please provide basic personal information")
        personalStep.formItems = [
            ORKFormItem(
                identifier: "ageRange",
                text: "Age Range",
                answerFormat: ORKAnswerFormat.choiceAnswerFormat(
                    with: .singleChoice,
                    textChoices: [
                        ORKTextChoice(text: "Under 18", value: "under18"),
                        ORKTextChoice(text: "18-25", value: "18-25"),
                        ORKTextChoice(text: "26-35", value: "26-35"),
                        ORKTextChoice(text: "36-45", value: "36-45"),
                        ORKTextChoice(text: "46-55", value: "46-55"),
                        ORKTextChoice(text: "56-65", value: "56-65"),
                        ORKTextChoice(text: "Over 65", value: "over65"),
                        ORKTextChoice(text: "Prefer not to answer", value: "pna")
                    ]
                ),
                optional: true
            ),
            ORKFormItem(
                identifier: "gender",
                text: "Gender Identity",
                answerFormat: ORKAnswerFormat.choiceAnswerFormat(
                    with: .singleChoice,
                    textChoices: [
                        ORKTextChoice(text: "Male", value: "male"),
                        ORKTextChoice(text: "Female", value: "female"),
                        ORKTextChoice(text: "Non-binary", value: "nonbinary"),
                        ORKTextChoice(text: "Genderqueer", value: "genderqueer"),
                        ORKTextChoice(text: "Prefer to self-describe", value: "selfDescribe"),
                        ORKTextChoice(text: "Prefer not to answer", value: "pna")
                    ]
                ),
                optional: true
            ),
            ORKFormItem(
                identifier: "genderSelfDescription",
                text: "How do you describe your gender?",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 100),
                optional: true
            )
        ]
        steps.append(personalStep)

        // Ethnicity and race
        let ethnicityStep = ORKQuestionStep(
            identifier: "ethnicity",
            title: "Ethnicity and Race",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .multipleChoice,
                textChoices: [
                    ORKTextChoice(text: "White/Caucasian", value: "white"),
                    ORKTextChoice(text: "Black/African American", value: "black"),
                    ORKTextChoice(text: "Hispanic/Latino", value: "hispanic"),
                    ORKTextChoice(text: "Asian/Pacific Islander", value: "asian"),
                    ORKTextChoice(text: "Native American/Alaska Native", value: "nativeAm"),
                    ORKTextChoice(text: "Middle Eastern/North African", value: "mena"),
                    ORKTextChoice(text: "Multiracial", value: "multiracial"),
                    ORKTextChoice(text: "Other", value: "other"),
                    ORKTextChoice(text: "Prefer not to answer", value: "pna")
                ]
            )
        )
        ethnicityStep.text = "Select all that apply"
        steps.append(ethnicityStep)

        // Education section
        let educationStep = ORKQuestionStep(
            identifier: "education",
            title: "Highest Education Level",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .singleChoice,
                textChoices: [
                    ORKTextChoice(text: "Less than High School", value: "lessHS"),
                    ORKTextChoice(text: "High School Diploma/GED", value: "hs"),
                    ORKTextChoice(text: "Some College", value: "someCollege"),
                    ORKTextChoice(text: "Associate's Degree", value: "associate"),
                    ORKTextChoice(text: "Bachelor's Degree", value: "bachelor"),
                    ORKTextChoice(text: "Master's Degree", value: "master"),
                    ORKTextChoice(text: "Doctoral Degree (PhD/MD/etc)", value: "doctoral"),
                    ORKTextChoice(text: "Prefer not to answer", value: "pna")
                ]
            )
        )
        steps.append(educationStep)

        // Field of study
        let fieldStep = ORKQuestionStep(
            identifier: "fieldOfStudy",
            title: "Primary Field of Study or Work",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .singleChoice,
                textChoices: [
                    ORKTextChoice(text: "Biology/Life Sciences", value: "biology"),
                    ORKTextChoice(text: "Chemistry", value: "chemistry"),
                    ORKTextChoice(text: "Physics", value: "physics"),
                    ORKTextChoice(text: "Environmental Science", value: "envScience"),
                    ORKTextChoice(text: "Computer Science/IT", value: "cs"),
                    ORKTextChoice(text: "Engineering", value: "engineering"),
                    ORKTextChoice(text: "Medicine/Healthcare", value: "medicine"),
                    ORKTextChoice(text: "Agriculture/Food Science", value: "agriculture"),
                    ORKTextChoice(text: "Mathematics/Statistics", value: "math"),
                    ORKTextChoice(text: "Social Sciences", value: "socialScience"),
                    ORKTextChoice(text: "Humanities", value: "humanities"),
                    ORKTextChoice(text: "Other", value: "other"),
                    ORKTextChoice(text: "Not applicable", value: "na"),
                    ORKTextChoice(text: "Prefer not to answer", value: "pna")
                ]
            )
        )
        steps.append(fieldStep)

        // Employment status
        let employmentStep = ORKQuestionStep(
            identifier: "employmentStatus",
            title: "Employment Status",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .singleChoice,
                textChoices: [
                    ORKTextChoice(text: "Employed Full-Time", value: "fullTime"),
                    ORKTextChoice(text: "Employed Part-Time", value: "partTime"),
                    ORKTextChoice(text: "Self-Employed", value: "selfEmployed"),
                    ORKTextChoice(text: "Student", value: "student"),
                    ORKTextChoice(text: "Retired", value: "retired"),
                    ORKTextChoice(text: "Unemployed", value: "unemployed"),
                    ORKTextChoice(text: "Not in Labor Force", value: "notLaborForce"),
                    ORKTextChoice(text: "Prefer not to answer", value: "pna")
                ]
            )
        )
        steps.append(employmentStep)

        // Geographic information
        let geoStep = ORKFormStep(identifier: "geographic", title: "Geographic Information", text: "Where are you located?")
        geoStep.formItems = [
            ORKFormItem(
                identifier: "country",
                text: "Country",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 50),
                optional: true
            ),
            ORKFormItem(
                identifier: "state",
                text: "State/Province",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 50),
                optional: true
            ),
            ORKFormItem(
                identifier: "urbanRural",
                text: "Area Type",
                answerFormat: ORKAnswerFormat.choiceAnswerFormat(
                    with: .singleChoice,
                    textChoices: [
                        ORKTextChoice(text: "Urban", value: "urban"),
                        ORKTextChoice(text: "Suburban", value: "suburban"),
                        ORKTextChoice(text: "Rural", value: "rural"),
                        ORKTextChoice(text: "Prefer not to answer", value: "pna")
                    ]
                ),
                optional: true
            )
        ]
        steps.append(geoStep)

        // Languages
        let languageStep = ORKQuestionStep(
            identifier: "languages",
            title: "Primary Language",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .singleChoice,
                textChoices: [
                    ORKTextChoice(text: "English", value: "english"),
                    ORKTextChoice(text: "Spanish", value: "spanish"),
                    ORKTextChoice(text: "Chinese", value: "chinese"),
                    ORKTextChoice(text: "French", value: "french"),
                    ORKTextChoice(text: "German", value: "german"),
                    ORKTextChoice(text: "Japanese", value: "japanese"),
                    ORKTextChoice(text: "Other", value: "other")
                ]
            )
        )
        steps.append(languageStep)

        // Accessibility needs
        let accessibilityStep = ORKQuestionStep(
            identifier: "accessibility",
            title: "Accessibility Needs",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .multipleChoice,
                textChoices: [
                    ORKTextChoice(text: "Visual Impairment Assistance", value: "visual"),
                    ORKTextChoice(text: "Hearing Impairment Assistance", value: "hearing"),
                    ORKTextChoice(text: "Mobility Assistance", value: "mobility"),
                    ORKTextChoice(text: "Cognitive Assistance", value: "cognitive"),
                    ORKTextChoice(text: "Other Accommodations", value: "other"),
                    ORKTextChoice(text: "No Additional Needs", value: "none")
                ]
            )
        )
        accessibilityStep.text = "Do you require any accessibility accommodations? (Select all that apply)"
        steps.append(accessibilityStep)

        // Household information
        let householdStep = ORKFormStep(identifier: "household", title: "Household Information", text: "Please provide basic household information")
        householdStep.formItems = [
            ORKFormItem(
                identifier: "householdSize",
                text: "Household Size",
                answerFormat: ORKAnswerFormat.integerAnswerFormat(withUnit: "people"),
                optional: true
            ),
            ORKFormItem(
                identifier: "dependents",
                text: "Number of Dependents (children/dependents)",
                answerFormat: ORKAnswerFormat.integerAnswerFormat(withUnit: ""),
                optional: true
            ),
            ORKFormItem(
                identifier: "incomeRange",
                text: "Annual Household Income Range",
                answerFormat: ORKAnswerFormat.choiceAnswerFormat(
                    with: .singleChoice,
                    textChoices: [
                        ORKTextChoice(text: "Less than $25,000", value: "under25"),
                        ORKTextChoice(text: "$25,000 - $50,000", value: "25-50"),
                        ORKTextChoice(text: "$50,000 - $75,000", value: "50-75"),
                        ORKTextChoice(text: "$75,000 - $100,000", value: "75-100"),
                        ORKTextChoice(text: "$100,000 - $150,000", value: "100-150"),
                        ORKTextChoice(text: "Over $150,000", value: "over150"),
                        ORKTextChoice(text: "Prefer not to answer", value: "pna")
                    ]
                ),
                optional: true
            )
        ]
        steps.append(householdStep)

        // Additional demographics
        let additionalStep = ORKQuestionStep(
            identifier: "additionalDemographics",
            title: "Additional Information",
            answer: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 300)
        )
        additionalStep.text = "Is there any other demographic information you'd like to share?"
        additionalStep.isOptional = true
        steps.append(additionalStep)

        // Privacy assurance
        let privacyStep = ORKInstructionStep(identifier: "demographics_privacy")
        privacyStep.title = "Privacy Notice"
        privacyStep.text = """
            Your demographic information is:
            - Collected for research purposes only
            - Stored separately from identifiable information
            - Protected by encrypted databases
            - Used only in aggregated statistical analysis
            - Never shared with third parties without consent
            """
        steps.append(privacyStep)

        // Review
        let reviewStep = ReviewStepFactory.createReviewStep(
            identifier: "demographics_review",
            title: "Review Your Information",
            text: "Please review your demographic information before completing"
        )
        steps.append(reviewStep)

        // Completion
        let completionStep = CompletionStepFactory.createCompletionStep(
            identifier: "demographics_completion",
            title: "Survey Complete",
            text: "Thank you for providing this information. It helps us understand our research community."
        )
        steps.append(completionStep)

        return ORKOrderedTask(identifier: identifier, steps: steps)
    }
}

// MARK: - Models
struct DemographicsResponse: Codable, Sendable {
    let ageRange: String?
    let gender: String?
    let genderSelfDescription: String?
    let ethnicity: [String]
    let education: String?
    let fieldOfStudy: String?
    let employmentStatus: String?
    let country: String?
    let state: String?
    let urbanRural: String?
    let primaryLanguage: String?
    let accessibilityNeeds: [String]
    let householdSize: Int?
    let dependents: Int?
    let incomeRange: String?
    let additionalInfo: String?
}
