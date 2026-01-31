import Foundation
import SwiftData

/// Defect classification persistence model for SwiftData
/// Represents detected defects or anomalies in samples
@Model
final class DefectEntity {
    /// Unique identifier for the defect
    @Attribute(.unique) var id: String

    /// Reference to the capture where defect was detected
    var captureID: String

    /// Type of defect (scratch, crack, dent, contamination, etc.)
    var defectType: String

    /// Severity level (low, medium, high, critical)
    var severity: String

    /// Classification confidence (0-1)
    var confidence: Double

    /// Bounding box coordinates (JSON string)
    var boundingBox: String

    /// Detailed description
    var description: String

    /// Detection method (manual, ml_model, hybrid)
    var detectionMethod: String = "manual"

    /// Which ML model detected it (if applicable)
    var modelID: String?

    /// User who created/reviewed the defect
    var createdBy: String?

    /// Creation timestamp
    var createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    /// Whether defect has been reviewed
    var isReviewed: Bool = false

    /// Review notes
    var reviewNotes: String?

    /// Status (detected, verified, resolved, false_positive)
    var status: String = "detected"

    /// Custom metadata
    var metadata: [String: String] = [:]

    /// Relationship to related measurements
    @Relationship(deleteRule: .cascade) var measurements: [DefectMeasurement] = []

    /// Initialization
    init(
        id: String = UUID().uuidString,
        captureID: String,
        defectType: String,
        severity: String = "medium",
        confidence: Double = 0.0,
        boundingBox: String = "{}",
        description: String = "",
        detectionMethod: String = "manual"
    ) {
        self.id = id
        self.captureID = captureID
        self.defectType = defectType
        self.severity = severity
        self.confidence = min(max(confidence, 0.0), 1.0)
        self.boundingBox = boundingBox
        self.description = description
        self.detectionMethod = detectionMethod
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Update defect information
    @MainActor
    func updateInfo(
        defectType: String? = nil,
        severity: String? = nil,
        description: String? = nil,
        confidence: Double? = nil
    ) {
        if let defectType = defectType {
            self.defectType = defectType
        }
        if let severity = severity {
            self.severity = severity
        }
        if let description = description {
            self.description = description
        }
        if let confidence = confidence {
            self.confidence = min(max(confidence, 0.0), 1.0)
        }
        self.updatedAt = Date()
    }

    /// Mark as reviewed
    @MainActor
    func markAsReviewed(notes: String? = nil, status: String? = nil) {
        self.isReviewed = true
        if let notes = notes {
            self.reviewNotes = notes
        }
        if let status = status {
            self.status = status
        }
        self.updatedAt = Date()
    }

    /// Add measurement
    @MainActor
    func addMeasurement(type: String, value: Double, unit: String) {
        let measurement = DefectMeasurement(
            measurementType: type,
            value: value,
            unit: unit
        )
        measurements.append(measurement)
        self.updatedAt = Date()
    }

    /// Get measurement count
    nonisolated var measurementCount: Int {
        measurements.count
    }

    /// Check if high severity
    nonisolated var isHighSeverity: Bool {
        severity == "high" || severity == "critical"
    }
}

/// Defect measurement for detailed analysis
@Model
final class DefectMeasurement {
    var measurementType: String
    var value: Double
    var unit: String
    var precision: Double? // Measurement precision
    var confidence: Double? // Measurement confidence
    var timestamp: Date = Date()

    init(
        measurementType: String,
        value: Double,
        unit: String,
        precision: Double? = nil,
        confidence: Double? = nil
    ) {
        self.measurementType = measurementType
        self.value = value
        self.unit = unit
        self.precision = precision
        self.confidence = confidence
    }
}
