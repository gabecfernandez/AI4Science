import Foundation
import ResearchKit

/// Task for assessing data quality
struct QualityAssessmentTask: Sendable {
    // MARK: - Properties
    let identifier = "qualityAssessmentTask"
    let title = "Data Quality Assessment"
    let dataType: String

    // MARK: - Initialization
    init(dataType: String = "general") {
        self.dataType = dataType
    }

    // MARK: - Methods

    /// Build the quality assessment task
    func buildTask() throws -> ORKTask {
        var steps: [ORKStep] = []

        // Welcome step
        let welcomeStep = InstructionStepFactory.createInstructionStep(
            identifier: "quality_welcome",
            title: "Data Quality Assessment",
            text: "Please evaluate the quality of your data before submission. Your honest assessment helps us maintain research integrity."
        )
        steps.append(welcomeStep)

        // Completeness assessment
        let completenessStep = ORKQuestionStep(
            identifier: "dataCompleteness",
            title: "Data Completeness",
            answer: ORKAnswerFormat.scale(
                withMaximumValue: 5,
                minimumValue: 1,
                defaultValue: 3,
                step: 1,
                vertical: false,
                maximumValueDescription: "100% Complete",
                minimumValueDescription: "Significantly Incomplete"
            )
        )
        completenessStep.text = "How complete is your data? (All required fields filled, no missing values)"
        steps.append(completenessStep)

        // Accuracy assessment
        let accuracyStep = ORKQuestionStep(
            identifier: "dataAccuracy",
            title: "Data Accuracy",
            answer: ORKAnswerFormat.scale(
                withMaximumValue: 5,
                minimumValue: 1,
                defaultValue: 3,
                step: 1,
                vertical: false,
                maximumValueDescription: "Very Confident",
                minimumValueDescription: "Not Confident"
            )
        )
        accuracyStep.text = "How confident are you in the accuracy of your data?"
        steps.append(accuracyStep)

        // Consistency assessment
        let consistencyStep = ORKQuestionStep(
            identifier: "dataConsistency",
            title: "Data Consistency",
            answer: ORKAnswerFormat.scale(
                withMaximumValue: 5,
                minimumValue: 1,
                defaultValue: 3,
                step: 1,
                vertical: false,
                maximumValueDescription: "Very Consistent",
                minimumValueDescription: "Inconsistent"
            )
        )
        consistencyStep.text = "Are the values consistent across your data?"
        steps.append(consistencyStep)

        // Issues identification
        let issuesStep = ORKQuestionStep(
            identifier: "qualityIssues",
            title: "Issues Encountered",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .multipleChoice,
                textChoices: [
                    ORKTextChoice(text: "Missing Data", value: "missing"),
                    ORKTextChoice(text: "Equipment Malfunction", value: "equipment"),
                    ORKTextChoice(text: "Environmental Interference", value: "environmental"),
                    ORKTextChoice(text: "User Error", value: "userError"),
                    ORKTextChoice(text: "Data Inconsistencies", value: "inconsistency"),
                    ORKTextChoice(text: "Calibration Issues", value: "calibration"),
                    ORKTextChoice(text: "No Issues", value: "none")
                ]
            )
        )
        issuesStep.text = "Were any of these issues encountered during data collection?"
        steps.append(issuesStep)

        // Issue severity
        let severityStep = ORKQuestionStep(
            identifier: "issueSeverity",
            title: "Issue Severity",
            answer: ORKAnswerFormat.scale(
                withMaximumValue: 5,
                minimumValue: 1,
                defaultValue: 3,
                step: 1,
                vertical: false,
                maximumValueDescription: "Critical",
                minimumValueDescription: "Minor"
            )
        )
        severityStep.text = "How severe were the issues you encountered?"
        steps.append(severityStep)

