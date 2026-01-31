import ResearchKit
import Foundation

/// Factory for creating ORKTask instances
final class TaskFactory {
    // MARK: - Task Creation

    static func createTask(
        withID identifier: String,
        type: TaskType,
        configuration: TaskConfiguration
    ) -> ORKTask? {
        switch type {
        case .survey:
            return SurveyTaskBuilder.buildTask(
                withID: identifier,
                configuration: configuration
            )

        case .activeTask:
            return ActiveTaskBuilder.buildTask(
                withID: identifier,
                configuration: configuration
            )

        case .consent:
            return ConsentTaskBuilder.buildTask(
                withID: identifier,
                configuration: configuration
            )

        case .onboarding:
            return OnboardingTaskBuilder.buildTask(
                withID: identifier,
                configuration: configuration
            )

        case .custom:
            return createCustomTask(
                withID: identifier,
                configuration: configuration
            )
        }
    }

    static func createOrderedTask(
        withID identifier: String,
        steps: [ORKStep]
    ) -> ORKTask {
        ORKOrderedTask(identifier: identifier, steps: steps)
    }

    static func createNavigableTask(
        withID identifier: String,
        steps: [ORKStep],
        rules: [ORKStepNavigationRule]
    ) -> ORKTask {
        let task = ORKNavigableOrderedTask(identifier: identifier, steps: steps)

        for rule in rules {
            task.setNavigationRule(rule, forTriggerStepIdentifier: rule.triggerStepIdentifier ?? "")
        }

        return task
    }

    // MARK: - Custom Task Creation

    private static func createCustomTask(
        withID identifier: String,
        configuration: TaskConfiguration
    ) -> ORKTask? {
        // Implement custom task creation based on configuration
        let steps: [ORKStep] = []
        return ORKOrderedTask(identifier: identifier, steps: steps)
    }
}

// MARK: - Models

enum TaskType: String, Codable {
    case survey
    case activeTask
    case consent
    case onboarding
    case custom
}

struct TaskConfiguration: Codable {
    let taskID: String
    let title: String
    let description: String
    let estimatedDuration: Int // minutes
    let steps: [StepConfiguration]
    let navigationRules: [NavigationRuleConfiguration]?

    enum CodingKeys: String, CodingKey {
        case taskID, title, description, estimatedDuration, steps, navigationRules
    }
}

struct StepConfiguration: Codable {
    let identifier: String
    let type: StepType
    let title: String?
    let text: String?
    let optional: Bool
    let allowsSkipping: Bool
    let properties: [String: AnyCodable]?
}

enum StepType: String, Codable {
    case instruction
    case question
    case scale
    case timeOfDay
    case datePicker
    case imagePicker
    case form
    case custom
}

struct NavigationRuleConfiguration: Codable {
    let triggerStepID: String
    let destinationStepID: String
    let condition: String
}

// MARK: - Task Builder Protocol

protocol TaskBuilder {
    static func buildTask(
        withID identifier: String,
        configuration: TaskConfiguration
    ) -> ORKTask?
}

extension TaskBuilder {
    static func createInstructionStep(
        identifier: String,
        title: String,
        text: String? = nil,
        detailedText: String? = nil,
        image: UIImage? = nil
    ) -> ORKInstructionStep {
        let step = ORKInstructionStep(identifier: identifier)
        step.title = title
        step.text = text
        step.detailedText = detailedText
        step.image = image
        return step
    }

    static func createQuestionStep(
        identifier: String,
        title: String,
        answerFormat: ORKAnswerFormat,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let step = ORKQuestionStep(identifier: identifier, title: title, answer: answerFormat)
        step.isOptional = optional
        return step
    }

    static func createCompletionStep(
        identifier: String = "completionStep",
        title: String = "Thank You",
        text: String = "Your responses have been saved"
    ) -> ORKCompletionStep {
        let step = ORKCompletionStep(identifier: identifier)
        step.title = title
        step.text = text
        return step
    }
}
