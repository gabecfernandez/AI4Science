import Foundation

public struct CreateProjectRequest: Sendable {
    public let name: String
    public let description: String
    public let ownerId: UUID

    public init(name: String, description: String, ownerId: UUID) {
        self.name = name
        self.description = description
        self.ownerId = ownerId
    }
}

public struct UpdateProjectRequest: Sendable {
    public let projectId: UUID
    public let name: String?
    public let description: String?

    public init(projectId: UUID, name: String? = nil, description: String? = nil) {
        self.projectId = projectId
        self.name = name
        self.description = description
    }
}

public enum ProjectError: LocalizedError, Sendable {
    case invalidName
    case projectNotFound
    case unknownError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Project name is invalid"
        case .projectNotFound:
            return "Project not found"
        case .unknownError(let message):
            return "Error: \(message)"
        }
    }
}

public struct ValidationError: LocalizedError, Sendable {
    public let message: String

    public init(message: String) {
        self.message = message
    }

    public var errorDescription: String? {
        message
    }
}

public enum ProjectPermission: String, Sendable {
    case owner
    case editor
    case viewer
}

public enum ExportFormat: String, Sendable {
    case json
    case csv
    case pdf
    case zip
}
