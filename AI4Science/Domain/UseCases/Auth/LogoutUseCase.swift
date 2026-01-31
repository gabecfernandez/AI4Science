import Foundation

public struct LogoutUseCase: Sendable {
    private let authRepository: any AuthRepositoryProtocol
    private let projectRepository: any LogoutProjectRepositoryProtocol
    private let captureRepository: any LogoutCaptureRepositoryProtocol

    public init(
        authRepository: any AuthRepositoryProtocol,
        projectRepository: any LogoutProjectRepositoryProtocol,
        captureRepository: any LogoutCaptureRepositoryProtocol
    ) {
        self.authRepository = authRepository
        self.projectRepository = projectRepository
        self.captureRepository = captureRepository
    }

    /// Executes user logout with cleanup of local data
    /// - Parameter clearLocalData: Whether to clear cached user data (default: false)
    /// - Throws: AuthError if logout fails
    public func execute(clearLocalData: Bool = false) async throws {
        // Invalidate tokens on server
        do {
            try await authRepository.logout()
        } catch {
            // Log the error but continue with local cleanup
            print("Server logout failed: \(error)")
        }

        // Clear sensitive data from memory
        if clearLocalData {
            try await projectRepository.clearLocalCache()
            try await captureRepository.clearLocalCache()
        }

        // Clear authentication tokens from secure storage
        try await authRepository.clearTokens()
    }
}

// MARK: - Repository Protocol Dependencies

public protocol AuthRepositoryProtocol: Sendable {
    func login(email: String, password: String) async throws -> AuthToken
    func logout() async throws
    func clearTokens() async throws
    func validateToken() async throws -> Bool
    func refreshToken(refreshToken: String) async throws -> AuthToken
}

public protocol LogoutProjectRepositoryProtocol: Sendable {
    func clearLocalCache() async throws
}

public protocol LogoutCaptureRepositoryProtocol: Sendable {
    func clearLocalCache() async throws
}
