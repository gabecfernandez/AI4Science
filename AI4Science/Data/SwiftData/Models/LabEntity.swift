import Foundation
import SwiftData

/// Lab persistence model for SwiftData
@Model
final class LabEntity {
    /// Unique identifier for the lab
    @Attribute(.unique) var id: String

    /// Lab display name
    var name: String

    /// Short abbreviation (e.g. "VAI")
    var abbreviation: String

    /// Detailed description — avoids CustomStringConvertible collision
    var labDescription: String

    /// Lab logo or image URL
    var imageURL: String?

    /// Host institution
    var institution: String?

    /// Lab website URL
    var website: String?

    /// Whether the lab is visible in Explore
    var isPublic: Bool = false

    /// Creation timestamp
    var createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    /// M2M: lab members. Inverse is declared on UserEntity.labs (the other side).
    @Relationship(deleteRule: .nullify)
    var members: [UserEntity] = []

    /// M2M: lab projects. Inverse is declared on ProjectEntity.labs (the other side).
    @Relationship(deleteRule: .nullify)
    var projects: [ProjectEntity] = []

    /// 1:1 optional: lab creator / PI.
    @Relationship(deleteRule: .nullify)
    var owner: UserEntity?

    /// Initialization — scalars only; relationships are set after insertion.
    init(
        id: String,
        name: String,
        abbreviation: String,
        labDescription: String,
        imageURL: String? = nil,
        institution: String? = nil,
        website: String? = nil,
        isPublic: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation
        self.labDescription = labDescription
        self.imageURL = imageURL
        self.institution = institution
        self.website = website
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
