import Foundation

/// Mapper for converting between Project domain models and persistence models
struct ProjectMapper {
    /// Map ProjectEntity to ProjectDTO for API communication
    static func toDTO(_ entity: ProjectEntity) -> ProjectDTO {
        ProjectDTO(
            id: entity.id,
            name: entity.name,
            description: entity.description,
            projectType: entity.projectType,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }

    /// Map ProjectDTO to ProjectEntity for persistence
    static func toEntity(_ dto: ProjectDTO) -> ProjectEntity {
        ProjectEntity(
            id: dto.id,
            name: dto.name,
            description: dto.description,
            projectType: dto.projectType,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    /// Map domain Project model to ProjectEntity
    static func toEntity(from project: Project) -> ProjectEntity {
        let entity = ProjectEntity(
            id: project.id,
            name: project.name,
            description: project.description,
            projectType: project.projectType,
            createdAt: project.createdAt,
            updatedAt: project.updatedAt
        )
        entity.status = project.status
        entity.imageURL = project.imageURL
        entity.isShared = project.isShared
        entity.collaborators = project.collaborators
        entity.tags = project.tags
        return entity
    }

    /// Map ProjectEntity to domain Project model
    static func toModel(_ entity: ProjectEntity) -> Project {
        Project(
            id: entity.id,
            name: entity.name,
            description: entity.description,
            projectType: entity.projectType,
            status: entity.status,
            imageURL: entity.imageURL,
            isShared: entity.isShared,
            collaborators: entity.collaborators,
            tags: entity.tags,
            sampleCount: entity.sampleCount,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }

    /// Update ProjectEntity from ProjectDTO
    static func update(_ entity: ProjectEntity, with dto: ProjectDTO) {
        entity.name = dto.name
        entity.description = dto.description
        entity.updatedAt = dto.updatedAt
    }

    /// Update ProjectEntity from domain Project
    static func update(_ entity: ProjectEntity, with project: Project) {
        entity.name = project.name
        entity.description = project.description
        entity.imageURL = project.imageURL
        entity.tags = project.tags
        entity.status = project.status
        entity.updatedAt = project.updatedAt
    }
}

/// Domain Project model
struct Project: Codable, Identifiable {
    let id: String
    var name: String
    var description: String
    var projectType: String
    var status: String
    var imageURL: String?
    var isShared: Bool
    var collaborators: [String]
    var tags: [String]
    var sampleCount: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        name: String,
        description: String,
        projectType: String,
        status: String = "active",
        imageURL: String? = nil,
        isShared: Bool = false,
        collaborators: [String] = [],
        tags: [String] = [],
        sampleCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.projectType = projectType
        self.status = status
        self.imageURL = imageURL
        self.isShared = isShared
        self.collaborators = collaborators
        self.tags = tags
        self.sampleCount = sampleCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var isActive: Bool {
        status == "active"
    }

    var isArchived: Bool {
        status == "archived"
    }

    mutating func archive() {
        status = "archived"
        updatedAt = Date()
    }

    mutating func unarchive() {
        status = "active"
        updatedAt = Date()
    }

    mutating func addCollaborator(_ email: String) {
        guard !collaborators.contains(email) else { return }
        collaborators.append(email)
        isShared = true
        updatedAt = Date()
    }

    mutating func removeCollaborator(_ email: String) {
        collaborators.removeAll { $0 == email }
        if collaborators.isEmpty {
            isShared = false
        }
        updatedAt = Date()
    }
}
