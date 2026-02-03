import Foundation
import SwiftData

/// Repository protocol for user operations - returns only Sendable domain types
/// Entity-based operations are internal to the actor and not exposed via protocol
protocol UserRepositoryProtocol: Sendable {
    // Domain model operations would go here when User domain model is added
    // For now, keep entity operations internal to actor only
}

/// User repository implementation using ModelActor
@ModelActor
final actor UserRepository {

    /// Create a new user
    func createUser(_ user: UserEntity) async throws {
        modelContext.insert(user)
        try modelContext.save()
    }

    /// Get user by ID
    func getUser(id: String) async throws -> UserEntity? {
        let descriptor = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Get user by email
    func getUserByEmail(_ email: String) async throws -> UserEntity? {
        let descriptor = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.email == email }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Update user information
    func updateUser(_ user: UserEntity) async throws {
        user.updatedAt = Date()
        try modelContext.save()
    }

    /// Delete user by ID
    func deleteUser(id: String) async throws {
        guard let user = try await getUser(id: id) else {
            throw RepositoryError.notFound
        }
        modelContext.delete(user)
        try modelContext.save()
    }

    /// Get all users
    func getAllUsers() async throws -> [UserEntity] {
        let descriptor = FetchDescriptor<UserEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get current user (typically fetched from auth)
    func getCurrentUser() async throws -> UserEntity? {
        // This would typically get the current authenticated user
        // Implementation depends on authentication system
        return nil
    }

    /// Check if user exists by ID (Sendable-safe)
    func userExists(id: String) async throws -> Bool {
        let descriptor = FetchDescriptor<UserEntity>(
            predicate: #Predicate { $0.id == id }
        )
        let users = try modelContext.fetch(descriptor)
        return !users.isEmpty
    }

    /// Update user institution by ID (Sendable-safe)
    func updateUserInstitution(id: String, institution: String) async throws {
        guard let user = try await getUser(id: id) else {
            throw RepositoryError.notFound
        }
        user.institution = institution
        user.updatedAt = Date()
        try modelContext.save()
    }
}

// Note: RepositoryError is defined in Core/Protocols/Repository.swift

/// Factory for creating user repository
enum UserRepositoryFactory {
    @MainActor
    static func makeRepository(modelContainer: ModelContainer) -> UserRepository {
        UserRepository(modelContainer: modelContainer)
    }
}

// MARK: - Sendable Display Models

/// Sendable display model for user profile
struct UserDisplayData: Sendable {
    let id: String
    let fullName: String
    let email: String
    let institution: String?
    let profileImageURL: String?
    let createdAt: Date
}

extension UserRepository {
    /// Get first user as a Sendable display model
    func getFirstUserDisplayData() async throws -> UserDisplayData? {
        let descriptor = FetchDescriptor<UserEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let users = try modelContext.fetch(descriptor)
        guard let user = users.first else { return nil }
        return UserDisplayData(
            id: user.id,
            fullName: user.fullName,
            email: user.email,
            institution: user.institution,
            profileImageURL: user.profileImageURL,
            createdAt: user.createdAt
        )
    }
}
