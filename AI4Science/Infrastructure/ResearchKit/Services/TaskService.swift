import Foundation
import ResearchKit

/// Service for managing active research tasks
actor TaskService {
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.ai4science.researchkit", category: "TaskService")

    // MARK: - Public Methods

    /// Create a sample collection task
    func createSampleCollectionTask() throws -> ORKTask {
        logger.info("Creating sample collection task")

        var steps: [ORKStep] = []

        // Instruction step
        let instructionStep = InstructionStepFactory.createInstructionStep(
            identifier: "sampleCollection_instruction",
            title: "Sample Collection",
            text: "Please follow the instructions to collect your sample"
        )
        steps.append(instructionStep)

        // Sample type selection
        let sampleTypeStep = ORKQuestionStep(
            identifier: "sampleType",
            title: "Sample Type",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .singleChoice,
                textChoices: [
                    ORKTextChoice(text: "Saliva", value: "saliva"),
                    ORKTextChoice(text: "Soil", value: "soil"),
                    ORKTextChoice(text: "Water", value: "water"),
                    ORKTextChoice(text: "Plant Material", value: "plant"),
                    ORKTextChoice(text: "Other", value: "other")
                ]
            )
        )
        steps.append(sampleTypeStep)

        // Collection instructions
        let collectionInstructionStep = InstructionStepFactory.createInstructionStep(
            identifier: "collection_detailed",
            title: "Collection Instructions",
            text: "Please collect approximately 5-10mL of your sample in the provided container. Label with date and time."
        )
        steps.append(collectionInstructionStep)

        // Sample details
        let sampleDetailsStep = ORKFormStep(identifier: "sampleDetails", title: "Sample Details", text: "Provide information about your sample")
        let collectionTimeFormat = ORKDateAnswerFormat(style: .dateAndTime)
        sampleDetailsStep.formItems = [
            ORKFormItem(identifier: "collectionTime", text: "Collection Time", answerFormat: collectionTimeFormat, optional: false),
            ORKFormItem(identifier: "collectionLocation", text: "Collection Location", answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 100), optional: false),
            ORKFormItem(identifier: "notes", text: "Notes", answerFormat: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 500), optional: true)
        ]
        steps.append(sampleDetailsStep)

        // Confirmation step
        let confirmationStep = ORKQuestionStep(
            identifier: "sampleConfirmation",
            title: "Confirm Sample Collection",
            answer: ORKAnswerFormat.booleanAnswerFormat()
        )
        confirmationStep.text = "Have you successfully collected the sample?"
        steps.append(confirmationStep)

        // Completion
        let completionStep = CompletionStepFactory.createCompletionStep(
            identifier: "sampleCollection_completion",
            title: "Thank You",
            text: "Your sample has been recorded. Instructions for submission will be provided."
        )
        steps.append(completionStep)

        let task = ORKOrderedTask(identifier: "sampleCollectionTask", steps: steps)
        return task
    }

    /// Create a quality assessment task
    func createQualityAssessmentTask() throws -> ORKTask {
        logger.info("Creating quality assessment task")

        var steps: [ORKStep] = []

        // Instruction step
        let instructionStep = InstructionStepFactory.createInstructionStep(
            identifier: "quality_instruction",
            title: "Quality Assessment",
            text: "Please assess the quality of your submitted data"
        )
        steps.append(instructionStep)

        // Data integrity question
        let integrityStep = ORKQuestionStep(
            identifier: "dataIntegrity",
            title: "Data Integrity",
            answer: ORKAnswerFormat.scale(
                withMaximumValue: 5,
                minimumValue: 1,
                defaultValue: 3,
                step: 1,
                vertical: false,
                maximumValueDescription: "Very Complete",
                minimumValueDescription: "Incomplete"
            )
        )
        integrityStep.text = "How would you rate the completeness of your data?"
        steps.append(integrityStep)

        // Accuracy question
        let accuracyStep = ORKQuestionStep(
            identifier: "dataAccuracy",
            title: "Data Accuracy",
            answer: ORKAnswerFormat.scale(
                withMaximumValue: 5,
                minimumValue: 1,
                defaultValue: 3,
                step: 1,
                vertical: false,
                maximumValueDescription: "Very Accurate",
                minimumValueDescription: "Not Accurate"
            )
        )
        accuracyStep.text = "How confident are you in the accuracy of your data?"
        steps.append(accuracyStep)

        // Issues identification
        let issuesStep = ORKQuestionStep(
            identifier: "qualityIssues",
            title: "Issues Identified",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .multipleChoice,
                textChoices: [
                    ORKTextChoice(text: "Missing Data", value: "missing"),
                    ORKTextChoice(text: "Equipment Malfunction", value: "equipment"),
                    ORKTextChoice(text: "Environmental Interference", value: "environmental"),
                    ORKTextChoice(text: "Human Error", value: "error"),
                    ORKTextChoice(text: "No Issues", value: "none")
                ]
            )
        )
        issuesStep.text = "Were there any issues with data collection?"
        steps.append(issuesStep)

        // Comments
        let commentsStep = ORKQuestionStep(
            identifier: "qualityComments",
            title: "Additional Comments",
            answer: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 500)
        )
        commentsStep.isOptional = true
        steps.append(commentsStep)

        // Review step
        let reviewStep = ReviewStepFactory.createReviewStep(
            identifier: "quality_review",
            title: "Review Assessment",
            text: "Please review your quality assessment before submitting"
        )
        steps.append(reviewStep)

        // Completion
        let completionStep = CompletionStepFactory.createCompletionStep(
            identifier: "quality_completion",
            title: "Assessment Complete",
            text: "Thank you for assessing the data quality"
        )
        steps.append(completionStep)

        let task = ORKOrderedTask(identifier: "qualityAssessmentTask", steps: steps)
        return task
    }

    /// Create a general research task with custom steps
    func createCustomTask(identifier: String, title: String, steps: [ORKStep]) throws -> ORKTask {
        logger.debug("Creating custom task: \(identifier)")

        guard !steps.isEmpty else {
            throw TaskServiceError.emptySteps
        }

        let task = ORKOrderedTask(identifier: identifier, steps: steps)
        return task
    }
}

// MARK: - Error Types
enum TaskServiceError: LocalizedError {
    case invalidTask
    case emptySteps
    case taskCreationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidTask:
            return "Invalid task configuration"
        case .emptySteps:
            return "Task cannot have empty steps"
        case .taskCreationFailed(let reason):
            return "Failed to create task: \(reason)"
        }
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

    func error(_ message: String) {
        os_log("%{public}@", log: getLog(), type: .error, message)
    }

    private func getLog() -> os.OSLog {
        return OSLog(subsystem: subsystem, category: category)
    }
}

import os
