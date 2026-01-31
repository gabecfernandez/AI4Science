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
    public var firstName: String
    public var lastName: String
    public var email: String
    public var role: UserRole
    public var labAffiliation: LabAffiliation?
    public var profileImageURL: URL?
    public var bio: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var isActive: Bool

    public init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        email: String,
        role: UserRole,
        labAffiliation: LabAffiliation? = nil,
        profileImageURL: URL? = nil,
        bio: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.role = role
        self.labAffiliation = labAffiliation
        self.profileImageURL = profileImageURL
        self.bio = bio
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isActive = isActive
    }

    public var fullName: String {
        "\(firstName) \(lastName)"
    }

    public var displayName: String {
        fullName.isEmpty ? email : fullName
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
