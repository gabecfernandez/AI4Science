import Foundation
import SwiftData

/// Capture persistence model for SwiftData
/// Represents a capture event (image, video, scan, etc.) of a sample
@Model
final class CaptureEntity {
    /// Unique identifier for the capture
    @Attribute(.unique) var id: String

    /// The sample this capture belongs to
    var sample: SampleEntity?

    /// Capture type (image, video, scan, microscopy, etc.)
    var captureType: String

    /// File URL or path to the captured data
    var fileURL: String

    /// File size in bytes
    var fileSize: Int64 = 0

    /// MIME type
    var mimeType: String

    /// Capture timestamp
    var capturedAt: Date

    /// Creation timestamp
    var createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    /// Capture device information
    var deviceInfo: String?

    /// Camera settings (if applicable)
    var cameraSettings: [String: String] = [:]

    /// Processing status
    var processingStatus: String = "pending"

    /// Quality score (0-1)
    var qualityScore: Double?

    /// User notes
    var notes: String?

    /// Whether capture has been processed/analyzed
    var isProcessed: Bool = false

    /// Relationship to annotations
    @Relationship(deleteRule: .cascade, inverse: \AnnotationEntity.capture) var annotations: [AnnotationEntity] = []

    /// Relationship to analysis results
    @Relationship(deleteRule: .cascade, inverse: \AnalysisResultEntity.capture) var analysisResults: [AnalysisResultEntity] = []

    /// Relationship to capture metadata
    @Relationship(deleteRule: .cascade) var captureMetadata: CaptureMetadataEntity?

    /// Initialization
    init(
        id: String,
        sample: SampleEntity? = nil,
        captureType: String,
        fileURL: String,
        mimeType: String,
        capturedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.sample = sample
        self.captureType = captureType
        self.fileURL = fileURL
        self.mimeType = mimeType
        self.capturedAt = capturedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Update capture information
    @MainActor
    func updateInfo(
        notes: String? = nil,
        qualityScore: Double? = nil
    ) {
        if let notes = notes {
            self.notes = notes
        }
        if let qualityScore = qualityScore {
            self.qualityScore = min(max(qualityScore, 0.0), 1.0)
        }
        self.updatedAt = Date()
    }

    /// Set processing status
    @MainActor
    func setProcessingStatus(_ status: String) {
        self.processingStatus = status
        self.updatedAt = Date()
    }

    /// Mark as processed
    @MainActor
    func markAsProcessed() {
        self.isProcessed = true
        self.processingStatus = "completed"
        self.updatedAt = Date()
    }

    /// Add camera setting
    @MainActor
    func addCameraSetting(key: String, value: String) {
        cameraSettings[key] = value
        updatedAt = Date()
    }

    /// Get number of annotations
    nonisolated var annotationCount: Int {
        annotations.count
    }

    /// Get number of analysis results
    nonisolated var analysisResultCount: Int {
        analysisResults.count
    }

    /// Check if capture is ready for analysis
    nonisolated var isReadyForAnalysis: Bool {
        !fileURL.isEmpty && fileSize != 0
    }
}

/// Capture metadata entity for SwiftData persistence
@Model
final class CaptureMetadataEntity {
    var resolution: String?
    var bitDepth: Int?
    var colorSpace: String?
    var exposureTime: Double?
    var gain: Double?
    var illumination: String?
    var magnification: String?
    var customMetadata: [String: String] = [:]

    init(
        resolution: String? = nil,
        bitDepth: Int? = nil,
        colorSpace: String? = nil
    ) {
        self.resolution = resolution
        self.bitDepth = bitDepth
        self.colorSpace = colorSpace
    }
}
