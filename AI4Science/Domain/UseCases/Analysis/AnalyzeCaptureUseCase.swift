import Foundation
import CoreGraphics

// MARK: - Request / Options

public struct AnalyzeCaptureRequest: Sendable {
    public let captureId: UUID
    public let modelType: MLModelType
    public let options: AnalysisOptions

    public init(captureId: UUID, modelType: MLModelType, options: AnalysisOptions) {
        self.captureId = captureId
        self.modelType = modelType
        self.options = options
    }
}

public struct AnalysisOptions: Sendable {
    public let confidenceThreshold: Double
    public let maxDetections: Int

    public init(confidenceThreshold: Double = 0.5, maxDetections: Int = 50) {
        self.confidenceThreshold = confidenceThreshold
        self.maxDetections = maxDetections
    }
}

// MARK: - ML Inference Service Protocol

public protocol MLInferenceServiceProtocol: Sendable {
    associatedtype DetectionResult: Sendable
    func runInference(on imageURL: URL, modelType: MLModelType) async throws -> [DetectionResult]
}

// MARK: - Analysis Result Saver Protocol

/// Protocol for repositories that can save analysis pipeline results.
/// Conforming types convert AnalysisPipelineResult into their own storage type.
public protocol AnalysisResultSaver: Sendable {
    func saveAnalysisResult(_ result: AnalysisPipelineResult) async throws
}

// MARK: - AnalyzeCaptureUseCase

/// Use case for running ML analysis on a capture.
/// Uses closure-based dependency injection for both ML inference and result persistence.
public actor AnalyzeCaptureUseCase: Sendable {
    private let _runInference: @Sendable (URL, MLModelType) async throws -> [Any]
    private let _save: @Sendable (AnalysisPipelineResult) async throws -> Void

    /// Generic init: accepts any MLInferenceServiceProtocol and any AnalysisResultSaver.
    public init<MLSvc: MLInferenceServiceProtocol, Repo: AnalysisResultSaver>(
        mlService: MLSvc, repository: Repo
    ) {
        self._runInference = { url, modelType in
            let results = try await mlService.runInference(on: url, modelType: modelType)
            return results as [Any]
        }
        self._save = { result in
            try await repository.saveAnalysisResult(result)
        }
    }

    public func execute(_ request: AnalyzeCaptureRequest) async throws -> AnalysisPipelineResult {
        let allDetections = try await _runInference(
            URL(fileURLWithPath: "/captures/\(request.captureId)"),
            request.modelType
        )

        let filtered = allDetections.filter { item in
            extractConfidence(from: item) >= request.options.confidenceThreshold
        }

        let limited = Array(filtered.prefix(request.options.maxDetections))

        let result = AnalysisPipelineResult(
            id: UUID(),
            captureId: request.captureId,
            modelType: request.modelType.rawValue,
            modelVersion: "1.0.0",
            detections: limited,
            processingTime: 0.1,
            createdAt: Date()
        )

        try await _save(result)

        return result
    }
}

// MARK: - Pipeline Result

/// Result returned by AnalyzeCaptureUseCase.execute().
/// detections contains type-erased detection structs.
public struct AnalysisPipelineResult: @unchecked Sendable {
    public let id: UUID
    public let captureId: UUID
    public let modelType: String
    public let modelVersion: String
    public let detections: [Any]
    public let processingTime: TimeInterval
    public let createdAt: Date

    public init(
        id: UUID, captureId: UUID, modelType: String, modelVersion: String,
        detections: [Any], processingTime: TimeInterval, createdAt: Date
    ) {
        self.id = id
        self.captureId = captureId
        self.modelType = modelType
        self.modelVersion = modelVersion
        self.detections = detections
        self.processingTime = processingTime
        self.createdAt = createdAt
    }
}

// MARK: - Helpers

private func extractConfidence(from item: Any) -> Double {
    let mirror = Mirror(reflecting: item)
    for child in mirror.children where child.label == "confidence" {
        if let value = child.value as? Double { return value }
    }
    return 0
}
