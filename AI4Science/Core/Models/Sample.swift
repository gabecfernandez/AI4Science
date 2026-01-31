import Foundation

// MARK: - SampleStatus

@frozen
public enum SampleStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case inProgress
    case analyzed
    case reviewed
    case archived
}

// MARK: - Sample

public struct Sample: Identifiable, Codable, Sendable {
    public let id: UUID
    public let projectId: UUID
    public let name: String
    public var description: String
    public var materialType: String
    public var status: SampleStatus
    public let createdAt: Date
    public let createdBy: UUID

    public init(
        id: UUID = UUID(),
        projectId: UUID,
        name: String,
        description: String = "",
        materialType: String = "",
        status: SampleStatus = .pending,
        createdAt: Date = Date(),
        createdBy: UUID
    ) {
        self.id = id
        self.projectId = projectId
        self.name = name
        self.description = description
        self.materialType = materialType
        self.status = status
        self.createdAt = createdAt
        self.createdBy = createdBy
    }
}

extension Sample: Equatable {
    public static func == (lhs: Sample, rhs: Sample) -> Bool {
        lhs.id == rhs.id
    }
}

extension Sample: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
