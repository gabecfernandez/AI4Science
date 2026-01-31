import Foundation
import SwiftData

/// Sample persistence model for SwiftData
/// Represents a physical or digital sample in a project
@Model
final class SampleEntity {
    /// Unique identifier for the sample
    @Attribute(.unique) var id: String

    /// Sample name
    var name: String

    /// Sample description
    var description: String

    /// The project this sample belongs to
    var project: ProjectEntity?

    /// Sample type (tissue, liquid, etc.)
    var sampleType: String

    /// Sample source/origin
    var source: String?

    /// Collection date
    var collectionDate: Date

    /// Creation timestamp
    var createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    /// Storage location
    var storageLocation: String?

    /// Physical or digital identifier
    var externalID: String?

    /// Sample status
    var status: String = "active"

    /// User notes about the sample
    var notes: String?

    /// Sample metadata (dimensions, weight, etc.)
    var metadata: [String: String] = [:]

    /// Whether sample is flagged for review
    var isFlagged: Bool = false

    /// Relationship to captures
    @Relationship(deleteRule: .cascade, inverse: \CaptureEntity.sample) var captures: [CaptureEntity] = []

    /// Relationship to sample properties
    @Relationship(deleteRule: .cascade) var properties: SampleProperties?

    /// Initialization
    init(
        id: String,
        name: String,
        description: String,
        project: ProjectEntity? = nil,
        sampleType: String,
        source: String? = nil,
        collectionDate: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.project = project
        self.sampleType = sampleType
        self.source = source
        self.collectionDate = collectionDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Update sample information
    @MainActor
    func updateInfo(
        name: String? = nil,
        description: String? = nil,
        source: String? = nil,
        notes: String? = nil
    ) {
        if let name = name {
            self.name = name
        }
        if let description = description {
            self.description = description
        }
        if let source = source {
            self.source = source
        }
        if let notes = notes {
            self.notes = notes
        }
        self.updatedAt = Date()
    }

    /// Add metadata key-value pair
    @MainActor
    func addMetadata(key: String, value: String) {
        metadata[key] = value
        updatedAt = Date()
    }

    /// Remove metadata by key
    @MainActor
    func removeMetadata(key: String) {
        metadata.removeValue(forKey: key)
        updatedAt = Date()
    }

    /// Flag the sample for review
    @MainActor
    func flag() {
        isFlagged = true
        updatedAt = Date()
    }

    /// Unflag the sample
    @MainActor
    func unflag() {
        isFlagged = false
        updatedAt = Date()
    }

    /// Get number of captures
    nonisolated var captureCount: Int {
        captures.count
    }
}

/// Sample properties for detailed information
@Model
final class SampleProperties {
    var weight: Double?
    var weightUnit: String = "mg"
    var volume: Double?
    var volumeUnit: String = "µL"
    var concentration: Double?
    var concentrationUnit: String = "mg/mL"
    var purity: Double?
    var customProperties: [String: String] = [:]

    init(
        weight: Double? = nil,
        volume: Double? = nil,
        concentration: Double? = nil,
        purity: Double? = nil
    ) {
        self.weight = weight
        self.volume = volume
        self.concentration = concentration
        self.purity = purity
    }
}
