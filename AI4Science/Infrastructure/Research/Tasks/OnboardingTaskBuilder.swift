import ResearchKit
import Foundation

/// Builds onboarding and eligibility screening flows
final class OnboardingTaskBuilder: TaskBuilder {
    // MARK: - Onboarding Task Creation

    static func buildTask(
        withID identifier: String,
        configuration: TaskConfiguration
    ) -> ORKTask? {
        var steps: [ORKStep] = []

        // Welcome step
        steps.append(createWelcomeStep(identifier: "\(identifier)_welcome"))

        // Add onboarding steps from configuration
        for stepConfig in configuration.steps {
            if let onboardingStep = buildOnboardingStep(from: stepConfig) {
                steps.append(onboardingStep)
            }
        }

        // Completion step
        steps.append(createCompletionStep(identifier: "\(identifier)_completion"))

        return ORKOrderedTask(identifier: identifier, steps: steps)
    }

    // MARK: - Onboarding Steps

    static func createWelcomeStep(identifier: String = "welcomeStep") -> ORKInstructionStep {
        let step = createInstructionStep(
            identifier: identifier,
            title: "Welcome to the Study",
            text: "Thank you for your interest in participating in this research study"
        )
        return step
    }

    static func createStudyOverviewStep(
        identifier: String = "overviewStep",
        title: String = "Study Overview",
        description: String,
        duration: String
    ) -> ORKInstructionStep {
        let step = createInstructionStep(
            identifier: identifier,
            title: title,
            text: description,
            detailedText: "Estimated time: \(duration)"
        )
        return step
    }

    static func createAboutYouStep(identifier: String = "aboutYouStep") -> ORKFormStep {
        let nameItem = ORKFormItem(
            identifier: "firstName",
            text: "First Name",
            answerFormat: ORKTextAnswerFormat(maximumLength: 50)
        )

        let ageItem = ORKFormItem(
            identifier: "age",
            text: "Age",
            answerFormat: ORKNumericAnswerFormat(style: .integer)
        )

        let genderItem = ORKFormItem(
            identifier: "gender",
            text: "Gender",
            answerFormat: ORKValuePickerAnswerFormat(textChoices: ["Male", "Female", "Other", "Prefer not to say"])
        )

        let step = SurveyTaskBuilder.buildFormStep(
            identifier: identifier,
            title: "About You",
            formItems: [nameItem, ageItem, genderItem]
        )
        return step
    }

    static func createDevicePermissionsStep(
        identifier: String = "permissionsStep"
    ) -> ORKInstructionStep {
        let step = createInstructionStep(
            identifier: identifier,
            title: "Device Permissions",
            text: "This study requires access to your camera and motion sensors. You will be prompted to grant these permissions.",
            detailedText: "Camera access is needed for image capture tasks. Motion sensors are used for activity tracking."
        )
        return step
    }

    static func createHealthKitPermissionsStep(
        identifier: String = "healthKitPermissionsStep"
    ) -> ORKInstructionStep {
        let step = createInstructionStep(
            identifier: identifier,
            title: "Health Data Access",
            text: "This study may request access to your health data from the Health app.",
            detailedText: "You can review which data types we access and modify these permissions at any time."
        )
        return step
    }

    static func createNotificationPermissionsStep(
        identifier: String = "notificationPermissionsStep"
    ) -> ORKInstructionStep {
        let step = createInstructionStep(
            identifier: identifier,
            title: "Notifications",
            text: "Allow notifications to receive reminders about study tasks.",
            detailedText: "You can disable notifications in your device settings at any time."
        )
        return step
    }

    static func createEligibilityScreeningStep(
        identifier: String = "eligibilityStep",
        criteria: [String]
    ) -> ORKFormStep {
        var formItems: [ORKFormItem] = []

        for (index, criterion) in criteria.enumerated() {
            let item = ORKFormItem(
                identifier: "criterion_\(index)",
                text: criterion,
                answerFormat: ORKBooleanAnswerFormat()
            )
            formItems.append(item)
        }

        let step = SurveyTaskBuilder.buildFormStep(
            identifier: identifier,
            title: "Eligibility Screening",
            formItems: formItems
        )
        return step
    }

    static func createDemographicsStep(
        identifier: String = "demographicsStep"
    ) -> ORKFormStep {
        let ageItem = ORKFormItem(
            identifier: "age",
            text: "Age",
            answerFormat: ORKNumericAnswerFormat(style: .integer)
        )

        let genderItem = ORKFormItem(
            identifier: "gender",
            text: "Gender",
            answerFormat: ORKValuePickerAnswerFormat(
                textChoices: ["Male", "Female", "Non-binary", "Other", "Prefer not to say"]
            )
        )

        let ethnicityItem = ORKFormItem(
            identifier: "ethnicity",
            text: "Ethnicity",
            answerFormat: ORKValuePickerAnswerFormat(
                textChoices: ["White", "Black/African American", "Hispanic/Latino", "Asian", "Native American", "Other", "Prefer not to say"]
            )
        )

        let educationItem = ORKFormItem(
            identifier: "education",
            text: "Education Level",
            answerFormat: ORKValuePickerAnswerFormat(
                textChoices: ["High School", "Some College", "Bachelor's", "Master's", "Doctorate", "Other"]
            )
        )

        let step = SurveyTaskBuilder.buildFormStep(
            identifier: identifier,
            title: "Demographics",
            formItems: [ageItem, genderItem, ethnicityItem, educationItem]
        )
        return step
    }

