import Foundation
import CoreGraphics

// MARK: - AnnotationType

@frozen
public enum AnnotationType: String, Codable, Sendable, CaseIterable {
    case point
    case rectangle
    case polygon
    case freeform
}

// MARK: - Geometry

public enum Geometry: Codable, Sendable {
    case point(CGPoint)
    case rectangle(CGRect)
    case polygon([CGPoint])
    case freeform([CGPoint])

    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case type, pointX, pointY, rectX, rectY, rectW, rectH, points
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .point(let p):
            try c.encode("point", forKey: .type)
            try c.encode(p.x, forKey: .pointX)
            try c.encode(p.y, forKey: .pointY)
        case .rectangle(let r):
            try c.encode("rectangle", forKey: .type)
            try c.encode(r.origin.x, forKey: .rectX)
            try c.encode(r.origin.y, forKey: .rectY)
            try c.encode(r.size.width, forKey: .rectW)
            try c.encode(r.size.height, forKey: .rectH)
        case .polygon(let pts):
            try c.encode("polygon", forKey: .type)
            try c.encode(pts.map { [$0.x, $0.y] }, forKey: .points)
        case .freeform(let pts):
            try c.encode("freeform", forKey: .type)
            try c.encode(pts.map { [$0.x, $0.y] }, forKey: .points)
        }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "point":
            let x = try c.decode(Double.self, forKey: .pointX)
            let y = try c.decode(Double.self, forKey: .pointY)
            self = .point(CGPoint(x: x, y: y))
        case "rectangle":
            let x = try c.decode(Double.self, forKey: .rectX)
            let y = try c.decode(Double.self, forKey: .rectY)
            let w = try c.decode(Double.self, forKey: .rectW)
            let h = try c.decode(Double.self, forKey: .rectH)
            self = .rectangle(CGRect(x: x, y: y, width: w, height: h))
        case "polygon":
            let raw = try c.decode([[Double]].self, forKey: .points)
            self = .polygon(raw.map { CGPoint(x: $0[0], y: $0[1]) })
        case "freeform":
            let raw = try c.decode([[Double]].self, forKey: .points)
            self = .freeform(raw.map { CGPoint(x: $0[0], y: $0[1]) })
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Unknown geometry type: \(type)")
            )
        }
    }
}

// MARK: - DefectCategory

public enum DefectCategory: String, Codable, Sendable {
    case structural
    case contamination
    case surface
}

// MARK: - Annotation

public struct Annotation: Identifiable, Codable, Sendable {
    public let id: UUID
    public let captureId: UUID
    public let type: AnnotationType
    public let geometry: Geometry
    public let label: String
    public let defectType: DefectType
    public let severity: DefectSeverity
    public let confidence: Double
    public let createdAt: Date
    public let createdBy: UUID

    public init(
        id: UUID = UUID(),
        captureId: UUID,
        type: AnnotationType,
        geometry: Geometry,
        label: String,
        defectType: DefectType,
        severity: DefectSeverity,
        confidence: Double,
        createdAt: Date = Date(),
        createdBy: UUID
    ) {
        self.id = id
        self.captureId = captureId
        self.type = type
        self.geometry = geometry
        self.label = label
        self.defectType = defectType
        self.severity = severity
        self.confidence = confidence
        self.createdAt = createdAt
        self.createdBy = createdBy
    }

    /// Bounding box that encloses the annotation geometry.
    public var boundingBox: CGRect {
        switch geometry {
        case .point(let p):
            return CGRect(x: p.x, y: p.y, width: 0, height: 0)
        case .rectangle(let r):
            return r
        case .polygon(let pts), .freeform(let pts):
            guard !pts.isEmpty else { return .zero }
            let minX = pts.min(by: { $0.x < $1.x })!.x
            let minY = pts.min(by: { $0.y < $1.y })!.y
            let maxX = pts.max(by: { $0.x < $1.x })!.x
            let maxY = pts.max(by: { $0.y < $1.y })!.y
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
    }

    /// Area of the annotation in pixels (for rectangles only; polygons approximate via bounding box).
    public var area: Double {
        switch geometry {
        case .rectangle(let r):
            return r.width * r.height
        default:
            return boundingBox.width * boundingBox.height
        }
    }
}

extension Annotation: Equatable {
    public static func == (lhs: Annotation, rhs: Annotation) -> Bool {
        lhs.id == rhs.id
    }
}

extension Annotation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
