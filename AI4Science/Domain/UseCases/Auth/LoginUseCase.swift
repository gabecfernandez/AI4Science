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
    /// - Throws: AuthError if login fails
    public func execute(email: String, password: String) async throws -> AuthToken {
        // Validate input
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }
        guard !password.isEmpty else {
            throw AuthError.invalidPassword
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

