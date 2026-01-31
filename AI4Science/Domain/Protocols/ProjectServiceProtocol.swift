import Foundation

/// Domain-level project service protocol
@available(iOS 15.0, *)
public protocol ProjectServiceProtocol: Sendable {
    /// Create new research project
    func createProject(_ request: CreateProjectRequest) async throws -> Project

    /// Fetch all user projects
    func fetchProjects(userId: String) async throws -> [Project]

    /// Fetch specific project
    func fetchProject(projectId: String) async throws -> Project

    /// Update project details
    func updateProject(_ request: UpdateProjectRequest) async throws -> Project

    /// Delete project
    func deleteProject(projectId: String) async throws

    /// Share project with collaborators
    func shareProject(projectId: String, with emails: [String], permission: ProjectPermission) async throws

    /// Remove collaborator from project
    func removeCollaborator(projectId: String, email: String) async throws

    /// Export project data
    func exportProject(projectId: String, format: ExportFormat) async throws -> Data
}

/// Project domain model
public struct Project: Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let ownerId: String
    public let createdAt: Date
    public let updatedAt: Date
    public let isArchived: Bool
    public let samples: [Sample]
    public let collaborators: [ProjectCollaborator]
    public let metadata: ProjectMetadata

    public init(
        id: String,
        name: String,
        description: String,
        ownerId: String,
        createdAt: Date,
        updatedAt: Date,
        isArchived: Bool,
        samples: [Sample],
        collaborators: [ProjectCollaborator],
        metadata: ProjectMetadata
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.ownerId = ownerId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.samples = samples
        self.collaborators = collaborators
        self.metadata = metadata
    }
}

/// Project collaborator information
public struct ProjectCollaborator: Sendable {
    public let userId: String
    public let email: String
    public let displayName: String
    public let permission: ProjectPermission
    public let addedAt: Date

    public init(
        userId: String,
        email: String,
        displayName: String,
        permission: ProjectPermission,
        addedAt: Date
    ) {
        self.userId = userId
        self.email = email
        self.displayName = displayName
        self.permission = permission
        self.addedAt = addedAt
    }
}

/// Project permissions
public enum ProjectPermission: String, Sendable {
    case owner
    case editor
    case viewer
}

/// Project metadata
public struct ProjectMetadata: Sendable {
    public let sampleCount: Int
    public let totalCaptures: Int
    public let totalAnnotations: Int
    public let lastSyncDate: Date?
    public let storageUsedBytes: Int

    public init(
        sampleCount: Int,
        totalCaptures: Int,
        totalAnnotations: Int,
        lastSyncDate: Date?,
        storageUsedBytes: Int
    ) {
        self.sampleCount = sampleCount
        self.totalCaptures = totalCaptures
        self.totalAnnotations = totalAnnotations
        self.lastSyncDate = lastSyncDate
        self.storageUsedBytes = storageUsedBytes
    }
}

/// Create project request
public struct CreateProjectRequest: Sendable {
    public let name: String
    public let description: String

    public init(name: String, description: String) {
        self.name = name
        self.description = description
    }
}

/// Update project request
public struct UpdateProjectRequest: Sendable {
    public let projectId: String
    public let name: String?
    public let description: String?
    public let isArchived: Bool?

    public init(
        projectId: String,
        name: String? = nil,
        description: String? = nil,
        isArchived: Bool? = nil
    ) {
        self.projectId = projectId
        self.name = name
        self.description = description
        self.isArchived = isArchived
    }
}

/// Project errors
public enum ProjectError: LocalizedError, Sendable {
    case projectNotFound
    case accessDenied
    case invalidName
    case quotaExceeded
    case networkError(String)
    case unknownError(String)

    public var errorDescription: String? {
        switch self {
        case .projectNotFound:
            return "Project not found"
        case .accessDenied:
            return "You do not have permission to access this project"
        case .invalidName:
            return "Project name is invalid"
        case .quotaExceeded:
            return "Storage quota exceeded"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknownError(let message):
            return "Error: \(message)"
        }
    }
}

/// Export format options
public enum ExportFormat: String, Sendable {
    case json
    case csv
    case pdf
    case zip
}
