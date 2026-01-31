import Foundation

/// Use case for user registration
@available(iOS 15.0, *)
public actor RegisterUseCase: Sendable {
    private let authService: any AuthServiceProtocol
    private let minPasswordLength = 8
    private let maxPasswordLength = 128

    public init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    /// Execute user registration
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's desired password
    ///   - displayName: User's display name
    /// - Returns: Authentication session with tokens
    /// - Throws: AuthError if registration fails
    public func execute(
        email: String,
        password: String,
        displayName: String
    ) async throws -> AuthSession {
        // Validate inputs
        try validateEmail(email)
        try validatePassword(password)
        try validateDisplayName(displayName)

        do {
            let session = try await authService.register(
                email: email,
                password: password,
                displayName: displayName
            )
            return session
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.unknownError(error.localizedDescription)
        }
    }

    /// Validate email format and length
    private func validateEmail(_ email: String) throws {
        guard !email.isEmpty && email.count <= 254 else {
            throw AuthError.invalidCredentials
        }

        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard predicate.evaluate(with: email) else {
            throw AuthError.invalidCredentials
        }
    }

    /// Validate password strength
    private func validatePassword(_ password: String) throws {
        guard password.count >= minPasswordLength && password.count <= maxPasswordLength else {
            throw AuthError.weakPassword
        }

        // Check for at least one uppercase letter
        guard password.range(of: "[A-Z]", options: .regularExpression) != nil else {
            throw AuthError.weakPassword
        }

        // Check for at least one lowercase letter
        guard password.range(of: "[a-z]", options: .regularExpression) != nil else {
            throw AuthError.weakPassword
        }

        // Check for at least one digit
        guard password.range(of: "[0-9]", options: .regularExpression) != nil else {
            throw AuthError.weakPassword
        }

        // Check for at least one special character
        guard password.range(of: "[!@#$%^&*()_+\\-=\\[\\]{};':\",./<>?]", options: .regularExpression) != nil else {
            throw AuthError.weakPassword
        }
    }

    /// Validate display name
    private func validateDisplayName(_ name: String) throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AuthError.invalidCredentials
        }
        guard name.count >= 2 && name.count <= 100 else {
            throw AuthError.invalidCredentials
        }
    }
}
