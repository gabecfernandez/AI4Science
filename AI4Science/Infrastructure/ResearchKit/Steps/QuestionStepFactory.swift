import Foundation
import ResearchKit

/// Factory for creating various question types
enum QuestionStepFactory {
    // MARK: - Single Choice Questions

    /// Create a single-choice question step
    static func createSingleChoiceQuestion(
        identifier: String,
        title: String,
        options: [String],
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKAnswerFormat.choiceAnswerFormat(
            with: .singleChoice,
            textChoices: options.map { text in
                ORKTextChoice(text: text, value: text)
            }
        )

        let step = ORKQuestionStep(identifier: identifier, title: title, answer: answerFormat)
        step.isOptional = optional
        return step
    }

    /// Create a multiple-choice question step
    static func createMultipleChoiceQuestion(
        identifier: String,
        title: String,
        options: [String],
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKAnswerFormat.choiceAnswerFormat(
            with: .multipleChoice,
            textChoices: options.map { text in
                ORKTextChoice(text: text, value: text)
            }
        )

        let step = ORKQuestionStep(identifier: identifier, title: title, answer: answerFormat)
        step.isOptional = optional
        return step
    }

    // MARK: - Text Questions

    /// Create a text response question
    static func createTextQuestion(
        identifier: String,
        title: String,
        maxLength: Int = 500,
        placeholder: String? = nil,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKAnswerFormat.textAnswerFormat(withMaximumLength: maxLength)
        let step = ORKQuestionStep(identifier: identifier, title: title, answer: answerFormat)
        step.isOptional = optional
        return step
    }

    /// Create a long-form text response question
    static func createLongTextQuestion(
        identifier: String,
        title: String,
        maxLength: Int = 2000,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKAnswerFormat.textAnswerFormat(withMaximumLength: maxLength)
        let step = ORKQuestionStep(identifier: identifier, title: title, answer: answerFormat)
        step.isOptional = optional
        return step
    }

    // MARK: - Numeric Questions

    /// Create an integer question
    static func createIntegerQuestion(
        identifier: String,
        title: String,
        unit: String? = nil,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKAnswerFormat.integerAnswerFormat(withUnit: unit)
        let step = ORKQuestionStep(identifier: identifier, title: title, answer: answerFormat)
        step.isOptional = optional
        return step
    }

    /// Create a decimal/float question
    static func createDecimalQuestion(
        identifier: String,
        title: String,
        unit: String? = nil,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKAnswerFormat.decimalAnswerFormat(withUnit: unit)
        let step = ORKQuestionStep(identifier: identifier, title: title, answer: answerFormat)
        step.isOptional = optional
        return step
    }

    // MARK: - Scale Questions

    /// Create a numeric scale question
    static func createScaleQuestion(
        identifier: String,
        title: String,
        minValue: Int = 1,
        maxValue: Int = 10,
        minLabel: String? = nil,
        maxLabel: String? = nil,
        step: Int = 1,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKAnswerFormat.scale(
            withMaximumValue: maxValue,
            minimumValue: minValue,
            defaultValue: (minValue + maxValue) / 2,
            step: step,
            vertical: false,
            maximumValueDescription: maxLabel,
            minimumValueDescription: minLabel
        )

        let questionStep = ORKQuestionStep(identifier: identifier, title: title, answer: answerFormat)
        questionStep.isOptional = optional
        return questionStep
    }

    /// Create a continuous scale question
    static func createContinuousScaleQuestion(
        identifier: String,
        title: String,
        minValue: Double = 0,
        maxValue: Double = 10,
        minLabel: String? = nil,
        maxLabel: String? = nil,
        step: Double = 0.1,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKAnswerFormat.continuousScale(
            withMaximumValue: maxValue,
            minimumValue: minValue,
            defaultValue: (minValue + maxValue) / 2,
            maximumFractionDigits: 1,
            vertical: false,
            maximumValueDescription: maxLabel,
            minimumValueDescription: minLabel
        )

        let questionStep = ORKQuestionStep(identifier: identifier, title: title, answer: answerFormat)
        questionStep.isOptional = optional
        return questionStep
    }

    // MARK: - Boolean Questions

    /// Create a yes/no boolean question
    static func createBooleanQuestion(
        identifier: String,
        title: String,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKAnswerFormat.booleanAnswerFormat()
        let step = ORKQuestionStep(identifier: identifier, title: title, answer: answerFormat)
        step.isOptional = optional
        return step
    }

    // MARK: - Date/Time Questions

    /// Create a date question
    static func createDateQuestion(
        identifier: String,
        title: String,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKDateAnswerFormat(style: .date)
        let step = ORKQuestionStep(identifier: identifier, title: title, answer: answerFormat)
        step.isOptional = optional
        return step
    }

    /// Create a date and time question
    static func createDateTimeQuestion(
        identifier: String,
        title: String,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKDateAnswerFormat(style: .dateAndTime)
        let step = ORKQuestionStep(identifier: identifier, title: title, answer: answerFormat)
        step.isOptional = optional
        return step
    }

    /// Create a time question
    static func createTimeQuestion(
        identifier: String,
        title: String,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKDateAnswerFormat(style: .time)
        let step = ORKQuestionStep(identifier: identifier, title: title, answer: answerFormat)
        step.isOptional = optional
        return step
    }

    // MARK: - Time Interval Questions

    /// Create a time interval question
    static func createTimeIntervalQuestion(
        identifier: String,
        title: String,
        step: Int = 1,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKTimeIntervalAnswerFormat(defaultInterval: 0, step: step)
        let questionStep = ORKQuestionStep(identifier: identifier, title: title, answer: answerFormat)
        questionStep.isOptional = optional
        return questionStep
    }

    // MARK: - Image Choice Questions

    /// Create an image choice question
    static func createImageChoiceQuestion(
        identifier: String,
        title: String,
        choices: [ImageChoice],
        optional: Bool = false
    ) -> ORKQuestionStep {
        let imageChoices = choices.map { choice in
            ORKImageChoice(normalImage: choice.image, selectedImage: nil, text: choice.text, value: choice.value)
        }

        let answerFormat = ORKAnswerFormat.choiceAnswerFormat(with: .singleChoice, imageChoices: imageChoices)
        let step = ORKQuestionStep(identifier: identifier, title: title, answer: answerFormat)
        step.isOptional = optional
        return step
    }

    // MARK: - Numeric Answer Questions

    /// Create a numeric answer question with constraints
    static func createNumericQuestion(
        identifier: String,
        title: String,
        minimum: Int? = nil,
        maximum: Int? = nil,
        unit: String? = nil,
        optional: Bool = false
    ) -> ORKQuestionStep {
        let answerFormat = ORKAnswerFormat.integerAnswerFormat(withUnit: unit)

        let step = ORKQuestionStep(identifier: identifier, title: title, answer: answerFormat)
        step.isOptional = optional
        return step
    }
}

// MARK: - Supporting Types
struct ImageChoice: Sendable {
    let image: UIImage
    let text: String
    let value: String

    init(image: UIImage, text: String, value: String) {
        self.image = image
        self.text = text
        self.value = value
    }
}
