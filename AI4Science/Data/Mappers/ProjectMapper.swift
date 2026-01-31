import Foundation

struct ProjectMapper {
    static func toEntity(from project: Project) -> ProjectEntity {
        let entity = ProjectEntity(
            id: project.id.uuidString,
            name: project.name,
            projectDescription: project.description,
            ownerId: project.ownerId.uuidString,
            createdAt: project.createdAt,
            updatedAt: project.updatedAt
        )
        entity.status = project.status.rawValue
        entity.sampleIds = project.sampleIds.map { $0.uuidString }
        entity.collaboratorIds = project.collaboratorIds.map { $0.uuidString }
        return entity
    }

    static func toModel(from entity: ProjectEntity) -> Project {
        Project(
            id: UUID(uuidString: entity.id) ?? UUID(),
            name: entity.name,
            description: entity.projectDescription,
            ownerId: UUID(uuidString: entity.ownerId) ?? UUID(),
            status: ProjectStatus(rawValue: entity.status) ?? .draft,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            sampleIds: entity.sampleIds.compactMap { UUID(uuidString: $0) },
            collaboratorIds: entity.collaboratorIds.compactMap { UUID(uuidString: $0) }
        )
    }
}
