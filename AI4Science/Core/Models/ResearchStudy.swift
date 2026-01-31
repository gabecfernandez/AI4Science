import Foundation

/// ResearchKit study configuration and metadata
public struct ResearchStudy: Identifiable, Codable, Sendable {
    public let id: UUID
    public var projectID: UUID
    public var title: String
    public var description: String
    public var version: String
    public var step: ResearchStudyStep
    public var consentRequired: Bool
    public var activityCount: Int
    public var estimatedCompletionMinutes: Int?
    public var metadata: [String: String]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        projectID: UUID,
        title: String,
        description: String,
        version: String = "1.0",
        step: ResearchStudyStep = .screening,
        consentRequired: Bool = true,
        activityCount: Int = 0,
        estimatedCompletionMinutes: Int? = nil,
        metadata: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.projectID = projectID
        self.title = title
        self.description = description
        self.version = version
        self.step = step
        self.consentRequired = consentRequired
        self.activityCount = activityCount
        self.estimatedCompletionMinutes = estimatedCompletionMinutes
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Study step/phase
@frozen
public enum ResearchStudyStep: String, Codable, Sendable, CaseIterable {
    case screening
    case consent
    case enrollment
    case active
    case completion
    case followUp = "follow_up"
}

// MARK: - Equatable
extension ResearchStudy: Equatable {
    public static func == (lhs: ResearchStudy, rhs: ResearchStudy) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension ResearchStudy: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
