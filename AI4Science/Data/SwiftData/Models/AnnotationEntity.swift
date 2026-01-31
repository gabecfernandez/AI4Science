import Foundation
import SwiftData

/// Annotation persistence model for SwiftData
/// Represents annotations or markups on captures
@Model
final class AnnotationEntity {
    /// Unique identifier for the annotation
    @Attribute(.unique) var id: String

    /// The capture this annotation belongs to
    var capture: CaptureEntity?

    /// Annotation type (region, polygon, point, measurement, etc.)
    var annotationType: String

    /// Annotation content/data
    var content: String

    /// Annotation coordinates (JSON string for flexibility)
    var coordinates: String

    /// Creator of the annotation
    var createdBy: String

    /// Creation timestamp
    var createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    /// Label for the annotation
    var label: String?

    /// Confidence score for automated annotations
    var confidenceScore: Double?

    /// Color for visualization
    var color: String = "#FF0000"

    /// Whether annotation is visible
    var isVisible: Bool = true

    /// Annotation metadata
    var metadata: [String: String] = [:]

    /// Relationship to related annotation items
    @Relationship(deleteRule: .cascade) var items: [AnnotationItem] = []

    /// Initialization
    init(
        id: String,
        capture: CaptureEntity? = nil,
        annotationType: String,
        content: String,
        coordinates: String,
        createdBy: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.capture = capture
        self.annotationType = annotationType
        self.content = content
        self.coordinates = coordinates
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Update annotation
    @MainActor
    func updateAnnotation(
        content: String? = nil,
        coordinates: String? = nil,
        label: String? = nil,
        confidenceScore: Double? = nil
    ) {
        if let content = content {
            self.content = content
        }
        if let coordinates = coordinates {
            self.coordinates = coordinates
        }
        if let label = label {
            self.label = label
        }
        if let confidenceScore = confidenceScore {
            self.confidenceScore = min(max(confidenceScore, 0.0), 1.0)
        }
        self.updatedAt = Date()
    }

    /// Toggle visibility
    @MainActor
    func toggleVisibility() {
        self.isVisible.toggle()
        self.updatedAt = Date()
    }

    /// Set color
    @MainActor
    func setColor(_ color: String) {
        self.color = color
        self.updatedAt = Date()
    }

    /// Add metadata
    @MainActor
    func addMetadata(key: String, value: String) {
        metadata[key] = value
        updatedAt = Date()
    }

    /// Get item count
    nonisolated var itemCount: Int {
        items.count
    }
}

/// Annotation item for detailed annotation information
@Model
final class AnnotationItem {
    var itemType: String
    var itemValue: String
    var position: Int = 0
    var metadata: [String: String] = [:]

    init(
        itemType: String,
        itemValue: String,
        position: Int = 0
    ) {
        self.itemType = itemType
        self.itemValue = itemValue
        self.position = position
    }
}
