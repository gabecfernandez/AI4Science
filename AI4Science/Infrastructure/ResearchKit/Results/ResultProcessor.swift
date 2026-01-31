import Foundation
import ResearchKit

/// Processes ORKTaskResult into structured data
actor ResultProcessor {
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.ai4science.researchkit", category: "ResultProcessor")

    // MARK: - Public Methods

    /// Process a task result
    func process(_ taskResult: ORKTaskResult) throws -> ProcessedResult {
        logger.debug("Processing task result: \(taskResult.identifier)")

        let timestamp = Date()
        var responses: [String: Any] = [:]
        var errors: [ProcessingError] = []

        // Extract responses from step results
        if let stepResults = taskResult.results {
            for stepResult in stepResults {
                do {
                    if let questionResult = stepResult as? ORKQuestionResult {
                        let response = try processQuestionResult(questionResult)
                        responses[stepResult.identifier] = response
                    } else if let choiceResult = stepResult as? ORKChoiceQuestionResult {
                        let response = processChoiceResult(choiceResult)
                        responses[stepResult.identifier] = response
                    } else if let scaleResult = stepResult as? ORKScaleQuestionResult {
                        let response = processScaleResult(scaleResult)
                        responses[stepResult.identifier] = response
                    } else if let boolResult = stepResult as? ORKBooleanQuestionResult {
                        let response = processBooleanResult(boolResult)
                        responses[stepResult.identifier] = response
                    } else if let dateResult = stepResult as? ORKDateQuestionResult {
                        let response = processDateResult(dateResult)
                        responses[stepResult.identifier] = response
                    } else if let timeResult = stepResult as? ORKTimeOfDayQuestionResult {
                        let response = processTimeResult(timeResult)
                        responses[stepResult.identifier] = response
                    } else if let formResult = stepResult as? ORKFormStepResult {
                        let response = try processFormResult(formResult)
                        responses[stepResult.identifier] = response
                    }
                } catch {
                    errors.append(ProcessingError(stepId: stepResult.identifier, error: error.localizedDescription))
                    logger.error("Error processing step \(stepResult.identifier): \(error.localizedDescription)")
                }
            }
        }

        let processedResult = ProcessedResult(
            taskIdentifier: taskResult.identifier,
            timestamp: timestamp,
            duration: taskResult.totalSecondsSinceStart,
            responses: responses,
            errors: errors,
            isComplete: errors.isEmpty
        )

        logger.info("Task result processed: \(taskResult.identifier)")
        return processedResult
    }

    /// Process a specific question result
    func processQuestionResult(_ result: ORKQuestionResult) throws -> Any {
        if let answer = result.answer {
            return answer
        }
        throw ResultProcessorError.noAnswer
    }

    // MARK: - Private Methods

    private func processChoiceResult(_ result: ORKChoiceQuestionResult) -> [String] {
        var choices: [String] = []
        if let answer = result.answer as? [String] {
            choices = answer
        } else if let answer = result.answer as? String {
            choices = [answer]
        }
        return choices
    }

    private func processScaleResult(_ result: ORKScaleQuestionResult) -> Int {
        guard let answer = result.answer as? NSNumber else {
            return 0
        }
        return answer.intValue
    }

    private func processBooleanResult(_ result: ORKBooleanQuestionResult) -> Bool {
        guard let answer = result.answer as? NSNumber else {
            return false
        }
        return answer.boolValue
    }

    private func processDateResult(_ result: ORKDateQuestionResult) -> String {
        guard let answer = result.answer as? Date else {
            return ""
        }
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: answer)
    }

    private func processTimeResult(_ result: ORKTimeOfDayQuestionResult) -> String {
        guard let answer = result.answer as? DateComponents else {
            return ""
        }
        let hour = answer.hour ?? 0
        let minute = answer.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }

    private func processFormResult(_ result: ORKFormStepResult) throws -> [String: Any] {
        var formResponses: [String: Any] = [:]

        if let results = result.results {
            for stepResult in results {
                if let questionResult = stepResult as? ORKQuestionResult {
                    let response = try processQuestionResult(questionResult)
                    formResponses[stepResult.identifier] = response
                }
            }
        }

        return formResponses
    }
}

// MARK: - Models
struct ProcessedResult: Codable, Sendable {
    let taskIdentifier: String
    let timestamp: Date
    let duration: TimeInterval
    let responses: [String: Any]
    let errors: [ProcessingError]
    let isComplete: Bool

    enum CodingKeys: String, CodingKey {
        case taskIdentifier, timestamp, duration, errors, isComplete
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(taskIdentifier, forKey: .taskIdentifier)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(duration, forKey: .duration)
        try container.encode(errors, forKey: .errors)
        try container.encode(isComplete, forKey: .isComplete)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        taskIdentifier = try container.decode(String.self, forKey: .taskIdentifier)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        errors = try container.decode([ProcessingError].self, forKey: .errors)
        isComplete = try container.decode(Bool.self, forKey: .isComplete)
        responses = [:]
    }

    init(
        taskIdentifier: String,
        timestamp: Date,
        duration: TimeInterval,
        responses: [String: Any],
        errors: [ProcessingError],
        isComplete: Bool
    ) {
        self.taskIdentifier = taskIdentifier
        self.timestamp = timestamp
        self.duration = duration
        self.responses = responses
        self.errors = errors
        self.isComplete = isComplete
    }
}

struct ProcessingError: Codable, Sendable {
    let stepId: String
    let error: String
    let timestamp: Date

    init(stepId: String, error: String) {
        self.stepId = stepId
        self.error = error
        self.timestamp = Date()
    }
}

// MARK: - Error Types
enum ResultProcessorError: LocalizedError {
    case noAnswer
    case invalidFormat
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .noAnswer:
            return "Question has no answer"
        case .invalidFormat:
            return "Answer format is invalid"
        case .processingFailed(let reason):
            return "Processing failed: \(reason)"
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
