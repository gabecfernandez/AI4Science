import Foundation
import SwiftData

/// Protocol for lab operations — returns only Sendable domain types
protocol LabRepositoryProtocol: Sendable {
    func save(_ lab: Lab) async throws
    func findById(_ id: String) async throws -> Lab?
    func findByUser(userId: String) async throws -> [Lab]
    func findAll() async throws -> [Lab]
    func delete(_ id: String) async throws
    func addMember(_ userId: String, to labId: String) async throws
    func removeMember(_ userId: String, from labId: String) async throws
    func findLabProjects(labId: String) async throws -> [Project]
    func findLabMembers(labId: String) async throws -> [LabMember]
    func findProjectsByUser(userId: String) async throws -> [Project]
}

/// Lab repository implementation using ModelActor
@ModelActor
final actor LabRepository: LabRepositoryProtocol {

    // MARK: - CRUD

    func save(_ lab: Lab) async throws {
        let entity = LabMapper.toEntity(from: lab)
        modelContext.insert(entity)
        try modelContext.save()
    }

    func findById(_ id: String) async throws -> Lab? {
        let descriptor = FetchDescriptor<LabEntity>(
            predicate: #Predicate { $0.id == id }
        )
        guard let entity = try modelContext.fetch(descriptor).first else {
            return nil
        }
        return LabMapper.toDomain(entity)
    }

    /// Labs the given user is a member of.
    /// Cannot use #Predicate to traverse M2M — walks the relationship from the fetched user.
    func findByUser(userId: String) async throws -> [Lab] {
        let descriptor = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.id == userId }
        )
        guard let user = try modelContext.fetch(descriptor).first else {
            return []
        }
        return user.labs.map { LabMapper.toDomain($0) }
    }

    func findAll() async throws -> [Lab] {
        let descriptor = FetchDescriptor<LabEntity>(
            sortBy: [SortDescriptor(\.name)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map { LabMapper.toDomain($0) }
    }

    func delete(_ id: String) async throws {
        let descriptor = FetchDescriptor<LabEntity>(
            predicate: #Predicate { $0.id == id }
        )
        guard let entity = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        modelContext.delete(entity)
        try modelContext.save()
    }

    // MARK: - Membership

    func addMember(_ userId: String, to labId: String) async throws {
        let labDescriptor = FetchDescriptor<LabEntity>(
            predicate: #Predicate { $0.id == labId }
        )
        guard let lab = try modelContext.fetch(labDescriptor).first else {
            throw RepositoryError.notFound
        }

        let userDescriptor = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.id == userId }
        )
        guard let user = try modelContext.fetch(userDescriptor).first else {
            throw RepositoryError.notFound
        }

        if !lab.members.contains(where: { $0.id == userId }) {
            lab.members.append(user)
            try modelContext.save()
        }
    }

    func removeMember(_ userId: String, from labId: String) async throws {
        let descriptor = FetchDescriptor<LabEntity>(
            predicate: #Predicate { $0.id == labId }
        )
        guard let lab = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }

        lab.members.removeAll { $0.id == userId }
        try modelContext.save()
    }

    // MARK: - Lab Projects

    /// Projects belonging to a lab.
    /// Walks the 1:M relationship from the fetched LabEntity — no predicate join needed.
    func findLabProjects(labId: String) async throws -> [Project] {
        let descriptor = FetchDescriptor<LabEntity>(
            predicate: #Predicate { $0.id == labId }
        )
        guard let lab = try modelContext.fetch(descriptor).first else {
            return []
        }
        return lab.projects.map { ProjectMapper.toDomain($0) }
    }
    // MARK: - Lab Members

    /// Members of a lab with PI flag.
    /// Walks the M2M relationship from the fetched LabEntity — no predicate join needed.
    func findLabMembers(labId: String) async throws -> [LabMember] {
        let descriptor = FetchDescriptor<LabEntity>(
            predicate: #Predicate { $0.id == labId }
        )
        guard let lab = try modelContext.fetch(descriptor).first else {
            return []
        }
        let ownerId = lab.owner?.id
        return lab.members.map { member in
            LabMember(
                id: member.id,
                fullName: member.fullName,
                isPI: member.id == ownerId,
                email: member.email,
                institution: member.institution
            )
        }
    }

    // MARK: - User Projects

    /// All projects across labs the given user belongs to, deduplicated.
    /// Walks user → labs → projects within @ModelActor — no predicate join needed.
    func findProjectsByUser(userId: String) async throws -> [Project] {
        let descriptor = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.id == userId }
        )
        guard let user = try modelContext.fetch(descriptor).first else {
            return []
        }
        var seen = Set<String>()
        var projects: [Project] = []
        for lab in user.labs {
            for project in lab.projects {
                if seen.insert(project.id).inserted {
                    projects.append(ProjectMapper.toDomain(project))
                }
            }
        }
        return projects
    }
}

/// Factory for creating lab repository
enum LabRepositoryFactory {
    @MainActor
    static func makeRepository(modelContainer: ModelContainer) -> LabRepository {
        LabRepository(modelContainer: modelContainer)
    }
}