        // Data usability
        let usabilityStep = ORKQuestionStep(
            identifier: "dataUsability",
            title: "Data Usability",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .singleChoice,
                textChoices: [
                    ORKTextChoice(text: "Ready for Analysis", value: "ready"),
                    ORKTextChoice(text: "Requires Minor Corrections", value: "minor"),
                    ORKTextChoice(text: "Requires Significant Corrections", value: "significant"),
                    ORKTextChoice(text: "Not Suitable for Analysis", value: "unsuitable")
                ]
            )
        )
        usabilityStep.text = "What is the current usability status of your data?"
        steps.append(usabilityStep)

        // Type-specific quality checks
        let typeSpecificStep = createTypeSpecificQualityStep()
        steps.append(typeSpecificStep)

        // Corrections needed
        let correctionsStep = ORKQuestionStep(
            identifier: "correctionsNeeded",
            title: "Corrections Needed",
            answer: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 500)
        )
        correctionsStep.text = "Describe any corrections that should be made to the data."
        correctionsStep.isOptional = true
        steps.append(correctionsStep)

        // Collection conditions
        let conditionsStep = ORKFormStep(identifier: "collectionConditions", title: "Collection Conditions", text: "Provide information about the conditions during data collection")
        conditionsStep.formItems = [
            ORKFormItem(
                identifier: "temperature",
                text: "Ambient Temperature (°C)",
                answerFormat: ORKAnswerFormat.decimalAnswerFormat(withUnit: "°C"),
                optional: true
            ),
            ORKFormItem(
                identifier: "humidity",
                text: "Humidity (%)",
                answerFormat: ORKAnswerFormat.integerAnswerFormat(withUnit: "%"),
                optional: true
            ),
            ORKFormItem(
                identifier: "lighting",
                text: "Lighting Conditions",
                answerFormat: ORKAnswerFormat.choiceAnswerFormat(
                    with: .singleChoice,
                    textChoices: [
                        ORKTextChoice(text: "Bright/Sunlight", value: "bright"),
                        ORKTextChoice(text: "Normal", value: "normal"),
                        ORKTextChoice(text: "Dim", value: "dim"),
                        ORKTextChoice(text: "Dark", value: "dark")
                    ]
                ),
                optional: true
            ),
            ORKFormItem(
                identifier: "disturbances",
                text: "Environmental Disturbances",
                answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 300),
                optional: true
            )
        ]
        steps.append(conditionsStep)

        // Validation checklist
        let checklistStep = ORKInstructionStep(identifier: "quality_checklist")
        checklistStep.title = "Quality Validation Checklist"
        checklistStep.text = """
            Before submission, verify:
            ✓ All required fields are completed
            ✓ Data values are within expected ranges
            ✓ Unit measurements are consistent
            ✓ Dates and times are properly formatted
            ✓ No obvious errors or typos
            ✓ Sample identification is clear
            ✓ Supporting documentation is attached
            """
        steps.append(checklistStep)

        // Certification
        let certificationStep = ORKQuestionStep(
            identifier: "qualityCertification",
            title: "Quality Certification",
            answer: ORKAnswerFormat.booleanAnswerFormat()
        )
        certificationStep.text = "I certify that the above information is accurate to the best of my knowledge and the data is ready for analysis."
        steps.append(certificationStep)

        // Additional comments
        let commentsStep = ORKQuestionStep(
            identifier: "qualityComments",
            title: "Additional Comments",
            answer: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 500)
        )
        commentsStep.text = "Any additional comments about data quality?"
        commentsStep.isOptional = true
        steps.append(commentsStep)

        // Review
        let reviewStep = ReviewStepFactory.createReviewStep(
            identifier: "quality_review",
            title: "Review Your Assessment",
            text: "Please review your quality assessment before submitting"
        )
        steps.append(reviewStep)

        // Completion
        let completionStep = CompletionStepFactory.createCompletionStep(
            identifier: "quality_completion",
            title: "Assessment Complete",
            text: "Thank you for completing the quality assessment. Your data is now ready for submission."
        )
        steps.append(completionStep)

        return ORKOrderedTask(identifier: identifier, steps: steps)
    }

    // MARK: - Private Methods

    private func createTypeSpecificQualityStep() -> ORKStep {
        let step = ORKQuestionStep(identifier: "typeSpecificQuality", title: "Type-Specific Quality", answer: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 300))

        switch dataType {
        case "biological":
            step.title = "Biological Sample Quality"
            step.text = "Describe the quality of your biological sample (clarity, contamination, integrity, etc.)"

        case "environmental":
            step.title = "Environmental Data Quality"
            step.text = "Were environmental measurements taken in controlled or natural conditions? Any unusual observations?"

        case "survey":
            step.title = "Survey Response Quality"
            step.text = "Were responses thoughtful and consistent? Any items you're uncertain about?"

        case "physical":
            step.title = "Physical Measurement Quality"
            step.text = "How confident are you in the precision and accuracy of your measurements?"

        default:
            step.title = "Data Quality Comments"
            step.text = "Please provide any comments about the quality of your data."
        }

        step.isOptional = true
        return step
    }
}

// MARK: - Models
struct QualityAssessmentResponse: Codable, Sendable {
    let completenessRating: Int
    let accuracyConfidence: Int
    let consistencyRating: Int
    let issuesEncountered: [String]
    let issueSeverity: Int
    let dataUsability: String
    let correctionsNeeded: String?
    let temperature: Double?
    let humidity: Int?
    let lightingConditions: String?
    let environmentalDisturbances: String?
    let qualityCertified: Bool
    let additionalComments: String?
}
