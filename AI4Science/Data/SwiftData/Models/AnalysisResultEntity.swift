import Foundation
import SwiftData

/// Analysis Result persistence model for SwiftData
/// Represents results from running ML models or analysis on captures
@Model
final class AnalysisResultEntity {
    /// Unique identifier for the result
    @Attribute(.unique) var id: String

    /// The capture that was analyzed
    var capture: CaptureEntity?

    /// ID of the ML model used
    var modelID: String

    /// Model name for reference
    var modelName: String

    /// Model version used
    var modelVersion: String

    /// Analysis type
    var analysisType: String

    /// Analysis status
    var status: String = "pending"

    /// Analysis start timestamp
    var startedAt: Date

    /// Analysis completion timestamp
    var completedAt: Date?

    /// Analysis duration in seconds
    var duration: Double?

    /// Main result data (JSON string)
    var resultData: String

    /// Confidence/accuracy score
    var confidenceScore: Double?

    /// Number of objects detected
    var objectCount: Int = 0

    /// Processing notes
    var notes: String?

    /// Error message if analysis failed
    var errorMessage: String?

    /// Analysis parameters used
    var parameters: [String: String] = [:]

    /// Whether result has been reviewed
    var isReviewed: Bool = false

    /// Review notes
    var reviewNotes: String?

    /// Relationship to result artifacts
    @Relationship(deleteRule: .cascade) var artifacts: [ResultArtifact] = []

    /// Relationship to detailed measurements
    @Relationship(deleteRule: .cascade) var measurements: [Measurement] = []

    /// Initialization
    init(
        id: String,
        capture: CaptureEntity? = nil,
        modelID: String,
        modelName: String,
        modelVersion: String,
        analysisType: String,
        resultData: String,
        startedAt: Date = Date()
    ) {
        self.id = id
        self.capture = capture
        self.modelID = modelID
        self.modelName = modelName
        self.modelVersion = modelVersion
        self.analysisType = analysisType
        self.resultData = resultData
        self.startedAt = startedAt
    }

    /// Mark analysis as in progress
    @MainActor
    func markInProgress() {
        self.status = "processing"
    }

    /// Mark analysis as completed
    @MainActor
    func markCompleted(
        resultData: String,
        confidenceScore: Double? = nil,
        objectCount: Int = 0
    ) {
        self.status = "completed"
        self.completedAt = Date()
        self.resultData = resultData
        if let confidenceScore = confidenceScore {
            self.confidenceScore = min(max(confidenceScore, 0.0), 1.0)
        }
        self.objectCount = objectCount
        self.duration = completedAt?.timeIntervalSince(startedAt)
    }

    /// Mark analysis as failed
    @MainActor
    func markFailed(errorMessage: String) {
        self.status = "failed"
        self.completedAt = Date()
        self.errorMessage = errorMessage
        self.duration = completedAt?.timeIntervalSince(startedAt)
    }

    /// Add parameter
    @MainActor
    func addParameter(key: String, value: String) {
        parameters[key] = value
    }

    /// Mark as reviewed
    @MainActor
    func markAsReviewed(notes: String? = nil) {
        self.isReviewed = true
        if let notes = notes {
            self.reviewNotes = notes
        }
    }

    /// Get artifact count
    nonisolated var artifactCount: Int {
        artifacts.count
    }

    /// Get measurement count
    nonisolated var measurementCount: Int {
        measurements.count
    }

    /// Check if result is successful
    nonisolated var isSuccessful: Bool {
        status == "completed"
    }
}

/// Result artifact for storing analysis outputs
@Model
final class ResultArtifact {
    var artifactType: String
    var artifactName: String
    var fileURL: String
    var fileSize: Int64 = 0
    var mimeType: String
    var createdAt: Date = Date()

    init(
        artifactType: String,
        artifactName: String,
        fileURL: String,
        mimeType: String
    ) {
        self.artifactType = artifactType
        self.artifactName = artifactName
        self.fileURL = fileURL
        self.mimeType = mimeType
    }
}

/// Measurement data from analysis
@Model
final class Measurement {
    var measurementType: String
    var label: String
    var value: Double
    var unit: String
    var confidence: Double?
    var metadata: [String: String] = [:]

    init(
        measurementType: String,
        label: String,
        value: Double,
        unit: String,
        confidence: Double? = nil
    ) {
        self.measurementType = measurementType
        self.label = label
        self.value = value
        self.unit = unit
        self.confidence = confidence
    }
}
