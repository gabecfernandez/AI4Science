import Foundation

/// Domain-level analysis service protocol
@available(iOS 15.0, *)
public protocol AnalysisServiceProtocol: Sendable {
    /// Execute ML model on capture
    func runMLAnalysis(captureId: String, modelId: String, parameters: AnalysisParameters) async throws -> MLAnalysisResult

    /// Analyze multiple captures in batch
    func batchAnalysis(captureIds: [String], modelId: String, parameters: AnalysisParameters) async throws -> [MLAnalysisResult]

    /// Fetch analysis history
    func fetchAnalysisResults(captureId: String) async throws -> [MLAnalysisResult]

    /// Export analysis report
    func exportAnalysisReport(resultIds: [String], format: AnalysisReportFormat) async throws -> Data

    /// Compare multiple analysis results
    func compareResults(resultIds: [String]) async throws -> ComparisonResult

    /// Cancel running analysis
    func cancelAnalysis(resultId: String) async throws

    /// Get available ML models
    func fetchAvailableModels() async throws -> [MLModel]
}

/// ML Analysis result
public struct MLAnalysisResult: Sendable {
    public let id: String
    public let captureId: String
    public let projectId: String
    public let modelId: String
    public let modelVersion: String
    public let executionTime: TimeInterval
    public let createdAt: Date
    public let status: AnalysisStatus
    public let predictions: [Prediction]
    public let confidence: Double
    public let metadata: AnalysisMetadata

    public init(
        id: String,
        captureId: String,
        projectId: String,
        modelId: String,
        modelVersion: String,
        executionTime: TimeInterval,
        createdAt: Date,
        status: AnalysisStatus,
        predictions: [Prediction],
        confidence: Double,
        metadata: AnalysisMetadata
    ) {
        self.id = id
        self.captureId = captureId
        self.projectId = projectId
        self.modelId = modelId
        self.modelVersion = modelVersion
        self.executionTime = executionTime
        self.createdAt = createdAt
        self.status = status
        self.predictions = predictions
        self.confidence = confidence
        self.metadata = metadata
    }
}

/// Analysis status
public enum AnalysisStatus: String, Sendable {
    case queued
    case running
    case completed
    case failed
    case cancelled
}

/// ML Prediction
public struct Prediction: Sendable {
    public let label: String
    public let score: Double
    public let metadata: [String: String]

    public init(label: String, score: Double, metadata: [String: String] = [:]) {
        self.label = label
        self.score = score
        self.metadata = metadata
    }
}

/// Analysis metadata
public struct AnalysisMetadata: Sendable {
    public let hardwareUsed: String
    public let processingTime: TimeInterval
    public let memoryUsedMB: Int
    public let customParameters: [String: String]

    public init(
        hardwareUsed: String,
        processingTime: TimeInterval,
        memoryUsedMB: Int,
        customParameters: [String: String] = [:]
    ) {
        self.hardwareUsed = hardwareUsed
        self.processingTime = processingTime
        self.memoryUsedMB = memoryUsedMB
        self.customParameters = customParameters
    }
}

/// Analysis parameters
public struct AnalysisParameters: Sendable {
    public let threshold: Double?
    public let options: [String: String]
    public let priority: ProcessingPriority

    public init(
        threshold: Double? = nil,
        options: [String: String] = [:],
        priority: ProcessingPriority = .normal
    ) {
        self.threshold = threshold
        self.options = options
        self.priority = priority
    }
}

/// Processing priority
public enum ProcessingPriority: String, Sendable {
    case low
    case normal
    case high
    case critical
}

/// ML Model information
public struct MLModel: Sendable {
    public let id: String
    public let name: String
    public let version: String
    public let description: String
    public let category: ModelCategory
    public let inputTypes: [InputType]
    public let outputTypes: [OutputType]
    public let minIOSVersion: String
    public let isLocalOnly: Bool

    public init(
        id: String,
        name: String,
        version: String,
        description: String,
        category: ModelCategory,
        inputTypes: [InputType],
        outputTypes: [OutputType],
        minIOSVersion: String,
        isLocalOnly: Bool
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.description = description
        self.category = category
        self.inputTypes = inputTypes
        self.outputTypes = outputTypes
        self.minIOSVersion = minIOSVersion
        self.isLocalOnly = isLocalOnly
    }
}

/// Model category
public enum ModelCategory: String, Sendable {
    case classification
    case detection
    case segmentation
    case regression
    case custom
}

/// Input type
public enum InputType: String, Sendable {
    case image
    case video
    case numeric
    case text
}

/// Output type
public enum OutputType: String, Sendable {
    case classification
    case boundingBox
    case mask
    case numeric
    case text
}

/// Comparison result
public struct ComparisonResult: Sendable {
    public let resultIds: [String]
    public let similarity: Double
    public let differences: [Difference]
    public let summary: String

    public init(
        resultIds: [String],
        similarity: Double,
        differences: [Difference],
        summary: String
    ) {
        self.resultIds = resultIds
        self.similarity = similarity
        self.differences = differences
        self.summary = summary
    }
}

/// Difference in comparison
public struct Difference: Sendable {
    public let metric: String
    public let values: [Double]
    public let description: String

    public init(metric: String, values: [Double], description: String) {
        self.metric = metric
        self.values = values
        self.description = description
    }
}

/// Analysis report format
public enum AnalysisReportFormat: String, Sendable {
    case pdf
    case html
    case json
    case csv
}

/// Analysis errors
public enum AnalysisError: LocalizedError, Sendable {
    case modelNotFound
    case analysisNotFound
    case analysisFailure(String)
    case modelNotSupported
    case insufficientMemory
    case networkError(String)
    case unknownError(String)

    public var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "ML model not found"
        case .analysisNotFound:
            return "Analysis result not found"
        case .analysisFailure(let message):
            return "Analysis failed: \(message)"
        case .modelNotSupported:
            return "Model is not supported on this device"
        case .insufficientMemory:
            return "Insufficient memory to run analysis"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknownError(let message):
            return "Error: \(message)"
        }
    }
}
