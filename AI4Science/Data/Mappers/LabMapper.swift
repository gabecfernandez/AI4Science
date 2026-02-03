import Foundation

/// Mapper for converting between Lab domain models and persistence models.
/// All methods are nonisolated static — callers (LabRepository) run on @ModelActor,
/// so relationship access (.members.count, .projects.count) is safe.
struct LabMapper {

    /// Map LabEntity → Lab domain model.
    /// Reads relationship counts — must be called inside @ModelActor.
    nonisolated static func toDomain(_ entity: LabEntity) -> Lab {
        Lab(
            id: entity.id,
            name: entity.name,
            abbreviation: entity.abbreviation,
            description: entity.labDescription,
            imageURL: entity.imageURL.flatMap { URL(string: $0) },
            institution: entity.institution,
            isPublic: entity.isPublic,
            memberCount: entity.members.count,
            projectCount: entity.projects.count
        )
    }

    /// Map Lab domain model → LabEntity for persistence.
    nonisolated static func toEntity(from lab: Lab) -> LabEntity {
        LabEntity(
            id: lab.id,
            name: lab.name,
            abbreviation: lab.abbreviation,
            labDescription: lab.description,
            imageURL: lab.imageURL?.absoluteString,
            institution: lab.institution,
            isPublic: lab.isPublic
        )
    }

    /// Update an existing LabEntity from a Lab domain model.
    nonisolated static func update(_ entity: LabEntity, with lab: Lab) {
        entity.name = lab.name
        entity.abbreviation = lab.abbreviation
        entity.labDescription = lab.description
        entity.imageURL = lab.imageURL?.absoluteString
        entity.institution = lab.institution
        entity.isPublic = lab.isPublic
        entity.updatedAt = Date()
    }
}
