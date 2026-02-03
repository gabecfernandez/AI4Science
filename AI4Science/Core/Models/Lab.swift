import Foundation

/// Represents a research laboratory
public struct Lab: Identifiable, Codable, Sendable {
    public let id: String
    public var name: String
    public var abbreviation: String
    public var description: String
    public var imageURL: URL?
    public var institution: String?
    public var isPublic: Bool
    public var memberCount: Int
    public var projectCount: Int

    public nonisolated init(
        id: String,
        name: String,
        abbreviation: String,
        description: String,
        imageURL: URL? = nil,
        institution: String? = nil,
        isPublic: Bool = false,
        memberCount: Int = 0,
        projectCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation
        self.description = description
        self.imageURL = imageURL
        self.institution = institution
        self.isPublic = isPublic
        self.memberCount = memberCount
        self.projectCount = projectCount
    }
}

// MARK: - Equatable
extension Lab: Equatable {
    public static func == (lhs: Lab, rhs: Lab) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Lab: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Lab Member

/// Display-only model representing a lab member.
public struct LabMember: Identifiable, Sendable {
    public let id: String
    public let fullName: String
    /// True when this member is the lab owner / PI.
    public let isPI: Bool
    /// Contact email address.
    public let email: String
    /// Institution or organization.
    public let institution: String?

    /// Two-letter initials derived from the name, skipping academic titles.
    public var initials: String {
        let titles: Set<String> = ["Dr.", "Prof.", "Dr", "Prof"]
        let parts = fullName.split(separator: " ").map(String.init)
        let filtered = parts.filter { !titles.contains($0) }
        let names = filtered.isEmpty ? parts : filtered
        guard let first = names.first, let firstChar = first.first else { return "?" }
        if names.count == 1 { return String(firstChar).uppercased() }
        guard let lastChar = names.last?.first else { return String(firstChar).uppercased() }
        return String(firstChar).uppercased() + String(lastChar).uppercased()
    }
}
