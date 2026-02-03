import Foundation
import SwiftData

/// Project persistence model for SwiftData
/// Represents a scientific research project
@Model
final class ProjectEntity {
    /// Unique identifier for the project
    @Attribute(.unique) var id: String

    /// Project name
    var name: String

    /// Detailed project description
    var projectDescription: String

    /// The owner/creator of the project
    var owner: UserEntity?

    /// Project creation timestamp
    var createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    /// Project status (active, archived, etc.)
    var status: String = "active"

    /// Project type/category
    var projectType: String

    /// Project image or thumbnail URL
    var imageURL: String?

    /// Number of samples in project
    var sampleCount: Int = 0

    /// Whether the project is shared
    var isShared: Bool = false

    /// List of collaborators (email addresses)
    var collaborators: [String] = []

    /// Tags for organizing projects
    var tags: [String] = []

    /// Project start date
    var startDate: Date?

    /// Principal investigator ID
    var principalInvestigatorId: String?

    /// Relationship to project samples
    @Relationship(deleteRule: .cascade, inverse: \SampleEntity.project) var samples: [SampleEntity] = []

    /// Relationship to project metadata
    @Relationship(deleteRule: .cascade) var metadata: ProjectMetadata?

    /// Initialization
    init(
        id: String,
        name: String,
        projectDescription: String,
        owner: UserEntity? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        projectType: String
    ) {
        self.id = id
        self.name = name
        self.projectDescription = projectDescription
        self.owner = owner
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.projectType = projectType
    }

    /// Update project information
    @MainActor
    func updateInfo(
        name: String? = nil,
        projectDescription: String? = nil,
        imageURL: String? = nil,
        tags: [String]? = nil
    ) {
        if let name = name {
            self.name = name
        }
        if let projectDescription = projectDescription {
            self.projectDescription = projectDescription
        }
        if let imageURL = imageURL {
            self.imageURL = imageURL
        }
        if let tags = tags {
            self.tags = tags
        }
        self.updatedAt = Date()
    }

    /// Archive the project
    @MainActor
    func archive() {
        self.status = "archived"
        self.updatedAt = Date()
    }

    /// Unarchive the project
    @MainActor
    func unarchive() {
        self.status = "active"
        self.updatedAt = Date()
    }

    /// Add a collaborator
    @MainActor
    func addCollaborator(_ email: String) {
        if !collaborators.contains(email) {
            collaborators.append(email)
            isShared = true
            updatedAt = Date()
        }
    }

    /// Remove a collaborator
    @MainActor
    func removeCollaborator(_ email: String) {
        collaborators.removeAll { $0 == email }
        if collaborators.isEmpty {
            isShared = false
        }
        updatedAt = Date()
    }
}

/// Project metadata for additional information
@Model
final class ProjectMetadata {
    var keywords: [String] = []
    var institution: String?
    var fundingInfo: String?
    var researchArea: String?
    var publicationURLs: [String] = []

    init(
        keywords: [String] = [],
        institution: String? = nil,
        fundingInfo: String? = nil,
        researchArea: String? = nil
    ) {
        self.keywords = keywords
        self.institution = institution
        self.fundingInfo = fundingInfo
        self.researchArea = researchArea
    }
}
