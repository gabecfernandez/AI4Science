import Foundation
import SwiftData

@Model
final class UserEntity: @unchecked Sendable {
    @Attribute(.unique) var id: String
    var email: String
    var fullName: String
    var institution: String?
    var profileImageURL: String?
    var createdAt: Date
    var updatedAt: Date
    var authToken: String?
    var preferredLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"
    var timezone: String = TimeZone.current.identifier
    var hasCompletedOnboarding: Bool = false

    @Relationship(deleteRule: .cascade) var projects: [ProjectEntity] = []
    @Relationship(deleteRule: .cascade) var deviceInfo: DeviceInfo?

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
}

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
