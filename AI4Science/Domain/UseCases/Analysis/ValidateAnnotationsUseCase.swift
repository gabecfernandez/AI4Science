import Foundation

public struct ValidateAnnotationsUseCase: Sendable {
    private let analysisRepository: any AnalysisRepositoryProtocol

    public init(analysisRepository: any AnalysisRepositoryProtocol) {
        self.analysisRepository = analysisRepository
    }

    /// Validates annotation quality and consistency
    /// - Parameters:
    ///   - findings: Array of findings to validate
    ///   - rules: Validation rules to apply
    /// - Returns: AnnotationValidationResult with issues and recommendations
    /// - Throws: AnalysisError if validation fails
    public func execute(
        findings: [AnnotationFinding],
        rules: ValidationRules? = nil
    ) async throws -> AnnotationValidationResult {
        guard !findings.isEmpty else {
            throw AnalysisError.validationFailed("At least one finding is required.")
        }

        let validationRules = rules ?? ValidationRules()
        let issues = validateFindings(findings, with: validationRules)

        return AnnotationValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            totalFindingsChecked: findings.count,
            confidence: calculateValidationConfidence(issues: issues, total: findings.count)
        )
    }

    /// Validates annotations across multiple analysis results
    /// - Parameters:
    ///   - results: Array of analysis results
    ///   - rules: Validation rules
    /// - Returns: Comprehensive validation report
    /// - Throws: AnalysisError if validation fails
    public func validateBatch(
        results: [AnalysisResult],
        rules: ValidationRules? = nil
    ) async throws -> BatchValidationReport {
        guard !results.isEmpty else {
            throw AnalysisError.validationFailed("At least one analysis result is required.")
        }

        let validationRules = rules ?? ValidationRules()
        var individualResults: [String: AnnotationValidationResult] = [:]
        var allIssues: [ValidationIssue] = []

        for result in results {
            // Convert predictions to findings for validation
            let findings = result.predictions.map { prediction in
                AnnotationFinding(
                    id: UUID().uuidString,
                    label: prediction.className,
                    confidence: Float(prediction.confidence),
                    boundingBox: nil
                )
            }

            guard !findings.isEmpty else { continue }

            do {
                let validation = try await execute(
                    findings: findings,
                    rules: validationRules
                )
                individualResults[result.id.uuidString] = validation
                allIssues.append(contentsOf: validation.issues)
            } catch {
                print("Validation failed for result \(result.id): \(error)")
            }
        }

        return BatchValidationReport(
            totalAnalyzed: results.count,
            validCount: individualResults.values.filter { $0.isValid }.count,
            issuesFound: allIssues.count,
            allIssues: allIssues,
            individualResults: individualResults
        )
    }

    // MARK: - Private Methods

    private func validateFindings(
        _ findings: [AnnotationFinding],
        with rules: ValidationRules
    ) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []

        for finding in findings {
            // Check confidence threshold
            if finding.confidence < rules.minConfidence {
                issues.append(
                    ValidationIssue(
                        findingId: finding.id,
                        severity: .warning,
                        message: "Confidence \(finding.confidence) below minimum \(rules.minConfidence)"
                    )
                )
            }

            // Check required fields
            if rules.requireBoundingBox && finding.boundingBox == nil {
                issues.append(
                    ValidationIssue(
                        findingId: finding.id,
                        severity: .error,
                        message: "Bounding box is required but missing"
                    )
                )
            }

            // Check label validity
            if !rules.allowedLabels.isEmpty && !rules.allowedLabels.contains(finding.label) {
                issues.append(
                    ValidationIssue(
                        findingId: finding.id,
                        severity: .error,
                        message: "Label '\(finding.label)' is not in allowed list"
                    )
                )
            }

            // Validate bounding box if present
            if let bbox = finding.boundingBox {
                if !isValidBoundingBox(bbox) {
                    issues.append(
                        ValidationIssue(
                            findingId: finding.id,
                            severity: .error,
                            message: "Invalid bounding box coordinates"
                        )
                    )
                }
            }
        }

        return issues
    }

    private func isValidBoundingBox(_ bbox: BoundingBox) -> Bool {
        bbox.x >= 0 && bbox.y >= 0 &&
        bbox.width > 0 && bbox.height > 0 &&
        bbox.x + bbox.width <= 1.0 &&
        bbox.y + bbox.height <= 1.0
    }

    private func calculateValidationConfidence(issues: [ValidationIssue], total: Int) -> Float {
        guard total > 0 else { return 1.0 }

        let errorCount = issues.filter { $0.severity == .error }.count
        return max(0, Float(total - errorCount) / Float(total))
    }
}

// MARK: - Supporting Types

/// A finding to be validated (distinct from ML predictions)
public struct AnnotationFinding: Sendable {
    public let id: String
    public let label: String
    public let confidence: Float
    public let boundingBox: BoundingBox?

    public init(
        id: String,
        label: String,
        confidence: Float,
        boundingBox: BoundingBox? = nil
    ) {
        self.id = id
        self.label = label
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

/// Annotation validation result (distinct from MLModelValidator's ValidationResult)
public struct AnnotationValidationResult: Sendable {
    public let isValid: Bool
    public let issues: [ValidationIssue]
    public let totalFindingsChecked: Int
    public let confidence: Float

    public init(
        isValid: Bool,
        issues: [ValidationIssue],
        totalFindingsChecked: Int,
        confidence: Float
    ) {
        self.isValid = isValid
        self.issues = issues
        self.totalFindingsChecked = totalFindingsChecked
        self.confidence = confidence
    }
}

public struct ValidationIssue: Sendable, Identifiable {
    public let id: String = UUID().uuidString
    public let findingId: String
    public let severity: IssueSeverity
    public let message: String

    public init(
        findingId: String,
        severity: IssueSeverity,
        message: String
    ) {
        self.findingId = findingId
        self.severity = severity
        self.message = message
    }
}

public enum IssueSeverity: Sendable {
    case info
    case warning
    case error

    public var priority: Int {
        switch self {
        case .info:
            return 1
        case .warning:
            return 2
        case .error:
            return 3
        }
    }
}

public struct ValidationRules: Sendable {
    public var minConfidence: Float
    public var requireBoundingBox: Bool
    public var allowedLabels: [String]
    public var strictMode: Bool

    public init(
        minConfidence: Float = 0.5,
        requireBoundingBox: Bool = false,
        allowedLabels: [String] = [],
        strictMode: Bool = false
    ) {
        self.minConfidence = minConfidence
        self.requireBoundingBox = requireBoundingBox
        self.allowedLabels = allowedLabels
        self.strictMode = strictMode
    }
}

public struct BatchValidationReport: Sendable {
    public let totalAnalyzed: Int
    public let validCount: Int
    public let issuesFound: Int
    public let allIssues: [ValidationIssue]
    public let individualResults: [String: AnnotationValidationResult]

    public var overallValidity: Float {
        guard totalAnalyzed > 0 else { return 1.0 }
        return Float(validCount) / Float(totalAnalyzed)
    }

    public init(
        totalAnalyzed: Int,
        validCount: Int,
        issuesFound: Int,
        allIssues: [ValidationIssue],
        individualResults: [String: AnnotationValidationResult]
    ) {
        self.totalAnalyzed = totalAnalyzed
        self.validCount = validCount
        self.issuesFound = issuesFound
        self.allIssues = allIssues
        self.individualResults = individualResults
    }
}
