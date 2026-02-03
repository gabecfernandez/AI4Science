import Foundation

/// Mapper for converting between Project domain models and persistence models
/// Note: Methods marked nonisolated to allow calling from actor contexts
/// (Project has SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor)
struct ProjectMapper {
    // MARK: - Domain <-> Entity Mapping

    /// Map domain Project to ProjectEntity for persistence
    nonisolated static func toEntity(from project: Project) -> ProjectEntity {
        let entity = ProjectEntity(
            id: project.id.uuidString,
            name: project.title,
            projectDescription: project.description,
            createdAt: project.createdAt,
            updatedAt: project.updatedAt,
            projectType: mapProjectTypeToString(project.metadata["projectType"])
        )
        entity.status = project.status.rawValue
        entity.imageURL = project.thumbnailURL?.absoluteString
        entity.isShared = !project.participantIDs.isEmpty
        entity.collaborators = project.participantIDs.map { $0.uuidString }
        entity.tags = project.tags
        entity.sampleCount = project.sampleIDs.count
        entity.startDate = project.startDate
        entity.principalInvestigatorId = project.principalInvestigatorID.uuidString
        return entity
    }

    /// Map ProjectEntity to domain Project model
    nonisolated static func toDomain(_ entity: ProjectEntity) -> Project {
        let projectId = UUID(uuidString: entity.id) ?? UUID()
        let piId = entity.principalInvestigatorId.flatMap { UUID(uuidString: $0) } ?? UUID()

        return Project(
            id: projectId,
            title: entity.name,
            description: entity.projectDescription,
            status: mapStringToProjectStatus(entity.status),
            principalInvestigatorID: piId,
            labAffiliations: entity.labs.map { lab in
                LabAffiliation(name: lab.name, institution: lab.institution ?? "Unknown")
            },
            participantIDs: entity.collaborators.compactMap { UUID(uuidString: $0) },
            sampleIDs: entity.samples.compactMap { UUID(uuidString: $0.id) },
            startDate: entity.startDate ?? entity.createdAt,
            endDate: nil,
            metadata: ["projectType": entity.projectType],
            tags: entity.tags,
            thumbnailURL: entity.imageURL.flatMap { URL(string: $0) },
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }

    /// Update ProjectEntity from domain Project
    nonisolated static func update(_ entity: ProjectEntity, with project: Project) {
        entity.name = project.title
        entity.projectDescription = project.description
        entity.status = project.status.rawValue
        entity.imageURL = project.thumbnailURL?.absoluteString
        entity.tags = project.tags
        entity.isShared = !project.participantIDs.isEmpty
        entity.collaborators = project.participantIDs.map { $0.uuidString }
        entity.sampleCount = project.sampleIDs.count
        entity.startDate = project.startDate
        entity.principalInvestigatorId = project.principalInvestigatorID.uuidString
        entity.updatedAt = project.updatedAt
    }

    // MARK: - DTO Mapping (for API communication)

    /// Map ProjectEntity to ProjectDTO for API communication
    nonisolated static func toDTO(_ entity: ProjectEntity) -> ProjectDTO {
        ProjectDTO(
            id: entity.id,
            name: entity.name,
            description: entity.projectDescription,
            projectType: entity.projectType,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }

    /// Map ProjectDTO to ProjectEntity for persistence
    nonisolated static func toEntity(_ dto: ProjectDTO) -> ProjectEntity {
        ProjectEntity(
            id: dto.id,
            name: dto.name,
            projectDescription: dto.description,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            projectType: dto.projectType
        )
    }

    /// Update ProjectEntity from ProjectDTO
    nonisolated static func update(_ entity: ProjectEntity, with dto: ProjectDTO) {
        entity.name = dto.name
        entity.projectDescription = dto.description
        entity.updatedAt = dto.updatedAt
    }

    // MARK: - Helper Methods

    private nonisolated static func mapStringToProjectStatus(_ status: String) -> ProjectStatus {
        switch status.lowercased() {
        case "planning", "draft":
            return .planning
        case "active":
            return .active
        case "on_hold", "onhold", "paused":
            return .onHold
        case "completed":
            return .completed
        case "archived":
            return .archived
        default:
            return .planning
        }
    }

    private nonisolated static func mapProjectTypeToString(_ type: String?) -> String {
        type ?? "materials_science"
    }

}
