import Foundation

/// Domain-level authentication service protocol
@available(iOS 15.0, *)
public protocol AuthServiceProtocol: Sendable {
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> AuthSession

    /// Register new user account
    func register(email: String, password: String, displayName: String) async throws -> AuthSession

    /// Sign out current user
    func signOut() async throws

    /// Validate current session
    func validateSession() async throws -> Bool

    /// Authenticate with biometric (Face ID/Touch ID)
    func authenticateWithBiometric() async throws -> AuthSession

    /// Refresh authentication token
    func refreshToken() async throws -> AuthSession

    /// Get current session
    func getCurrentSession() async throws -> AuthSession?

    /// Check if user is authenticated
    func isAuthenticated() async throws -> Bool
}

/// Authentication session data
public struct AuthSession: Sendable {
    public let userId: String
    public let email: String
    public let displayName: String
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date
    public let isBiometricEnabled: Bool

    public init(
        userId: String,
        email: String,
        displayName: String,
        accessToken: String,
        refreshToken: String,
        expiresAt: Date,
        isBiometricEnabled: Bool
    ) {
        self.userId = userId
        self.email = email
        self.displayName = displayName
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.isBiometricEnabled = isBiometricEnabled
    }
}

/// Authentication errors
public enum AuthError: LocalizedError, Sendable {
    case invalidCredentials
    case userNotFound
    case userAlreadyExists
    case weakPassword
    case sessionExpired
    case biometricNotAvailable
    case biometricFailed
    case networkError(String)
    case unknownError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        case .userAlreadyExists:
            return "User account already exists"
        case .weakPassword:
            return "Password does not meet security requirements"
        case .sessionExpired:
            return "Session has expired"
        case .biometricNotAvailable:
            return "Biometric authentication is not available"
        case .biometricFailed:
            return "Biometric authentication failed"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknownError(let message):
            return "Error: \(message)"
        }
    }
}
