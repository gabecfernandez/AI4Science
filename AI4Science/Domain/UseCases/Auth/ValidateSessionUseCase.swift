import Foundation

/// Use case for validating current user session
@available(iOS 15.0, *)
public actor ValidateSessionUseCase: Sendable {
    private let authService: any AuthServiceProtocol

    public init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    /// Check if current session is valid
    /// - Returns: True if session is valid, false otherwise
    /// - Throws: AuthError if validation fails
    public func execute() async throws -> Bool {
        do {
            return try await authService.validateSession()
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.unknownError(error.localizedDescription)
        }
    }

    /// Get current authenticated session
    /// - Returns: Current authentication session or nil if not authenticated
    /// - Throws: AuthError if retrieval fails
    public func getCurrentSession() async throws -> AuthSession? {
        do {
            return try await authService.getCurrentSession()
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.unknownError(error.localizedDescription)
        }
    }

    /// Check if user is authenticated without throwing
    /// - Returns: True if authenticated, false otherwise
    public func isAuthenticated() async -> Bool {
        do {
            return try await authService.isAuthenticated()
        } catch {
            return false
        }
    }
}
