//
//  SupabaseAuthenticationService.swift
//  AI4Science
//
//  Core authentication service implementation using Supabase
//

import Foundation
@preconcurrency import Supabase

/// Supabase-based authentication service
/// Thread-safe actor implementing AuthServiceProtocol
actor SupabaseAuthenticationService: AuthServiceProtocol {
    private let client: SupabaseClient
    private let userRepository: UserRepository
    private let keychainManager: KeychainManager

    // OAuth continuation state - isolated to this actor for thread safety
    private var oauthContinuation: CheckedContinuation<AuthSession, Error>?

    // MARK: - Initialization

    init(
        client: SupabaseClient,
        userRepository: UserRepository,
        keychainManager: KeychainManager
    ) {
        self.client = client
        self.userRepository = userRepository
        self.keychainManager = keychainManager
    }

    // MARK: - AuthServiceProtocol Implementation

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> AuthSession {
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )

            // Sync user to local database
            let authSession = try await syncUserToLocal(from: session)

            AppLogger.info("User signed in successfully: \(email)")
            return authSession

        } catch {
            throw mapSupabaseError(error)
        }
    }

    /// Register new user account
    func register(email: String, password: String, displayName: String) async throws -> AuthSession {
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["display_name": .string(displayName)]
            )

            // Check if session is returned (depends on Supabase email confirmation settings)
            if let session = response.session {
                // Email confirmation disabled - session returned immediately
                let authSession = try await syncUserToLocal(from: session)
                AppLogger.info("User registered successfully: \(email)")
                return authSession
            } else if response.user != nil {
                // Email confirmation enabled - user created but needs to verify email
                AppLogger.info("User registered, email confirmation required: \(email)")
                throw ServiceAuthError.emailConfirmationRequired
            } else {
                // Unexpected: no session and no user
                throw ServiceAuthError.unknownError("Registration failed - no user or session returned")
            }

        } catch {
            throw mapSupabaseError(error)
        }
    }

    /// Sign out current user
    func signOut() async throws {
        do {
            // Sign out from Supabase
            try await client.auth.signOut()

            // Delete local user data
            if let currentSession = try? await getCurrentSession() {
                try? await userRepository.deleteUser(id: currentSession.userId)
            }

            // Clear keychain
            try? await keychainManager.delete(for: "supabase.session")

            AppLogger.info("User signed out successfully")

        } catch {
            throw mapSupabaseError(error)
        }
    }

    /// Validate current session
    func validateSession() async throws -> Bool {
        do {
            let session = try await client.auth.session

            // Check if session is expired (expiresAt is TimeInterval/timestamp)
            let isValid = session.expiresAt > Date().timeIntervalSince1970
            return isValid

        } catch {
            // Session doesn't exist or is invalid
            return false
        }
    }

    /// Authenticate with biometric (Face ID/Touch ID)
    /// TODO: Implement full biometric authentication
    func authenticateWithBiometric() async throws -> AuthSession {
        // Stub implementation - marked for future enhancement
        throw ServiceAuthError.biometricNotAvailable
    }

    /// Refresh authentication token
    func refreshToken() async throws -> AuthSession {
        do {
            let session = try await client.auth.refreshSession()

            // Sync updated session to local database
            let authSession = try await syncUserToLocal(from: session)

            AppLogger.info("Token refreshed successfully")
            return authSession

        } catch {
            throw mapSupabaseError(error)
        }
    }

    /// Get current session
    func getCurrentSession() async throws -> AuthSession? {
        do {
            let session = try await client.auth.session
            return mapToAuthSession(from: session)

        } catch {
            // No session available
            return nil
        }
    }

    /// Check if user is authenticated
    func isAuthenticated() async throws -> Bool {
        do {
            let session = try await client.auth.session

            // Validate session is not expired (expiresAt is TimeInterval/timestamp)
            return session.expiresAt > Date().timeIntervalSince1970

        } catch {
            return false
        }
    }

    // MARK: - OAuth Methods

    /// Sign in with Google OAuth
    func signInWithGoogle() async throws -> AuthSession {
        try await performOAuthSignIn(provider: .google)
    }

    /// Sign in with Apple
    func signInWithApple() async throws -> AuthSession {
        try await performOAuthSignIn(provider: .apple)
    }

    /// Handle OAuth callback URL
    func handleOAuthCallback(url: URL) async throws {
        do {
            // Exchange callback for session
            try await client.auth.session(from: url)

            // Get the new session
            guard let session = try await getCurrentSession() else {
                throw ServiceAuthError.unknownError("Failed to retrieve session after OAuth")
            }

            // Resume the continuation
            oauthContinuation?.resume(returning: session)
            oauthContinuation = nil

        } catch {
            oauthContinuation?.resume(throwing: mapSupabaseError(error))
            oauthContinuation = nil
            throw mapSupabaseError(error)
        }
    }

    // MARK: - Private Helpers

    /// Perform OAuth sign-in flow
    private func performOAuthSignIn(provider: Provider) async throws -> AuthSession {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    // Store continuation for callback
                    await self.storeContinuation(continuation)

                    // Get OAuth URL
                    let oauthURL = try await self.client.auth.getOAuthSignInURL(
                        provider: provider,
                        redirectTo: URL(string: "ai4science://auth/callback")
                    )

                    // Open OAuth flow
                    _ = try await OAuthURLHandler.shared.openOAuthURL(oauthURL)

                    // Wait for callback - continuation will be resumed in handleOAuthCallback

                } catch {
                    await self.resumeWithError(error)
                }
            }
        }
    }

    private func storeContinuation(_ continuation: CheckedContinuation<AuthSession, Error>) {
        self.oauthContinuation = continuation
    }

    private func resumeWithError(_ error: Error) {
        oauthContinuation?.resume(throwing: mapSupabaseError(error))
        oauthContinuation = nil
    }

    /// Sync Supabase user to local SwiftData
    private func syncUserToLocal(from response: Session) async throws -> AuthSession {
        let userId = response.user.id.uuidString
        let email = response.user.email ?? ""
        // Try to extract display name from user metadata
        let displayName: String
        if let metadata = response.user.userMetadata["display_name"] {
            displayName = "\(metadata)"
        } else {
            displayName = email
        }

        // Check if user exists locally (Sendable-safe)
        let userExists = try await userRepository.userExists(id: userId)

        if userExists {
            // User exists - we would update here but can't access UserEntity directly
            // due to Sendable requirements. The user data will be synced when needed.
            AppLogger.debug("User already exists in local database: \(userId)")
        } else {
            // Create new user
            let newUser = UserEntity(
                id: userId,
                email: email,
                fullName: displayName,
                authToken: response.accessToken
            )
            try await userRepository.createUser(newUser)
            AppLogger.debug("Created new user in local database: \(userId)")
        }

        // Store session in Keychain for future biometric auth
        if let sessionData = try? JSONEncoder().encode(response) {
            try? await keychainManager.saveData(sessionData, for: "supabase.session")
        }

        return mapToAuthSession(from: response)
    }

    /// Map Supabase Session to AuthSession
    nonisolated private func mapToAuthSession(from session: Session) -> AuthSession {
        // Try to extract display name from user metadata
        let displayName: String
        if let metadata = session.user.userMetadata["display_name"] {
            displayName = "\(metadata)"
        } else {
            displayName = session.user.email ?? "User"
        }

        // Convert TimeInterval to Date
        let expiresAt = Date(timeIntervalSince1970: session.expiresAt)

        return AuthSession(
            userId: session.user.id.uuidString,
            email: session.user.email ?? "",
            displayName: displayName,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            expiresAt: expiresAt,
            isBiometricEnabled: false // TODO: Implement biometric check
        )
    }

    /// Map Supabase errors to ServiceAuthError
    nonisolated private func mapSupabaseError(_ error: Error) -> ServiceAuthError {
        // Parse error messages for common cases
        let errorMessage = error.localizedDescription.lowercased()

        if errorMessage.contains("invalid login credentials") || errorMessage.contains("invalid email or password") {
            return .invalidCredentials
        } else if errorMessage.contains("user already registered") || errorMessage.contains("already exists") {
            return .userAlreadyExists
        } else if errorMessage.contains("password") && errorMessage.contains("weak") {
            return .weakPassword
        } else if errorMessage.contains("session") && (errorMessage.contains("expired") || errorMessage.contains("missing")) {
            return .sessionExpired
        }

        // Network errors
        if let urlError = error as? URLError {
            return .networkError(urlError.localizedDescription)
        }

        // Service auth errors pass through
        if let serviceError = error as? ServiceAuthError {
            return serviceError
        }

        // Unknown errors
        return .unknownError(error.localizedDescription)
    }
}
