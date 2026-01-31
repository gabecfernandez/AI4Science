import Foundation

/// Use case for signing in user with email and password
@available(iOS 15.0, *)
public actor SignInUseCase: Sendable {
    private let authService: any AuthServiceProtocol

    public init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    /// Execute sign in operation
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: Authentication session with tokens
    /// - Throws: AuthError if sign in fails
    public func execute(email: String, password: String) async throws -> AuthSession {
        // Validate input
        guard isValidEmail(email) else {
            throw AuthError.invalidCredentials
        }

        guard !password.isEmpty, password.count >= 8 else {
            throw AuthError.invalidCredentials
        }

        do {
            let session = try await authService.signIn(email: email, password: password)
            return session
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.unknownError(error.localizedDescription)
        }
    }

    /// Validate email format
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
}
