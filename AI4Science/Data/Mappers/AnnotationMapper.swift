import Foundation
import CoreGraphics

/// Mapper for converting between Annotation domain models and persistence models
struct AnnotationMapper {
    /// Map AnnotationEntity to domain Annotation model
    static func toModel(_ entity: AnnotationEntity) -> Annotation {
        let captureId = UUID(uuidString: entity.capture?.id ?? "") ?? UUID()
        let type = AnnotationType(rawValue: entity.annotationType) ?? .point
        let geometry = parseGeometry(type: type, coordinates: entity.coordinates)
        let defectType = DefectType(rawValue: entity.content) ?? .unknown
        let severity = DefectSeverity(rawValue: entity.label ?? "low") ?? .low
        let confidence = entity.confidenceScore ?? 0.0
        let createdBy = UUID(uuidString: entity.createdBy) ?? UUID()
        let id = UUID(uuidString: entity.id) ?? UUID()

        return Annotation(
            id: id,
            captureId: captureId,
            type: type,
            geometry: geometry,
            label: entity.label ?? "",
            defectType: defectType,
            severity: severity,
            confidence: confidence,
            createdAt: entity.createdAt,
            createdBy: createdBy
        )
    }

    /// Map domain Annotation model to AnnotationEntity
    static func toEntity(from annotation: Annotation) -> AnnotationEntity {
        AnnotationEntity(
            id: annotation.id.uuidString,
            annotationType: annotation.type.rawValue,
            content: annotation.defectType.rawValue,
            coordinates: serializeGeometry(annotation.geometry),
            createdBy: annotation.createdBy.uuidString,
            createdAt: annotation.createdAt,
            updatedAt: annotation.createdAt
        )
    }

    /// Update AnnotationEntity from domain Annotation
    static func update(_ entity: AnnotationEntity, with annotation: Annotation) {
        entity.content = annotation.defectType.rawValue
        entity.coordinates = serializeGeometry(annotation.geometry)
        entity.label = annotation.label
        entity.confidenceScore = annotation.confidence
        entity.updatedAt = Date()
    }

    // MARK: - Geometry Serialization

    private static func parseGeometry(type: AnnotationType, coordinates: String) -> Geometry {
        guard let data = coordinates.data(using: .utf8),
              let array = try? JSONDecoder().decode([[Double]].self, from: data),
              !array.isEmpty else {
            return .point(.zero)
        }

        switch type {
        case .point:
            guard array[0].count >= 2 else { return .point(.zero) }
            return .point(CGPoint(x: array[0][0], y: array[0][1]))
        case .rectangle:
            guard array[0].count >= 4 else { return .rectangle(.zero) }
            return .rectangle(CGRect(x: array[0][0], y: array[0][1],
                                     width: array[0][2], height: array[0][3]))
        case .polygon:
            let points = array.compactMap { $0.count >= 2 ? CGPoint(x: $0[0], y: $0[1]) : nil }
            return .polygon(points)
        case .freeform:
            let points = array.compactMap { $0.count >= 2 ? CGPoint(x: $0[0], y: $0[1]) : nil }
            return .freeform(points)
        }
    }

    private static func serializeGeometry(_ geometry: Geometry) -> String {
        let array: [[Double]]
        switch geometry {
        case .point(let p):
            array = [[p.x, p.y]]
        case .rectangle(let r):
            array = [[r.origin.x, r.origin.y, r.size.width, r.size.height]]
        case .polygon(let pts), .freeform(let pts):
            array = pts.map { [$0.x, $0.y] }
        }
        guard let data = try? JSONEncoder().encode(array),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }
}
