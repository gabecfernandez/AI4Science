import Foundation
import SwiftData

actor UserRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ user: User) async throws {
        let idStr = user.id.uuidString
        let descriptor = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.id == idStr }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.email = user.email
            existing.fullName = user.displayName
            existing.updatedAt = user.updatedAt
        } else {
            let entity = UserEntity(
                id: user.id.uuidString,
                email: user.email,
                fullName: user.displayName
            )
            modelContext.insert(entity)
        }
        try modelContext.save()
    }

    func findById(_ id: UUID) async throws -> User? {
        let idStr = id.uuidString
        let descriptor = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.id == idStr }
        )
        guard let entity = try modelContext.fetch(descriptor).first else { return nil }
        return User(
            id: UUID(uuidString: entity.id) ?? UUID(),
            email: entity.email,
            displayName: entity.fullName
        )
    }

    func findByEmail(_ email: String) async throws -> User? {
        let descriptor = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.email == email }
        )
        guard let entity = try modelContext.fetch(descriptor).first else { return nil }
        return User(
            id: UUID(uuidString: entity.id) ?? UUID(),
            email: entity.email,
            displayName: entity.fullName
        )
    }

    func delete(_ id: UUID) async throws {
        let idStr = id.uuidString
        let descriptor = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.id == idStr }
        )
        guard let entity = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        modelContext.delete(entity)
        try modelContext.save()
    }
}
