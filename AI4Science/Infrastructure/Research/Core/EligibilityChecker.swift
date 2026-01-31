import ResearchKit
import Foundation

/// Checks participant eligibility based on study criteria
@MainActor
final class EligibilityChecker: NSObject {
    // MARK: - Singleton

    static let shared = EligibilityChecker()

    // MARK: - Properties

    private let stepBuilder = EligibilityStepBuilder()
    private let resultHandler = EligibilityResultHandler()

    private var eligibilityResults: [String: EligibilityResult] = [:]

    // MARK: - Eligibility Assessment

    /// Check eligibility for a study
    func checkEligibility(for study: Study) async throws -> Bool {
        do {
            let result = try await evaluateEligibility(for: study)
            return result.isEligible
        } catch {
            throw error
        }
    }

    /// Get eligibility assessment details
    func getEligibilityAssessment(for study: Study) async throws -> EligibilityResult {
        try await evaluateEligibility(for: study)
    }

    /// Process eligibility task result
    func processEligibilityResult(
        _ result: ORKTaskResult,
        for studyID: String
    ) async throws -> EligibilityResult {
        do {
            let eligibilityResult = try resultHandler.handleEligibilityResult(
                result,
                studyID: studyID
            )
            eligibilityResults[studyID] = eligibilityResult
            return eligibilityResult
        } catch {
            throw error
        }
    }

    /// Check specific eligibility criterion
    func checkCriterion(
        _ criterion: EligibilityCriterion,
        against answers: [String: Any]
    ) throws -> Bool {
        let evaluator = EligibilityEvaluator()
        return try evaluator.evaluate(criterion, against: answers)
    }

    /// Get eligibility status
    func getEligibilityStatus(for studyID: String) -> EligibilityStatus {
        guard let result = eligibilityResults[studyID] else {
            return .notAssessed
        }

        if result.isEligible {
            return .eligible
        } else {
            return .ineligible(reasons: result.failureReasons)
        }
    }

    // MARK: - Private Helpers

    private func evaluateEligibility(for study: Study) async throws -> EligibilityResult {
        var passedCriteria: [String] = []
        var failedCriteria: [String] = []

        for (key, criterionValue) in study.eligibilityCriteria {
            // Parse and evaluate each criterion
            let criterion = try parseCriterion(key: key, value: criterionValue)

            // In a real implementation, this would evaluate against actual participant data
            // For now, we'll create a placeholder
            let passed = true // This would be determined by actual evaluation
            if passed {
                passedCriteria.append(key)
            } else {
                failedCriteria.append(key)
            }
        }

        return EligibilityResult(
            studyID: study.id,
            isEligible: failedCriteria.isEmpty,
            passedCriteria: passedCriteria,
            failureReasons: failedCriteria,
            timestamp: Date()
        )
    }

    private func parseCriterion(key: String, value: AnyCodable) throws -> EligibilityCriterion {
        // Convert AnyCodable to EligibilityCriterion
        // This is a placeholder implementation
        return EligibilityCriterion(
            identifier: key,
            type: .ageRange,
            operator: .greaterThanOrEqual,
            value: 18
        )
    }
}

// MARK: - Eligibility Evaluator

struct EligibilityEvaluator {
    func evaluate(_ criterion: EligibilityCriterion, against answers: [String: Any]) throws -> Bool {
        guard let answerValue = answers[criterion.identifier] else {
            return false
        }

        switch criterion.type {
        case .ageRange:
            return evaluateAge(criterion, value: answerValue)
        case .inclusionCriteria:
            return evaluateInclusion(criterion, value: answerValue)
        case .exclusionCriteria:
            return evaluateExclusion(criterion, value: answerValue)
        case .custom:
            return evaluateCustom(criterion, value: answerValue)
        }
    }

    private func evaluateAge(_ criterion: EligibilityCriterion, value: Any) -> Bool {
        guard let age = value as? Int else { return false }

        if let minAge = criterion.minValue as? Int {
            return age >= minAge
        }
        return true
    }

    private func evaluateInclusion(_ criterion: EligibilityCriterion, value: Any) -> Bool {
        guard let requiredValue = criterion.value else { return true }
        return value as? String == requiredValue as? String
    }

    private func evaluateExclusion(_ criterion: EligibilityCriterion, value: Any) -> Bool {
        guard let excludedValue = criterion.value else { return true }
        return value as? String != excludedValue as? String
    }

    private func evaluateCustom(_ criterion: EligibilityCriterion, value: Any) -> Bool {
        // Custom evaluation logic based on criterion rules
        return true
    }
}

// MARK: - Models

struct EligibilityCriterion: Codable {
    let identifier: String
    let type: EligibilityType
    let `operator`: ComparisonOperator
    let value: Any?
    let minValue: Any?
    let maxValue: Any?
    let description: String

    init(
        identifier: String,
        type: EligibilityType,
        operator: ComparisonOperator,
        value: Any? = nil,
        minValue: Any? = nil,
        maxValue: Any? = nil,
        description: String = ""
    ) {
        self.identifier = identifier
        self.type = type
        self.operator = `operator`
        self.value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.description = description
    }

    enum CodingKeys: String, CodingKey {
        case identifier, type, operator, minValue, maxValue, description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        type = try container.decode(EligibilityType.self, forKey: .type)
        `operator` = try container.decode(ComparisonOperator.self, forKey: .operator)
        minValue = try container.decodeIfPresent(Int.self, forKey: .minValue)
        maxValue = try container.decodeIfPresent(Int.self, forKey: .maxValue)
        description = try container.decode(String.self, forKey: .description)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(type, forKey: .type)
        try container.encode(`operator`, forKey: .operator)
        try container.encodeIfPresent(minValue as? Int, forKey: .minValue)
        try container.encodeIfPresent(maxValue as? Int, forKey: .maxValue)
        try container.encode(description, forKey: .description)
    }
}

enum EligibilityType: String, Codable {
    case ageRange
    case inclusionCriteria
    case exclusionCriteria
    case custom
}

enum ComparisonOperator: String, Codable {
    case equals
    case notEquals
    case greaterThan
    case greaterThanOrEqual
    case lessThan
    case lessThanOrEqual
    case contains
    case notContains
}

struct EligibilityResult: Identifiable, Codable {
    let id: String = UUID().uuidString
    let studyID: String
    let isEligible: Bool
    let passedCriteria: [String]
    let failureReasons: [String]
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id, studyID, isEligible, passedCriteria, failureReasons, timestamp
    }
}

enum EligibilityStatus {
    case notAssessed
    case eligible
    case ineligible(reasons: [String])

    var description: String {
        switch self {
        case .notAssessed:
            return "Eligibility not yet assessed"
        case .eligible:
            return "You are eligible for this study"
        case .ineligible(let reasons):
            return "You do not meet the eligibility criteria: \(reasons.joined(separator: ", "))"
        }
    }
}
