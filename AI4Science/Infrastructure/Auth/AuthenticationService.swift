import Foundation
import Supabase
import CryptoKit
import Security

/// Core authentication actor. All Supabase SDK calls are serialised within this
/// actor's isolation domain. ViewModels (`@MainActor`) cross the boundary via
/// `await`; the return type `User` is a `Sendable` struct so no data-race occurs.
actor AuthenticationService {
    // MARK: - Properties

    private let client: SupabaseClient
    private let userRepository: UserRepository

    /// The currently signed-in user, or `nil` when unauthenticated.
    private(set) var currentUser: User?

    /// Convenience accessor checked by ViewModels after sign-in.
    var isAuthenticated: Bool { currentUser != nil }

    // MARK: - Initialization

    init(config: SupabaseConfig = .current, userRepository: UserRepository) {
        self.client = SupabaseClient(
            supabaseURL: config.projectURL,
            supabaseKey: config.anonKey,
            options: SupabaseClientOptions(
                auth: .init(storage: SupabaseSessionStorage())
            )
        )
        self.userRepository = userRepository
    }

    // MARK: - Email / Password

    /// Create a new account and persist the user locally.
    func signUp(email: String, password: String, fullName: String) async throws -> User {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: ["full_name": .string(fullName)]
        )

        let user = try buildDomainUser(from: response.user, fullName: fullName)
        try await syncLocalUser(userId: response.user.id.uuidString, email: email, fullName: fullName)
        currentUser = user
        return user
    }

    /// Authenticate with email and password.
    func signIn(email: String, password: String) async throws -> User {
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )

        let fullName = extractFullName(from: session.user)
        let user = try buildDomainUser(from: session.user, fullName: fullName)
        try await syncLocalUser(userId: session.user.id.uuidString, email: email, fullName: fullName)
        currentUser = user
        return user
    }

    // MARK: - Google OAuth

    /// Return the URL that should be opened in an `ASWebAuthenticationSession`
    /// to begin the Google OAuth flow.
    func googleOAuthURL() throws -> URL {
        try client.auth.getOAuthSignInURL(
            provider: .google,
            scopes: "email profile",
            redirectTo: URL(string: "ai4science://oauth/callback")!
        )
    }

    /// Exchange the OS-delivered callback URL for a Supabase session.
    /// Called from the app's `.onOpenURL` handler on `@MainActor`.
    func handleGoogleOAuthCallback(url: URL) async throws -> User {
        let session = try await client.auth.session(from: url)

        let fullName = extractFullName(from: session.user)
        let user = try buildDomainUser(from: session.user, fullName: fullName)
        try await syncLocalUser(userId: session.user.id.uuidString, email: session.user.email ?? "", fullName: fullName)
        currentUser = user
        return user
    }

    // MARK: - Apple Sign-In

    /// Complete Apple Sign-In using the extracted ID token and the original nonce.
    /// The caller (ViewModel) extracts these `Sendable` values from the
    /// non-Sendable `ASAuthorizationAppleIDCredential` before crossing the actor boundary.
    func signInWithApple(idToken: String, nonce: String) async throws -> User {
        let session = try await client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )

        let fullName = extractFullName(from: session.user)
        let user = try buildDomainUser(from: session.user, fullName: fullName)
        try await syncLocalUser(userId: session.user.id.uuidString, email: session.user.email ?? "", fullName: fullName)
        currentUser = user
        return user
    }

    // MARK: - Sign Out

    /// Sign out from Supabase and clear local state.
    /// Network failures during the remote sign-out are logged but do not
    /// prevent local state from being cleared.
    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            // Log-but-don't-block: AppLogger is @MainActor so we use print inside the actor.
            print("[AuthenticationService] Remote sign-out failed (local state will still be cleared): \(error)")
        }
        currentUser = nil
    }

    // MARK: - Session Restore

    /// Attempt to restore a persisted session from Keychain on app launch.
    /// Returns `nil` when no valid session exists.
    func restoreSession() async -> User? {
        guard let session = client.auth.currentSession else {
            return nil
        }
        do {
            let fullName = extractFullName(from: session.user)
            let user = try buildDomainUser(from: session.user, fullName: fullName)
            currentUser = user
            return user
        } catch {
            print("[AuthenticationService] Failed to build user from restored session: \(error)")
            return nil
        }
    }

    // MARK: - Private Helpers

    /// Build a `User` domain model from a Supabase user. Parses the UUID string
    /// and splits `fullName` into first / last name components.
    /// Marked `nonisolated` because it is a pure function of its parameters — no
    /// actor state is accessed, and `User` is a `Sendable` struct.
    nonisolated private func buildDomainUser(from supabaseUser: Supabase.User, fullName: String) throws -> User {
        guard let uuid = UUID(uuidString: supabaseUser.id.uuidString) else {
            throw AuthError.invalidUserId(supabaseUser.id.uuidString)
        }

        let parts = fullName.split(separator: " ", maxSplits: 1)
        let firstName = parts.first.map(String.init) ?? fullName
        let lastName  = parts.count > 1 ? String(parts[1]) : ""

        return User(
            id: uuid,
            firstName: firstName,
            lastName: lastName,
            email: supabaseUser.email ?? "",
            role: .researcher
        )
    }

    /// Extract `full_name` from Supabase user metadata, falling back to email.
    nonisolated private func extractFullName(from supabaseUser: Supabase.User) -> String {
        if let name = supabaseUser.userMetadata["full_name"]?.stringValue, !name.isEmpty {
            return name
        }
        return supabaseUser.email ?? ""
    }

    /// Persist user data via `UserRepository.upsertUser`. Only `Sendable` value
    /// types cross the actor boundary — no `UserEntity` is returned.
    private func syncLocalUser(userId: String, email: String, fullName: String) async throws {
        try await userRepository.upsertUser(id: userId, email: email, fullName: fullName)
    }

    // MARK: - Nonce Utilities (nonisolated)

    /// Generate a 32-character URL-safe random nonce for Apple Sign-In.
    /// Pure function — no actor state accessed.
    nonisolated static func generateNonce() -> String {
        let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return String(bytes.map { characters[Int($0) % characters.count] })
    }

    /// SHA-256 hash of the nonce, hex-encoded. Required by Apple's sign-in flow.
    /// Pure function — no actor state accessed.
    nonisolated static func sha256(_ string: String) -> String {
        let data = Data(string.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
