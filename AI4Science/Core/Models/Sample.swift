import Foundation

/// Material composition type
@frozen
public enum MaterialType: String, Codable, Sendable, CaseIterable {
    case metal
    case ceramic
    case polymer
    case composite
    case semiconductor
    case glass
    case other
}

/// Represents a physical material sample being analyzed
public struct Sample: Identifiable, Codable, Sendable {
    public let id: UUID
    public var projectID: UUID
    public var name: String
    public var description: String?
    public var materialType: MaterialType
    public var batchNumber: String?
    public var manufacturingDate: Date?
    public var sampleLocation: String?
    public var metadata: [String: String]
    public var captureIDs: [UUID]
    public var analysisResultIDs: [UUID]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        projectID: UUID,
        name: String,
        description: String? = nil,
        materialType: MaterialType,
        batchNumber: String? = nil,
        manufacturingDate: Date? = nil,
        sampleLocation: String? = nil,
        metadata: [String: String] = [:],
        captureIDs: [UUID] = [],
        analysisResultIDs: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.projectID = projectID
        self.name = name
        self.description = description
        self.materialType = materialType
        self.batchNumber = batchNumber
        self.manufacturingDate = manufacturingDate
        self.sampleLocation = sampleLocation
        self.metadata = metadata
        self.captureIDs = captureIDs
        self.analysisResultIDs = analysisResultIDs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var captureCount: Int {
        captureIDs.count
    }

    public var analysisCount: Int {
        analysisResultIDs.count
    }
}

// MARK: - Equatable
extension Sample: Equatable {
    public static func == (lhs: Sample, rhs: Sample) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Sample: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
