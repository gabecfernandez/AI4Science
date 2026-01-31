import Foundation

// MARK: - ProjectStatus

public enum ProjectStatus: String, Codable, Sendable, CaseIterable {
    case draft
    case active
    case paused
    case completed
    case archived

    public var displayName: String {
        switch self {
        case .draft:      return "Draft"
        case .active:     return "Active"
        case .paused:     return "Paused"
        case .completed:  return "Completed"
        case .archived:   return "Archived"
        }
    }
}

// MARK: - Project

public struct Project: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var description: String
    public var ownerId: UUID
    public var status: ProjectStatus
    public var sampleIds: [UUID]
    public var collaboratorIds: [UUID]
    public var createdAt: Date
    public var updatedAt: Date

    public nonisolated init(
        id: UUID = UUID(),
        name: String,
        description: String,
        ownerId: UUID,
        status: ProjectStatus = .draft,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sampleIds: [UUID] = [],
        collaboratorIds: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.ownerId = ownerId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sampleIds = sampleIds
        self.collaboratorIds = collaboratorIds
    }

    // MARK: - Computed Properties

    public var sampleCount: Int {
        sampleIds.count
    }

    public nonisolated var isArchived: Bool {
        status == .archived
    }

    public func isCollaborator(userId: UUID) -> Bool {
        collaboratorIds.contains(userId)
    }

    // MARK: - Status Transitions

    public func canTransitionTo(_ target: ProjectStatus) -> Bool {
        switch status {
        case .draft:
            return target == .active
        case .active:
            return target == .paused || target == .completed || target == .archived
        case .paused:
            return target == .active || target == .archived
        case .completed:
            return target == .archived
        case .archived:
            return false
        }
    }
}

// MARK: - Equatable (by id only)

extension Project: Equatable {
    public static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable (by id only)

extension Project: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