    static func createExperienceStep(
        identifier: String = "experienceStep"
    ) -> ORKFormStep {
        let priorStudyItem = ORKFormItem(
            identifier: "priorStudy",
            text: "Have you participated in research studies before?",
            answerFormat: ORKBooleanAnswerFormat()
        )

        let techComfortItem = ORKFormItem(
            identifier: "techComfort",
            text: "Comfort level with mobile apps",
            answerFormat: ORKScaleAnswerFormat(
                maximumValue: 5,
                minimumValue: 1,
                defaultValue: 3,
                step: 1,
                vertical: false,
                maximumValueDescription: "Very Comfortable",
                minimumValueDescription: "Not Comfortable"
            )
        )

        let step = SurveyTaskBuilder.buildFormStep(
            identifier: identifier,
            title: "Experience",
            formItems: [priorStudyItem, techComfortItem]
        )
        return step
    }

    static func createTermsAndConditionsStep(
        identifier: String = "termsStep",
        htmlContent: String
    ) -> ORKInstructionStep {
        let step = createInstructionStep(
            identifier: identifier,
            title: "Terms and Conditions",
            text: "Please review our terms and conditions before proceeding"
        )
        return step
    }

    static func createDataSecurityStep(
        identifier: String = "securityStep"
    ) -> ORKInstructionStep {
        let step = createInstructionStep(
            identifier: identifier,
            title: "Data Security",
            text: "Your data is protected using encryption and secure protocols.",
            detailedText: "All information is stored securely and access is restricted to authorized researchers. Your privacy is our priority."
        )
        return step
    }

    static func createContactInformationStep(
        identifier: String = "contactStep"
    ) -> ORKFormStep {
        let emailItem = ORKFormItem(
            identifier: "email",
            text: "Email Address",
            answerFormat: ORKEmailAnswerFormat()
        )

        let phoneItem = ORKFormItem(
            identifier: "phone",
            text: "Phone Number (Optional)",
            answerFormat: ORKTextAnswerFormat(maximumLength: 20)
        )

        let step = SurveyTaskBuilder.buildFormStep(
            identifier: identifier,
            title: "Contact Information",
            formItems: [emailItem, phoneItem]
        )
        return step
    }

    static func createConfirmationStep(
        identifier: String = "confirmationStep"
    ) -> ORKInstructionStep {
        let step = createInstructionStep(
            identifier: identifier,
            title: "Ready to Begin",
            text: "You have successfully completed the onboarding process.",
            detailedText: "Your responses have been saved. You can now proceed to the study tasks."
        )
        return step
    }

    // MARK: - Complete Onboarding Flow

    static func buildCompleteOnboardingFlow(
        identifier: String,
        studyTitle: String,
        studyDescription: String
    ) -> ORKTask {
        var steps: [ORKStep] = []

        // Welcome
        steps.append(createWelcomeStep())

        // Study overview
        steps.append(createStudyOverviewStep(
            title: studyTitle,
            description: studyDescription,
            duration: "15-20 minutes"
        ))

        // About you
        steps.append(createAboutYouStep())

        // Eligibility screening
        steps.append(createEligibilityScreeningStep(
            criteria: [
                "I am 18 years or older",
                "I have a compatible smartphone",
                "I am willing to complete daily tasks"
            ]
        ))

        // Demographics
        steps.append(createDemographicsStep())

        // Prior experience
        steps.append(createExperienceStep())

        // Permissions
        steps.append(createDevicePermissionsStep())
        steps.append(createHealthKitPermissionsStep())
        steps.append(createNotificationPermissionsStep())

        // Data security
        steps.append(createDataSecurityStep())

        // Contact information
        steps.append(createContactInformationStep())

        // Confirmation
        steps.append(createConfirmationStep())

        return ORKOrderedTask(identifier: identifier, steps: steps)
    }

    // MARK: - Private Helpers

    private static func buildOnboardingStep(from configuration: StepConfiguration) -> ORKStep? {
        switch configuration.type {
        case .instruction:
            return createInstructionStep(
                identifier: configuration.identifier,
                title: configuration.title ?? "",
                text: configuration.text
            )

        case .form:
            return SurveyTaskBuilder.buildFormStep(
                identifier: configuration.identifier,
                title: configuration.title ?? "",
                formItems: []
            )

        default:
            return nil
        }
    }
}

// MARK: - Quick Start Onboarding

extension OnboardingTaskBuilder {
    static func buildMinimalOnboarding(identifier: String) -> ORKTask {
        var steps: [ORKStep] = []

        steps.append(createWelcomeStep())
        steps.append(createAboutYouStep())
        steps.append(createDevicePermissionsStep())
        steps.append(createConfirmationStep())

        return ORKOrderedTask(identifier: identifier, steps: steps)
    }

    static func buildDetailedOnboarding(identifier: String) -> ORKTask {
        buildCompleteOnboardingFlow(
            identifier: identifier,
            studyTitle: "Research Study",
            studyDescription: "Thank you for your interest in participating in our research"
        )
    }
}
