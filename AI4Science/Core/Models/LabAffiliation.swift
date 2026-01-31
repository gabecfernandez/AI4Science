import Foundation

/// Represents a laboratory or research institution
public struct LabAffiliation: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var institution: String
    public var department: String?
    public var location: String?
    public var website: URL?
    public var contactEmail: String?
    public var contactPhone: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        institution: String,
        department: String? = nil,
        location: String? = nil,
        website: URL? = nil,
        contactEmail: String? = nil,
        contactPhone: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.institution = institution
        self.department = department
        self.location = location
        self.website = website
        self.contactEmail = contactEmail
        self.contactPhone = contactPhone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var displayName: String {
        if let department = department {
            return "\(name) - \(department)"
        }
        return name
    }

    public var fullName: String {
        if let department = department {
            return "\(institution) - \(name) - \(department)"
        }
        return "\(institution) - \(name)"
    }
}

// MARK: - Equatable
extension LabAffiliation: Equatable {
    public static func == (lhs: LabAffiliation, rhs: LabAffiliation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension LabAffiliation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
