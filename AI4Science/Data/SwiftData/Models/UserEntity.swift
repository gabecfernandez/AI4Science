import Foundation
import SwiftData

/// User persistence model for SwiftData
/// Represents the authenticated user and their metadata
@Model
final class UserEntity {
    /// Unique identifier for the user
    @Attribute(.unique) var id: String

    /// User's email address
    var email: String

    /// User's full name
    var fullName: String

    /// User's institution or organization
    var institution: String?

    /// User's profile image URL
    var profileImageURL: String?

    /// Account creation timestamp
    var createdAt: Date

    /// Last account update timestamp
    var updatedAt: Date

    /// Authentication token (should be stored securely in real app)
    var authToken: String?

    /// User's preferred language
    var preferredLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"

    /// User's timezone
    var timezone: String = TimeZone.current.identifier

    /// Whether the user has completed onboarding
    var hasCompletedOnboarding: Bool = false

    /// Relationship to user's projects
    @Relationship(deleteRule: .cascade, inverse: \ProjectEntity.owner) var projects: [ProjectEntity] = []

    /// Relationship to user's devices for sync
    @Relationship(deleteRule: .cascade) var deviceInfo: DeviceInfo?

    /// Initialization
    init(
        id: String,
        email: String,
        fullName: String,
        institution: String? = nil,
        profileImageURL: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        authToken: String? = nil
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.institution = institution
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.authToken = authToken
    }

    /// Update the user's information
    @MainActor
    func updateInfo(
        fullName: String? = nil,
        institution: String? = nil,
        profileImageURL: String? = nil
    ) {
        if let fullName = fullName {
            self.fullName = fullName
        }
        if let institution = institution {
            self.institution = institution
        }
        if let profileImageURL = profileImageURL {
            self.profileImageURL = profileImageURL
        }
        self.updatedAt = Date()
    }
}

/// Device information for sync tracking
@Model
final class DeviceInfo {
    var deviceID: String
    var deviceName: String
    var osVersion: String
    var appVersion: String
    var lastSyncDate: Date?

    init(
        deviceID: String,
        deviceName: String,
        osVersion: String,
        appVersion: String
    ) {
        self.deviceID = deviceID
        self.deviceName = deviceName
        self.osVersion = osVersion
        self.appVersion = appVersion
    }
}
