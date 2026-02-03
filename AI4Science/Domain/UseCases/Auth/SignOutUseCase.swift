import Foundation

/// Use case for signing out current user and cleanup
@available(iOS 15.0, *)
public actor SignOutUseCase: Sendable {
    private let authService: any AuthServiceProtocol

    public init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    /// Execute sign out operation with cleanup
    /// - Throws: ServiceAuthError if sign out fails
    public func execute() async throws {
        do {
            try await authService.signOut()
        } catch let error as ServiceAuthError {
            throw error
        } catch {
            throw ServiceAuthError.unknownError(error.localizedDescription)
        }
    }
}
