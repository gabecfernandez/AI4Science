import Foundation

/// User roles within the application
@frozen
public enum UserRole: String, Codable, Sendable, CaseIterable {
    case researcher
    case citizen
    case admin
}

/// Represents a user in the AI4Science application
public struct User: Identifiable, Codable, Sendable {
    public let id: UUID
    public var email: String
    public var displayName: String
    public var role: UserRole
    public var labAffiliation: LabAffiliation?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        email: String,
        displayName: String,
        role: UserRole,
        labAffiliation: LabAffiliation? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.role = role
        self.labAffiliation = labAffiliation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Equatable

extension User: Equatable {
    public static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension User: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
