import Foundation
import ResearchKit

/// Service for creating and managing surveys
actor SurveyService {
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.ai4science.researchkit", category: "SurveyService")

    // MARK: - Public Methods

    /// Create an onboarding survey task
    func createOnboardingSurvey() throws -> ORKTask {
        logger.info("Creating onboarding survey")

        let questions: [SurveyQuestion] = [
            SurveyQuestion(
                identifier: "ageRange",
                title: "What is your age range?",
                type: .singleChoice,
                options: ["18-25", "26-35", "36-45", "46-55", "56-65", "65+"]
            ),
            SurveyQuestion(
                identifier: "scienceExperience",
                title: "What is your experience with scientific research?",
                type: .multipleChoice,
                options: ["Professional", "Academic", "Hobbyist", "Novice", "None"]
            ),
            SurveyQuestion(
                identifier: "motivation",
                title: "What motivates you to participate in this research?",
                type: .text,
                options: []
            )
        ]

        return try createCustomSurvey(
            identifier: "onboardingSurvey",
            title: "Welcome to AI4Science",
            questions: questions
        )
    }

    /// Create a demographic survey task
    func createDemographicsSurvey() throws -> ORKTask {
        logger.info("Creating demographics survey")

        let questions: [SurveyQuestion] = [
            SurveyQuestion(
                identifier: "gender",
                title: "How do you identify your gender?",
                type: .singleChoice,
                options: ["Male", "Female", "Non-binary", "Prefer to self-describe", "Prefer not to answer"]
            ),
            SurveyQuestion(
                identifier: "ethnicity",
                title: "What is your ethnicity or racial background?",
                type: .multipleChoice,
                options: ["White", "Black/African American", "Hispanic/Latino", "Asian", "Native American", "Pacific Islander", "Multiple", "Other", "Prefer not to answer"]
            ),
            SurveyQuestion(
                identifier: "education",
                title: "What is your highest level of education?",
                type: .singleChoice,
                options: ["High School", "Bachelor's", "Master's", "PhD", "Other"]
            ),
            SurveyQuestion(
                identifier: "field",
                title: "What is your primary field of study or work?",
                type: .text,
                options: []
            )
        ]

        return try createCustomSurvey(
            identifier: "demographicsSurvey",
            title: "Demographic Information",
            questions: questions
        )
    }

    /// Create a custom survey with specified questions
    func createCustomSurvey(identifier: String, title: String, questions: [SurveyQuestion]) throws -> ORKTask {
        logger.debug("Creating custom survey: \(identifier)")

        var steps: [ORKStep] = []

        // Add instruction step
        let instructionStep = InstructionStepFactory.createInstructionStep(
            identifier: "\(identifier)_instruction",
            title: title,
            text: "Please answer the following questions"
        )
        steps.append(instructionStep)

        // Add question steps
        for question in questions {
            let step = try createQuestionStep(from: question)
            steps.append(step)
        }

        // Add completion step
        let completionStep = CompletionStepFactory.createCompletionStep(
            identifier: "\(identifier)_completion",
            title: "Survey Complete",
            text: "Thank you for completing the survey"
        )
        steps.append(completionStep)

        let task = ORKOrderedTask(identifier: identifier, steps: steps)
        return task
    }

    // MARK: - Private Methods

    private func createQuestionStep(from question: SurveyQuestion) throws -> ORKStep {
        let answerFormat: ORKAnswerFormat

        switch question.type {
        case .singleChoice:
            let choiceAnswerFormat = ORKAnswerFormat.choiceAnswerFormat(
                with: .singleChoice,
                textChoices: question.options.map { text in
                    ORKTextChoice(text: text, value: text)
                }
            )
            answerFormat = choiceAnswerFormat

        case .multipleChoice:
            let choiceAnswerFormat = ORKAnswerFormat.choiceAnswerFormat(
                with: .multipleChoice,
                textChoices: question.options.map { text in
                    ORKTextChoice(text: text, value: text)
                }
            )
            answerFormat = choiceAnswerFormat

        case .text:
            answerFormat = ORKAnswerFormat.textAnswerFormat(withMaximumLength: 500)

        case .scale:
            answerFormat = ORKAnswerFormat.scale(
                withMaximumValue: 10,
                minimumValue: 1,
                defaultValue: 5,
                step: 1,
                vertical: false,
                maximumValueDescription: "Strongly Agree",
                minimumValueDescription: "Strongly Disagree"
            )

        case .boolean:
            answerFormat = ORKAnswerFormat.booleanAnswerFormat()
        }

        let questionStep = ORKQuestionStep(identifier: question.identifier, title: question.title, answer: answerFormat)
        questionStep.isOptional = false

        return questionStep
    }
}

// MARK: - Models
struct SurveyQuestion: Sendable {
    enum QuestionType: Sendable {
        case singleChoice
        case multipleChoice
        case text
        case scale
        case boolean
    }

    let identifier: String
    let title: String
    let type: QuestionType
    let options: [String]
}

// MARK: - Error Types
enum SurveyServiceError: LocalizedError {
    case invalidQuestion
    case taskCreationFailed

    var errorDescription: String? {
        switch self {
        case .invalidQuestion:
            return "Invalid survey question structure"
        case .taskCreationFailed:
            return "Failed to create survey task"
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
