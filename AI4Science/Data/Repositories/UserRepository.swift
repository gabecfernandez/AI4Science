import Foundation
import SwiftData

/// Repository protocol for user operations
protocol UserRepositoryProtocol: Sendable {
    func createUser(_ user: UserEntity) async throws
    func getUser(id: String) async throws -> UserEntity?
    func getUserByEmail(_ email: String) async throws -> UserEntity?
    func updateUser(_ user: UserEntity) async throws
    func deleteUser(id: String) async throws
    func getAllUsers() async throws -> [UserEntity]
    func getCurrentUser() async throws -> UserEntity?
}

/// User repository implementation with SwiftData
actor UserRepository: UserRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

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
        guard let user = try getUser(id: id) else {
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
}

/// Repository error types
enum RepositoryError: LocalizedError {
    case notFound
    case saveFailed
    case deleteFailed
    case invalidData
    case networkError

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Resource not found"
        case .saveFailed:
            return "Failed to save data"
        case .deleteFailed:
            return "Failed to delete data"
        case .invalidData:
            return "Invalid data"
        case .networkError:
            return "Network error occurred"
        }
    }
}

/// Factory for creating user repository
struct UserRepositoryFactory {
    static func makeRepository(modelContext: ModelContext) -> UserRepository {
        UserRepository(modelContext: modelContext)
    }

    static func makeRepository(modelContainer: ModelContainer) -> UserRepository {
        let context = ModelContext(modelContainer)
        return UserRepository(modelContext: context)
    }
}
