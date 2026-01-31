import Foundation

/// Defect severity level
@frozen
public enum DefectSeverity: String, Codable, Sendable, CaseIterable {
    case critical
    case high
    case medium
    case low
    case negligible
}

/// Defect type classification
@frozen
public enum DefectType: String, Codable, Sendable, CaseIterable {
    case crack
    case corrosion
    case delamination
    case oxidation
    case contamination
    case fatigue
    case porosity
    case scratch
    case dent
    case discoloration
    case unknown
}

/// Represents a detected defect with classification and metadata
public struct Defect: Identifiable, Codable, Sendable {
    public let id: UUID
    public var analysisResultID: UUID
    public var type: DefectType
    public var severity: DefectSeverity
    public var confidence: Double
    public var area: Double? // in square millimeters or normalized units
    public var depth: Double? // in millimeters
    public var location: String?
    public var annotations: [UUID]
    public var metadata: [String: String]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        analysisResultID: UUID,
        type: DefectType,
        severity: DefectSeverity,
        confidence: Double,
        area: Double? = nil,
        depth: Double? = nil,
        location: String? = nil,
        annotations: [UUID] = [],
        metadata: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.analysisResultID = analysisResultID
        self.type = type
        self.severity = severity
        self.confidence = max(0, min(1, confidence))
        self.area = area
        self.depth = depth
        self.location = location
        self.annotations = annotations
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isCritical: Bool {
        severity == .critical
    }

    public var isHighSeverity: Bool {
        severity == .critical || severity == .high
    }

    public var confidencePercentage: Double {
        confidence * 100
    }
}

// MARK: - Equatable
extension Defect: Equatable {
    public static func == (lhs: Defect, rhs: Defect) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Defect: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
