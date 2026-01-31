import Foundation

/// Analysis status
@frozen
public enum AnalysisStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case processing
    case completed
    case failed
    case cancelled
}

/// Contains predictions from a single class
public struct ClassPrediction: Codable, Sendable {
    public var className: String
    public var confidence: Double
    public var probability: Double?

    public init(className: String, confidence: Double, probability: Double? = nil) {
        self.className = className
        self.confidence = max(0, min(1, confidence))
        self.probability = probability.map { max(0, min(1, $0)) }
    }
}

/// Results of ML model inference on a capture
public struct AnalysisResult: Identifiable, Codable, Sendable {
    public let id: UUID
    public var captureID: UUID
    public var projectID: UUID
    public var sampleID: UUID
    public var mlModelID: UUID
    public var status: AnalysisStatus
    public var predictions: [ClassPrediction]
    public var defectIDs: [UUID]
    public var confidenceScore: Double
    public var inferenceTimeMillis: Int64
    public var processingStartedAt: Date?
    public var processingCompletedAt: Date?
    public var errorMessage: String?
    public var warnings: [String]
    public var metadata: [String: String]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        captureID: UUID,
        projectID: UUID,
        sampleID: UUID,
        mlModelID: UUID,
        status: AnalysisStatus = .pending,
        predictions: [ClassPrediction] = [],
        defectIDs: [UUID] = [],
        confidenceScore: Double = 0,
        inferenceTimeMillis: Int64 = 0,
        processingStartedAt: Date? = nil,
        processingCompletedAt: Date? = nil,
        errorMessage: String? = nil,
        warnings: [String] = [],
        metadata: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.captureID = captureID
        self.projectID = projectID
        self.sampleID = sampleID
        self.mlModelID = mlModelID
        self.status = status
        self.predictions = predictions
        self.defectIDs = defectIDs
        self.confidenceScore = max(0, min(1, confidenceScore))
        self.inferenceTimeMillis = inferenceTimeMillis
        self.processingStartedAt = processingStartedAt
        self.processingCompletedAt = processingCompletedAt
        self.errorMessage = errorMessage
        self.warnings = warnings
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isProcessing: Bool {
        status == .processing
    }

    public var isComplete: Bool {
        status == .completed
    }

    public var hasFailed: Bool {
        status == .failed
    }

    public var confidencePercentage: Double {
        confidenceScore * 100
    }

    public var topPrediction: ClassPrediction? {
        predictions.max { $0.confidence < $1.confidence }
    }

    public var defectCount: Int {
        defectIDs.count
    }

    public var processingDuration: TimeInterval? {
        guard let started = processingStartedAt,
              let completed = processingCompletedAt else {
            return nil
        }
        return completed.timeIntervalSince(started)
    }
}

// MARK: - Equatable
extension AnalysisResult: Equatable {
    public static func == (lhs: AnalysisResult, rhs: AnalysisResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension AnalysisResult: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension ClassPrediction: Equatable, Hashable {}
