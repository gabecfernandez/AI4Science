import Foundation
import ResearchKit

/// Factory for creating form-based steps
enum FormStepFactory {
    // MARK: - Public Methods

    /// Create a basic form step
    static func createFormStep(
        identifier: String,
        title: String,
        text: String? = nil,
        formItems: [ORKFormItem]
    ) -> ORKFormStep {
        let step = ORKFormStep(identifier: identifier, title: title, text: text)
        step.formItems = formItems
        return step
    }

    /// Create a contact information form
    static func createContactForm(identifier: String) -> ORKFormStep {
        let step = ORKFormStep(identifier: identifier, title: "Contact Information", text: "Please provide your contact information")

        let formItems = [
            ORKFormItem(
                identifier: "firstName",
                text: "First Name",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 100),
                optional: false
            ),
            ORKFormItem(
                identifier: "lastName",
                text: "Last Name",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 100),
                optional: false
            ),
            ORKFormItem(
                identifier: "email",
                text: "Email Address",
                answerFormat: ORKAnswerFormat.emailAnswerFormat(),
                optional: false
            ),
            ORKFormItem(
                identifier: "phone",
                text: "Phone Number",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 20),
                optional: true
            ),
            ORKFormItem(
                identifier: "institution",
                text: "Institution/Organization",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 100),
                optional: true
            )
        ]

        step.formItems = formItems
        return step
    }

    /// Create a location information form
    static func createLocationForm(identifier: String) -> ORKFormStep {
        let step = ORKFormStep(identifier: identifier, title: "Location Information", text: "Where are you located?")

        let formItems = [
            ORKFormItem(
                identifier: "address",
                text: "Street Address",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 100),
                optional: true
            ),
            ORKFormItem(
                identifier: "city",
                text: "City",
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
                identifier: "zipCode",
                text: "Zip/Postal Code",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 20),
                optional: true
            ),
            ORKFormItem(
                identifier: "country",
                text: "Country",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 50),
                optional: true
            )
        ]

        step.formItems = formItems
        return step
    }

    /// Create a health history form
    static func createHealthHistoryForm(identifier: String) -> ORKFormStep {
        let step = ORKFormStep(identifier: identifier, title: "Health History", text: "Please provide relevant health information")

        let formItems = [
            ORKFormItem(
                identifier: "knownConditions",
                text: "Known Medical Conditions",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 300),
                optional: true
            ),
            ORKFormItem(
                identifier: "medications",
                text: "Current Medications",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 300),
                optional: true
            ),
            ORKFormItem(
                identifier: "allergies",
                text: "Known Allergies",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 300),
                optional: true
            ),
            ORKFormItem(
                identifier: "surgeries",
                text: "Previous Surgeries",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 300),
                optional: true
            ),
            ORKFormItem(
                identifier: "familyHistory",
                text: "Relevant Family Medical History",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 300),
                optional: true
            )
        ]

        step.formItems = formItems
        return step
    }

    /// Create a research experience form
    static func createResearchExperienceForm(identifier: String) -> ORKFormStep {
        let step = ORKFormStep(identifier: identifier, title: "Research Experience", text: "Tell us about your research background")

        let formItems = [
            ORKFormItem(
                identifier: "yearsExperience",
                text: "Years of Research Experience",
                answerFormat: ORKAnswerFormat.integerAnswerFormat(withUnit: "years"),
                optional: true
            ),
            ORKFormItem(
                identifier: "researchAreas",
                text: "Research Areas of Interest",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 300),
                optional: true
            ),
            ORKFormItem(
                identifier: "publications",
                text: "Number of Publications",
                answerFormat: ORKAnswerFormat.integerAnswerFormat(withUnit: ""),
                optional: true
            ),
            ORKFormItem(
                identifier: "methodologies",
                text: "Research Methodologies Experience",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 300),
                optional: true
            )
        ]

        step.formItems = formItems
        return step
    }

    /// Create a sample information form
    static func createSampleInformationForm(identifier: String) -> ORKFormStep {
        let step = ORKFormStep(identifier: identifier, title: "Sample Information", text: "Provide details about your sample")

        let formItems = [
            ORKFormItem(
                identifier: "sampleID",
                text: "Sample ID",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 50),
                optional: false
            ),
            ORKFormItem(
                identifier: "collectionDate",
                text: "Collection Date",
                answerFormat: ORKDateAnswerFormat(style: .date),
                optional: false
            ),
            ORKFormItem(
                identifier: "collectionTime",
                text: "Collection Time",
                answerFormat: ORKDateAnswerFormat(style: .time),
                optional: true
            ),
            ORKFormItem(
                identifier: "quantity",
                text: "Quantity",
                answerFormat: ORKAnswerFormat.decimalAnswerFormat(withUnit: "mL"),
                optional: true
            ),
            ORKFormItem(
                identifier: "storageConditions",
                text: "Storage Conditions",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 100),
                optional: true
            ),
            ORKFormItem(
                identifier: "notes",
                text: "Additional Notes",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 500),
                optional: true
            )
        ]

        step.formItems = formItems
        return step
    }

    /// Create a measurements form
    static func createMeasurementsForm(identifier: String) -> ORKFormStep {
        let step = ORKFormStep(identifier: identifier, title: "Measurements", text: "Record your measurements")

        let formItems = [
            ORKFormItem(
                identifier: "temperature",
                text: "Temperature",
                answerFormat: ORKAnswerFormat.decimalAnswerFormat(withUnit: "°C"),
                optional: true
            ),
            ORKFormItem(
                identifier: "humidity",
                text: "Humidity",
                answerFormat: ORKAnswerFormat.decimalAnswerFormat(withUnit: "%"),
                optional: true
            ),
            ORKFormItem(
                identifier: "pressure",
                text: "Pressure",
                answerFormat: ORKAnswerFormat.decimalAnswerFormat(withUnit: "kPa"),
                optional: true
            ),
            ORKFormItem(
                identifier: "pH",
                text: "pH Value",
                answerFormat: ORKAnswerFormat.decimalAnswerFormat(withUnit: ""),
                optional: true
            ),
            ORKFormItem(
                identifier: "otherMeasurements",
                text: "Other Measurements",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 300),
                optional: true
            )
        ]

        step.formItems = formItems
        return step
    }

    /// Create a protocol compliance form
    static func createProtocolComplianceForm(identifier: String) -> ORKFormStep {
        let step = ORKFormStep(identifier: identifier, title: "Protocol Compliance", text: "Confirm your adherence to study protocol")

        let formItems = [
            ORKFormItem(
                identifier: "protocolFollowed",
                text: "I followed the study protocol exactly",
                answerFormat: ORKAnswerFormat.booleanAnswerFormat(),
                optional: false
            ),
            ORKFormItem(
                identifier: "deviations",
                text: "If no, describe any deviations",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 500),
                optional: true
            ),
            ORKFormItem(
                identifier: "safetyIssues",
                text: "Any safety issues encountered",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 500),
                optional: true
            ),
            ORKFormItem(
                identifier: "equipmentUsed",
                text: "Equipment/materials used as specified",
                answerFormat: ORKAnswerFormat.booleanAnswerFormat(),
                optional: false
            ),
            ORKFormItem(
                identifier: "dataRecorded",
                text: "All required data recorded",
                answerFormat: ORKAnswerFormat.booleanAnswerFormat(),
                optional: false
            )
        ]

        step.formItems = formItems
        return step
    }

    /// Create a feedback form
    static func createFeedbackForm(identifier: String) -> ORKFormStep {
        let step = ORKFormStep(identifier: identifier, title: "Feedback", text: "Help us improve your experience")

        let formItems = [
            ORKFormItem(
                identifier: "overallExperience",
                text: "Rate your overall experience",
                answerFormat: ORKAnswerFormat.scale(
                    withMaximumValue: 5,
                    minimumValue: 1,
                    defaultValue: 3,
                    step: 1,
                    vertical: false,
                    maximumValueDescription: "Excellent",
                    minimumValueDescription: "Poor"
                ),
                optional: false
            ),
            ORKFormItem(
                identifier: "easeOfUse",
                text: "Ease of use",
                answerFormat: ORKAnswerFormat.scale(
                    withMaximumValue: 5,
                    minimumValue: 1,
                    defaultValue: 3,
                    step: 1,
                    vertical: false,
                    maximumValueDescription: "Very Easy",
                    minimumValueDescription: "Very Difficult"
                ),
                optional: false
            ),
            ORKFormItem(
                identifier: "suggestions",
                text: "Suggestions for improvement",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 500),
                optional: true
            ),
            ORKFormItem(
                identifier: "additionalComments",
                text: "Additional comments",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 500),
                optional: true
            )
        ]

        step.formItems = formItems
        return step
    }
}
