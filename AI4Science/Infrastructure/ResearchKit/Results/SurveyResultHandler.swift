import Foundation
import ResearchKit

/// Handles survey-specific result processing
actor SurveyResultHandler {
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.ai4science.researchkit", category: "SurveyResultHandler")

    // MARK: - Public Methods

    /// Process survey task results
    func processSurveyResult(_ taskResult: ORKTaskResult) throws -> SurveyResultData {
        logger.info("Processing survey result: \(taskResult.identifier)")

        var responses: [SurveyResponse] = []
        var completionStatus: SurveyCompletionStatus = .complete

        if let stepResults = taskResult.results {
            for stepResult in stepResults {
                if let questionResult = stepResult as? ORKQuestionResult {
                    let response = processSurveyResponse(questionResult)
                    responses.append(response)
                } else if let formResult = stepResult as? ORKFormStepResult {
                    let formResponses = processSurveyFormResult(formResult)
                    responses.append(contentsOf: formResponses)
                }
            }
        }

        let surveyData = SurveyResultData(
            surveyIdentifier: taskResult.identifier,
            timestamp: Date(),
            duration: taskResult.totalSecondsSinceStart,
            responses: responses,
            completionStatus: completionStatus,
            responseCount: responses.count
        )

        logger.info("Survey result processed: \(taskResult.identifier)")
        return surveyData
    }

    /// Calculate survey statistics
    func calculateSurveyStatistics(_ surveyResult: SurveyResultData) -> SurveyStatistics {
        logger.debug("Calculating survey statistics")

        var averageScales: [String: Double] = [:]
        var choiceFrequency: [String: [String: Int]] = [:]
        var textResponses: [String] = []

        for response in surveyResult.responses {
            if case .scale(let value) = response.answer {
                averageScales[response.questionId] = Double(value)
            } else if case .choices(let values) = response.answer {
                var frequencies = choiceFrequency[response.questionId] ?? [:]
                for value in values {
                    frequencies[value] = (frequencies[value] ?? 0) + 1
                }
                choiceFrequency[response.questionId] = frequencies
            } else if case .text(let text) = response.answer {
                textResponses.append(text)
            }
        }

        let completionPercentage = Double(surveyResult.responseCount) / Double(max(surveyResult.responses.count, 1)) * 100

        return SurveyStatistics(
            totalResponses: surveyResult.responses.count,
            completionPercentage: completionPercentage,
            averageScales: averageScales,
            choiceFrequency: choiceFrequency,
            textResponseCount: textResponses.count,
            completionTime: surveyResult.duration
        )
    }

    /// Validate survey responses
    func validateSurveyResponses(_ surveyResult: SurveyResultData) throws -> SurveyValidationResult {
        logger.debug("Validating survey responses")

        var validationErrors: [ValidationError] = []

        for response in surveyResult.responses {
            // Check for empty required responses
            if response.isRequired && response.answer == nil {
                validationErrors.append(
                    ValidationError(
                        questionId: response.questionId,
                        error: "Required response missing"
                    )
                )
            }

            // Validate response format
            if !isValidResponseFormat(response) {
                validationErrors.append(
                    ValidationError(
                        questionId: response.questionId,
                        error: "Invalid response format"
                    )
                )
            }
        }

        return SurveyValidationResult(
            isValid: validationErrors.isEmpty,
            errors: validationErrors
        )
    }

    /// Extract specific response
    func getResponse(for questionId: String, from surveyResult: SurveyResultData) -> SurveyResponse? {
        logger.debug("Extracting response for question: \(questionId)")
        return surveyResult.responses.first { $0.questionId == questionId }
    }

    /// Export survey responses in standard format
    func exportToCSV(_ surveyResult: SurveyResultData) throws -> String {
        logger.debug("Exporting survey to CSV")

        var csvContent = "Question ID,Question Text,Answer Type,Answer Value,Timestamp\n"

        for response in surveyResult.responses {
            let answerValue = formatAnswerForExport(response.answer)
            let line = "\(response.questionId),\(escape(response.questionText)),\(response.answerType),\(answerValue),\(surveyResult.timestamp.ISO8601Format())\n"
            csvContent += line
        }

        return csvContent
    }

    /// Create response summary
    func createResponseSummary(_ surveyResult: SurveyResultData) -> ResponseSummary {
        logger.debug("Creating response summary")

        var summary = ResponseSummary(
            surveyId: surveyResult.surveyIdentifier,
            responseCount: surveyResult.responseCount,
            completionTime: surveyResult.duration,
            responses: []
        )

        for response in surveyResult.responses {
            summary.responses.append(
                ResponseSummaryItem(
                    question: response.questionText,
                    answer: formatAnswerForDisplay(response.answer),
                    answerType: response.answerType
                )
            )
        }

        return summary
    }

    // MARK: - Private Methods

    private func processSurveyResponse(_ questionResult: ORKQuestionResult) -> SurveyResponse {
        var answer: SurveyAnswer? = nil
        var answerType = "unknown"

        if let choiceResult = questionResult as? ORKChoiceQuestionResult {
            if let choices = choiceResult.answer as? [String] {
                answer = .choices(choices)
                answerType = "multiple_choice"
            } else if let choice = choiceResult.answer as? String {
                answer = .choices([choice])
                answerType = "single_choice"
            }
        } else if let scaleResult = questionResult as? ORKScaleQuestionResult {
            if let value = scaleResult.answer as? NSNumber {
                answer = .scale(value.intValue)
                answerType = "scale"
            }
        } else if let textResult = questionResult as? ORKTextQuestionResult {
            if let text = textResult.answer as? String {
                answer = .text(text)
                answerType = "text"
            }
        } else if let boolResult = questionResult as? ORKBooleanQuestionResult {
            if let bool = boolResult.answer as? NSNumber {
                answer = .boolean(bool.boolValue)
                answerType = "boolean"
            }
        } else if let dateResult = questionResult as? ORKDateQuestionResult {
            if let date = dateResult.answer as? Date {
                answer = .date(date)
                answerType = "date"
            }
        }

        return SurveyResponse(
            questionId: questionResult.identifier,
            questionText: "Question",
            answer: answer,
            answerType: answerType,
            isRequired: !questionResult.isOptional,
            responseTime: Date()
        )
    }

    private func processSurveyFormResult(_ formResult: ORKFormStepResult) -> [SurveyResponse] {
        var responses: [SurveyResponse] = []

        if let results = formResult.results {
            for result in results {
                if let questionResult = result as? ORKQuestionResult {
                    responses.append(processSurveyResponse(questionResult))
                }
            }
        }

        return responses
    }

    private func isValidResponseFormat(_ response: SurveyResponse) -> Bool {
        if let answer = response.answer {
            switch answer {
            case .text(let text):
                return !text.trimmingCharacters(in: .whitespaces).isEmpty
            case .choices(let choices):
                return !choices.isEmpty
            case .scale(let value):
                return value >= 0 && value <= 10
            default:
                return true
            }
        }
        return response.isRequired == false
    }

    private func formatAnswerForExport(_ answer: SurveyAnswer?) -> String {
        guard let answer = answer else { return "" }

        switch answer {
        case .text(let text):
            return escape(text)
        case .choices(let choices):
            return choices.joined(separator: ";")
        case .scale(let value):
            return String(value)
        case .boolean(let bool):
            return bool ? "Yes" : "No"
        case .date(let date):
            return date.ISO8601Format()
        }
    }

    private func formatAnswerForDisplay(_ answer: SurveyAnswer?) -> String {
        guard let answer = answer else { return "" }

        switch answer {
        case .text(let text):
            return text
        case .choices(let choices):
            return choices.joined(separator: ", ")
        case .scale(let value):
            return String(value)
        case .boolean(let bool):
            return bool ? "Yes" : "No"
        case .date(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    private func escape(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }
}

// MARK: - Models
struct SurveyResultData: Codable, Sendable {
    let surveyIdentifier: String
    let timestamp: Date
    let duration: TimeInterval
    let responses: [SurveyResponse]
    let completionStatus: SurveyCompletionStatus
    let responseCount: Int
}

struct SurveyResponse: Codable, Sendable {
    let questionId: String
    let questionText: String
    let answer: SurveyAnswer?
    let answerType: String
    let isRequired: Bool
    let responseTime: Date
}

enum SurveyAnswer: Codable, Sendable {
    case text(String)
    case choices([String])
    case scale(Int)
    case boolean(Bool)
    case date(Date)

    enum CodingKeys: String, CodingKey {
        case text, choices, scale, boolean, date
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let value):
            try container.encode(value, forKey: .text)
        case .choices(let value):
            try container.encode(value, forKey: .choices)
        case .scale(let value):
            try container.encode(value, forKey: .scale)
        case .boolean(let value):
            try container.encode(value, forKey: .boolean)
        case .date(let value):
            try container.encode(value, forKey: .date)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try container.decodeIfPresent(String.self, forKey: .text) {
            self = .text(value)
        } else if let value = try container.decodeIfPresent([String].self, forKey: .choices) {
            self = .choices(value)
        } else if let value = try container.decodeIfPresent(Int.self, forKey: .scale) {
            self = .scale(value)
        } else if let value = try container.decodeIfPresent(Bool.self, forKey: .boolean) {
            self = .boolean(value)
        } else if let value = try container.decodeIfPresent(Date.self, forKey: .date) {
            self = .date(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode SurveyAnswer")
        }
    }
}

enum SurveyCompletionStatus: String, Codable, Sendable {
    case complete
    case incomplete
    case abandoned
    case screened
}

struct SurveyStatistics: Sendable {
    let totalResponses: Int
    let completionPercentage: Double
    let averageScales: [String: Double]
    let choiceFrequency: [String: [String: Int]]
    let textResponseCount: Int
    let completionTime: TimeInterval
}

struct ValidationError: Codable, Sendable {
    let questionId: String
    let error: String
}

struct SurveyValidationResult: Sendable {
    let isValid: Bool
    let errors: [ValidationError]
}

struct ResponseSummary: Sendable {
    let surveyId: String
    let responseCount: Int
    let completionTime: TimeInterval
    var responses: [ResponseSummaryItem]
}

struct ResponseSummaryItem: Sendable {
    let question: String
    let answer: String
    let answerType: String
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
