import ResearchKit
import Foundation

/// Builds survey tasks with various question types
final class SurveyTaskBuilder: TaskBuilder {
    // MARK: - Survey Task Creation

    static func buildTask(
        withID identifier: String,
        configuration: TaskConfiguration
    ) -> ORKTask? {
        var steps: [ORKStep] = []

        // Add instruction step if title/description provided
        if !configuration.title.isEmpty {
            let instructionStep = createInstructionStep(
                identifier: "\(identifier)_instruction",
                title: configuration.title,
                text: configuration.description
            )
            steps.append(instructionStep)
        }

        // Add question steps
        for stepConfig in configuration.steps {
            if let questionStep = buildQuestionStep(from: stepConfig) {
                steps.append(questionStep)
            }
        }

        // Add completion step
        steps.append(createCompletionStep(identifier: "\(identifier)_completion"))

        return ORKOrderedTask(identifier: identifier, steps: steps)
    }

    // MARK: - Survey Question Types

    static func buildMultipleChoiceQuestion(
        identifier: String,
        title: String,
        choices: [String],
        allowsMultipleSelection: Bool = false,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKValuePickerAnswerFormat(textChoices: choices)
        let step = createQuestionStep(
            identifier: identifier,
            title: title,
            answerFormat: answerFormat,
            optional: optional
        )
        return step
    }

    static func buildScaleQuestion(
        identifier: String,
        title: String,
        minimum: Int = 1,
        maximum: Int = 5,
        minimumValueDescription: String? = nil,
        maximumValueDescription: String? = nil,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKScaleAnswerFormat(
            maximumValue: maximum,
            minimumValue: minimum,
            defaultValue: (minimum + maximum) / 2,
            step: 1,
            vertical: false,
            maximumValueDescription: maximumValueDescription,
            minimumValueDescription: minimumValueDescription
        )

        let step = createQuestionStep(
            identifier: identifier,
            title: title,
            answerFormat: answerFormat,
            optional: optional
        )
        return step
    }

    static func buildTextQuestion(
        identifier: String,
        title: String,
        placeholder: String = "",
        multiline: Bool = false,
        maxLength: Int = 0,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKTextAnswerFormat(maximumLength: maxLength)
        answerFormat.multipleLines = multiline
        answerFormat.placeholder = placeholder

        let step = createQuestionStep(
            identifier: identifier,
            title: title,
            answerFormat: answerFormat,
            optional: optional
        )
        return step
    }

    static func buildBooleanQuestion(
        identifier: String,
        title: String,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKBooleanAnswerFormat()
        let step = createQuestionStep(
            identifier: identifier,
            title: title,
            answerFormat: answerFormat,
            optional: optional
        )
        return step
    }

    static func buildNumericQuestion(
        identifier: String,
        title: String,
        unit: String? = nil,
        placeholder: String = "",
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKNumericAnswerFormat(style: .decimal)
        answerFormat.maximum = NSNumber(value: 1000)
        answerFormat.minimum = NSNumber(value: 0)
        answerFormat.unit = unit
        answerFormat.placeholder = placeholder

        let step = createQuestionStep(
            identifier: identifier,
            title: title,
            answerFormat: answerFormat,
            optional: optional
        )
        return step
    }

    static func buildDateQuestion(
        identifier: String,
        title: String,
        defaultDate: Date? = nil,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKDateAnswerFormat(style: .date)
        let step = createQuestionStep(
            identifier: identifier,
            title: title,
            answerFormat: answerFormat,
            optional: optional
        )
        return step
    }

    static func buildTimeQuestion(
        identifier: String,
        title: String,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKTimeOfDayAnswerFormat()
        let step = createQuestionStep(
            identifier: identifier,
            title: title,
            answerFormat: answerFormat,
            optional: optional
        )
        return step
    }

    static func buildMatrixQuestion(
        identifier: String,
        title: String,
        items: [String],
        choices: [String],
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKMatrixAnswerFormat(
            matrixRows: items.map { ORKMatrixRow(identifier: $0, text: $0) } as [ORKMatrixRow],
            columns: choices.map { ORKMatrixColumn(identifier: $0, text: $0) } as [ORKMatrixColumn]
        )

        let step = createQuestionStep(
            identifier: identifier,
            title: title,
            answerFormat: answerFormat,
            optional: optional
        )
        return step
    }

    static func buildFormStep(
        identifier: String,
        title: String,
        formItems: [ORKFormItem]
    ) -> ORKFormStep {
        let step = ORKFormStep(identifier: identifier, title: title, text: nil)
        step.formItems = formItems
        return step
    }

    // MARK: - Private Helpers

    private static func buildQuestionStep(from configuration: StepConfiguration) -> ORKStep? {
        switch configuration.type {
        case .question:
            // Default to text question
            return buildTextQuestion(
                identifier: configuration.identifier,
                title: configuration.title ?? "",
                optional: configuration.optional
            )

        case .scale:
            return buildScaleQuestion(
                identifier: configuration.identifier,
                title: configuration.title ?? "",
                optional: configuration.optional
            )

        case .datePicker:
            return buildDateQuestion(
                identifier: configuration.identifier,
                title: configuration.title ?? "",
                optional: configuration.optional
            )

        case .timeOfDay:
            return buildTimeQuestion(
                identifier: configuration.identifier,
                title: configuration.title ?? "",
                optional: configuration.optional
            )

        case .instruction:
            return createInstructionStep(
                identifier: configuration.identifier,
                title: configuration.title ?? "",
                text: configuration.text
            )

        case .form:
            return buildFormStep(
                identifier: configuration.identifier,
                title: configuration.title ?? "",
                formItems: []
            )

        default:
            return nil
        }
    }
}
