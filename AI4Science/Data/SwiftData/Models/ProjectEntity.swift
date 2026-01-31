import Foundation
import SwiftData

@Model
final class ProjectEntity: @unchecked Sendable {
    @Attribute(.unique) var id: String
    var name: String
    var projectDescription: String
    var ownerId: String
    var status: String = "draft"
    var sampleIds: [String] = []
    var collaboratorIds: [String] = []
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \SampleEntity.project) var samples: [SampleEntity] = []

    init(
        id: String,
        name: String,
        projectDescription: String,
        ownerId: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.projectDescription = projectDescription
        self.ownerId = ownerId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
