import Foundation

public struct RunAnalysisUseCase: Sendable {
    private let analysisRepository: any AnalysisRepositoryProtocol

    public init(analysisRepository: any AnalysisRepositoryProtocol) {
        self.analysisRepository = analysisRepository
    }

    /// Runs ML analysis on a capture
    /// - Parameters:
    ///   - captureId: Capture identifier
    ///   - modelId: ML model identifier to use
    ///   - parameters: Optional analysis parameters
    /// - Returns: AnalysisResult with findings
    /// - Throws: AnalysisError if analysis fails
    public func execute(
        captureId: String,
        modelId: String,
        parameters: AnalysisParameters? = nil
    ) async throws -> AnalysisResult {
        // Validate inputs
        guard !captureId.isEmpty else {
            throw AnalysisError.validationFailed("Capture ID is required.")
        }

        guard !modelId.isEmpty else {
            throw AnalysisError.validationFailed("Model ID is required.")
        }

        // Run analysis through repository
        let result = try await analysisRepository.runAnalysis(
            captureId: captureId,
            modelId: modelId,
            parameters: parameters
        )

        return result
    }

    /// Gets analysis progress
    /// - Parameter analysisId: Analysis identifier
    /// - Returns: AnalysisProgress with current status
    /// - Throws: AnalysisError if fetch fails
    public func getProgress(analysisId: String) async throws -> AnalysisProgress {
        guard !analysisId.isEmpty else {
            throw AnalysisError.validationFailed("Analysis ID is required.")
        }

        return try await analysisRepository.getAnalysisProgress(analysisId)
    }

    /// Cancels an ongoing analysis
    /// - Parameter analysisId: Analysis identifier
    /// - Throws: AnalysisError if cancellation fails
    public func cancel(analysisId: String) async throws {
        guard !analysisId.isEmpty else {
            throw AnalysisError.validationFailed("Analysis ID is required.")
        }

        try await analysisRepository.cancelAnalysis(analysisId)
    }
}

// MARK: - Supporting Types

public struct Finding: Sendable, Codable, Identifiable {
    public let id: String
    public let type: String
    public let label: String
    public let confidence: Float
    public let boundingBox: BoundingBox?
    public let metadata: [String: String]

    public init(
        id: String = UUID().uuidString,
        type: String,
        label: String,
        confidence: Float,
        boundingBox: BoundingBox? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.label = label
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.metadata = metadata
    }
}

public struct AnalysisParameters: Sendable, Codable {
    public var confidenceThreshold: Float
    public var maxDetections: Int
    public var options: [String: String]

    public init(
        confidenceThreshold: Float = 0.5,
        maxDetections: Int = 100,
        options: [String: String] = [:]
    ) {
        self.confidenceThreshold = confidenceThreshold
        self.maxDetections = maxDetections
        self.options = options
    }
}

public struct AnalysisProgress: Sendable {
    public let analysisId: String
    public let status: AnalysisStatus
    public let progress: Float // 0.0 to 1.0
    public let estimatedTimeRemaining: TimeInterval?
    public let currentStep: String?

    public init(
        analysisId: String,
        status: AnalysisStatus,
        progress: Float,
        estimatedTimeRemaining: TimeInterval? = nil,
        currentStep: String? = nil
    ) {
        self.analysisId = analysisId
        self.status = status
        self.progress = progress
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.currentStep = currentStep
    }
}

public enum AnalysisError: LocalizedError, Sendable {
    case validationFailed(String)
    case analysisNotFound
    case modelNotFound
    case processingFailed(String)
    case networkError
    case serverError(message: String)
    case insufficientData

    public var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return message
        case .analysisNotFound:
            return "Analysis not found."
        case .modelNotFound:
            return "ML model not found."
        case .processingFailed(let message):
            return "Analysis processing failed: \(message)"
        case .networkError:
            return "Network connection failed."
        case .serverError(let message):
            return "Server error: \(message)"
        case .insufficientData:
            return "Insufficient data for analysis."
        }
    }
}

// MARK: - Repository Protocol

public protocol AnalysisRepositoryProtocol: Sendable {
    func runAnalysis(
        captureId: String,
        modelId: String,
        parameters: AnalysisParameters?
    ) async throws -> AnalysisResult

    func getAnalysisResult(id: String) async throws -> AnalysisResult
    func getAnalysisProgress(_ analysisId: String) async throws -> AnalysisProgress
    func cancelAnalysis(_ analysisId: String) async throws
    func fetchAnalysisHistory(captureId: String) async throws -> [AnalysisResult]
}
