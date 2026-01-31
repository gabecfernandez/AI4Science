import Foundation

public struct LoginUseCase: Sendable {
    private let authRepository: any AuthRepositoryProtocol

    public init(authRepository: any AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    /// Executes user login with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: AuthToken containing access and refresh tokens
    /// - Throws: ServiceAuthError if login fails
    public func execute(email: String, password: String) async throws -> AuthToken {
        // Validate input
        guard !email.isEmpty else {
            throw LoginServiceAuthError.invalidEmail
        }
        guard !password.isEmpty else {
            throw LoginServiceAuthError.invalidPassword
        }

        // Attempt login through repository
        let token = try await authRepository.login(email: email, password: password)
        return token
    }
}

// MARK: - Supporting Types

public struct AuthToken: Sendable, Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let userId: String

    public init(
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        userId: String
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.userId = userId
    }
}

public enum LoginServiceAuthError: LocalizedError, Sendable {
    case invalidEmail
    case invalidPassword
    case invalidCredentials
    case networkError
    case serverError(message: String)
    case tokenExpired
    case unauthorized

    public var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "The email address is invalid."
        case .invalidPassword:
            return "The password is invalid."
        case .invalidCredentials:
            return "Email or password is incorrect."
        case .networkError:
            return "Network connection failed."
        case .serverError(let message):
            return "Server error: \(message)"
        case .tokenExpired:
            return "Authentication token has expired."
        case .unauthorized:
            return "User is not authorized."
        }
    }
}
