import Foundation

/// Mapper for converting between Annotation domain models and persistence models
struct AnnotationMapper {
    /// Map AnnotationEntity to domain Annotation model
    static func toModel(_ entity: AnnotationEntity) -> Annotation {
        Annotation(
            id: entity.id,
            annotationType: entity.annotationType,
            content: entity.content,
            coordinates: entity.coordinates,
            createdBy: entity.createdBy,
            label: entity.label,
            confidenceScore: entity.confidenceScore,
            color: entity.color,
            isVisible: entity.isVisible,
            metadata: entity.metadata,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }

    /// Map domain Annotation model to AnnotationEntity
    static func toEntity(from annotation: Annotation) -> AnnotationEntity {
        AnnotationEntity(
            id: annotation.id,
            annotationType: annotation.annotationType,
            content: annotation.content,
            coordinates: annotation.coordinates,
            createdBy: annotation.createdBy,
            createdAt: annotation.createdAt,
            updatedAt: annotation.updatedAt
        )
    }

    /// Update AnnotationEntity from domain Annotation
    static func update(_ entity: AnnotationEntity, with annotation: Annotation) {
        entity.content = annotation.content
        entity.coordinates = annotation.coordinates
        entity.label = annotation.label
        entity.confidenceScore = annotation.confidenceScore
        entity.color = annotation.color
        entity.isVisible = annotation.isVisible
        entity.metadata = annotation.metadata
        entity.updatedAt = annotation.updatedAt
    }

    /// Parse coordinates string to coordinates array
    static func parseCoordinates(_ coordinatesString: String) -> [[Double]] {
        guard let data = coordinatesString.data(using: .utf8),
              let array = try? JSONDecoder().decode([[Double]].self, from: data) else {
            return []
        }
        return array
    }

    /// Serialize coordinates array to string
    static func serializeCoordinates(_ coordinates: [[Double]]) -> String {
        guard let data = try? JSONEncoder().encode(coordinates),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }
}

/// Domain Annotation model
struct Annotation: Codable, Identifiable {
    let id: String
    let annotationType: String
    var content: String
    var coordinates: String
    let createdBy: String
    var label: String?
    var confidenceScore: Double?
    var color: String
    var isVisible: Bool
    var metadata: [String: String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        annotationType: String,
        content: String,
        coordinates: String,
        createdBy: String,
        label: String? = nil,
        confidenceScore: Double? = nil,
        color: String = "#FF0000",
        isVisible: Bool = true,
        metadata: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.annotationType = annotationType
        self.content = content
        self.coordinates = coordinates
        self.createdBy = createdBy
        self.label = label
        self.confidenceScore = confidenceScore
        self.color = color
        self.isVisible = isVisible
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var isRegion: Bool {
        annotationType == "region"
    }

    var isPoint: Bool {
        annotationType == "point"
    }

    var isPolygon: Bool {
        annotationType == "polygon"
    }

    var isMeasurement: Bool {
        annotationType == "measurement"
    }

    var isHighConfidence: Bool {
        guard let score = confidenceScore else { return false }
        return score > 0.8
    }

    var parsedCoordinates: [[Double]] {
        AnnotationMapper.parseCoordinates(coordinates)
    }

    mutating func updateCoordinates(_ newCoordinates: [[Double]]) {
        coordinates = AnnotationMapper.serializeCoordinates(newCoordinates)
        updatedAt = Date()
    }

    mutating func setColor(_ color: String) {
        self.color = color
        updatedAt = Date()
    }

    mutating func toggleVisibility() {
        isVisible.toggle()
        updatedAt = Date()
    }

    mutating func setLabel(_ label: String) {
        self.label = label
        updatedAt = Date()
    }

    mutating func setConfidenceScore(_ score: Double) {
        confidenceScore = min(max(score, 0.0), 1.0)
        updatedAt = Date()
    }

    mutating func addMetadata(key: String, value: String) {
        metadata[key] = value
        updatedAt = Date()
    }
}

/// Annotation type definitions
enum AnnotationType: String, Codable {
    case region = "region"
    case point = "point"
    case polygon = "polygon"
    case measurement = "measurement"
    case freehand = "freehand"
    case arrow = "arrow"
    case text = "text"
}
