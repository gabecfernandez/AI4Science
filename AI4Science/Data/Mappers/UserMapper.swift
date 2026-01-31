import Foundation

/// Mapper for converting between User domain models and persistence models
struct UserMapper {
    /// Map UserEntity to UserDTO for API communication
    static func toDTO(_ entity: UserEntity) -> UserDTO {
        UserDTO(
            id: entity.id,
            email: entity.email,
            fullName: entity.fullName,
            institution: entity.institution,
            profileImageURL: entity.profileImageURL,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }

    /// Map UserDTO to UserEntity for persistence
    static func toEntity(_ dto: UserDTO) -> UserEntity {
        UserEntity(
            id: dto.id,
            email: dto.email,
            fullName: dto.fullName,
            institution: dto.institution,
            profileImageURL: dto.profileImageURL,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    /// Map UserModel to UserEntity
    static func toEntity(from user: UserModel) -> UserEntity {
        UserEntity(
            id: user.id,
            email: user.email,
            fullName: user.fullName,
            institution: user.institution,
            profileImageURL: user.profileImageURL,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
            authToken: user.authToken
        )
    }

    /// Map UserEntity to UserModel
    static func toModel(_ entity: UserEntity) -> UserModel {
        UserModel(
            id: entity.id,
            email: entity.email,
            fullName: entity.fullName,
            institution: entity.institution,
            profileImageURL: entity.profileImageURL,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            authToken: entity.authToken,
            preferredLanguage: entity.preferredLanguage,
            timezone: entity.timezone,
            hasCompletedOnboarding: entity.hasCompletedOnboarding
        )
    }

    /// Update UserEntity from UserDTO
    static func update(_ entity: UserEntity, with dto: UserDTO) {
        entity.email = dto.email
        entity.fullName = dto.fullName
        entity.institution = dto.institution
        entity.profileImageURL = dto.profileImageURL
        entity.updatedAt = dto.updatedAt
    }

    /// Update UserEntity from UserModel
    static func update(_ entity: UserEntity, with user: UserModel) {
        entity.email = user.email
        entity.fullName = user.fullName
        entity.institution = user.institution
        entity.profileImageURL = user.profileImageURL
        entity.preferredLanguage = user.preferredLanguage
        entity.timezone = user.timezone
        entity.hasCompletedOnboarding = user.hasCompletedOnboarding
        entity.updatedAt = user.updatedAt
    }
}

/// Local User model for mapper operations
struct UserModel: Codable, Identifiable {
    let id: String
    var email: String
    var fullName: String
    var institution: String?
    var profileImageURL: String?
    var createdAt: Date
    var updatedAt: Date
    var authToken: String?
    var preferredLanguage: String
    var timezone: String
    var hasCompletedOnboarding: Bool

    init(
        id: String,
        email: String,
        fullName: String,
        institution: String? = nil,
        profileImageURL: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        authToken: String? = nil,
        preferredLanguage: String = Locale.current.language.languageCode?.identifier ?? "en",
        timezone: String = TimeZone.current.identifier,
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.institution = institution
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.authToken = authToken
        self.preferredLanguage = preferredLanguage
        self.timezone = timezone
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
