import Foundation

/// Status of a research project
@frozen
public enum ProjectStatus: String, Codable, Sendable, CaseIterable {
    case planning
    case active
    case onHold = "on_hold"
    case completed
    case archived
}

/// Represents a research project
public struct Project: Identifiable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var description: String
    public var status: ProjectStatus
    public var principalInvestigatorID: UUID
    public var labAffiliations: [LabAffiliation]
    public var participantIDs: [UUID]
    public var sampleIDs: [UUID]
    public var startDate: Date
    public var endDate: Date?
    public var metadata: [String: String]
    public var tags: [String]
    public var thumbnailURL: URL?
    public var createdAt: Date
    public var updatedAt: Date

    public nonisolated init(
        id: UUID = UUID(),
        title: String,
        description: String,
        status: ProjectStatus = .planning,
        principalInvestigatorID: UUID,
        labAffiliations: [LabAffiliation] = [],
        participantIDs: [UUID] = [],
        sampleIDs: [UUID] = [],
        startDate: Date = Date(),
        endDate: Date? = nil,
        metadata: [String: String] = [:],
        tags: [String] = [],
        thumbnailURL: URL? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.principalInvestigatorID = principalInvestigatorID
        self.labAffiliations = labAffiliations
        self.participantIDs = participantIDs
        self.sampleIDs = sampleIDs
        self.startDate = startDate
        self.endDate = endDate
        self.metadata = metadata
        self.tags = tags
        self.thumbnailURL = thumbnailURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isActive: Bool {
        status == .active
    }

    public var participantCount: Int {
        participantIDs.count
    }

    public var sampleCount: Int {
        sampleIDs.count
    }
}

// MARK: - Equatable
extension Project: Equatable {
    public static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Project: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
