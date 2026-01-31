import Foundation

/// Annotation geometry type
@frozen
public enum AnnotationGeometry: Codable, Sendable {
    case point(Point)
    case rectangle(Rectangle)
    case polygon(Polygon)

    public enum CodingKeys: String, CodingKey {
        case type
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "point":
            let point = try container.decode(Point.self, forKey: .data)
            self = .point(point)
        case "rectangle":
            let rect = try container.decode(Rectangle.self, forKey: .data)
            self = .rectangle(rect)
        case "polygon":
            let poly = try container.decode(Polygon.self, forKey: .data)
            self = .polygon(poly)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid geometry type: \(type)"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .point(let point):
            try container.encode("point", forKey: .type)
            try container.encode(point, forKey: .data)
        case .rectangle(let rect):
            try container.encode("rectangle", forKey: .type)
            try container.encode(rect, forKey: .data)
        case .polygon(let poly):
            try container.encode("polygon", forKey: .type)
            try container.encode(poly, forKey: .data)
        }
    }
}

/// 2D point in normalized coordinates (0.0 - 1.0)
public struct Point: Codable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// Rectangle in normalized coordinates
public struct Rectangle: Codable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var minX: Double { x }
    public var minY: Double { y }
    public var maxX: Double { x + width }
    public var maxY: Double { y + height }

    public var centerX: Double { x + (width / 2) }
    public var centerY: Double { y + (height / 2) }

    public var area: Double { width * height }
}

/// Polygon defined by vertices in normalized coordinates
public struct Polygon: Codable, Sendable {
    public var vertices: [Point]

    public init(vertices: [Point]) {
        self.vertices = vertices
    }

    public var vertexCount: Int {
        vertices.count
    }

    public var isClosed: Bool {
        vertices.count >= 3
    }
}

/// Annotation of a defect on a capture
public struct Annotation: Identifiable, Codable, Sendable {
    public let id: UUID
    public var captureID: UUID
    public var geometry: AnnotationGeometry
    public var label: String
    public var confidence: Double?
    public var annotatorID: UUID?
    public var notes: String?
    public var isAutomatic: Bool
    public var metadata: [String: String]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        captureID: UUID,
        geometry: AnnotationGeometry,
        label: String,
        confidence: Double? = nil,
        annotatorID: UUID? = nil,
        notes: String? = nil,
        isAutomatic: Bool = false,
        metadata: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.captureID = captureID
        self.geometry = geometry
        self.label = label
        self.confidence = confidence
        self.annotatorID = annotatorID
        self.notes = notes
        self.isAutomatic = isAutomatic
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Equatable
extension Annotation: Equatable {
    public static func == (lhs: Annotation, rhs: Annotation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Annotation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Point: Equatable, Hashable {}
extension Rectangle: Equatable, Hashable {}
extension Polygon: Equatable, Hashable {}
