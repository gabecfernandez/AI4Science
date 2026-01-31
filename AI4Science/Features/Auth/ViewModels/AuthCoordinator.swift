import Foundation
import Observation

@Observable
@MainActor
final class AuthCoordinator {
    enum AuthFlow {
        case login
        case register
        case forgotPassword
        case biometricSetup
        case labAffiliation
        case completed
    }

    var currentFlow: AuthFlow = .login
    var isAuthenticated = false
    var userSession: UserSession?

    func navigateToRegister() {
        currentFlow = .register
    }

    func navigateToLogin() {
        currentFlow = .login
    }

    func navigateToForgotPassword() {
        currentFlow = .forgotPassword
    }

    func navigateToLabAffiliation() {
        currentFlow = .labAffiliation
    }

    func completeBiometricSetup() {
        currentFlow = .biometricSetup
    }

    func completeAuthentication(session: UserSession) async {
        userSession = session
        isAuthenticated = true
        currentFlow = .completed
    }

    func logout() {
        userSession = nil
        isAuthenticated = false
        currentFlow = .login
    }

    func restoreSession() async -> Bool {
        // Check for existing valid session
        if let savedSession = retrieveSavedSession() {
            userSession = savedSession
            isAuthenticated = true
            return true
        }
        return false
    }

    private func retrieveSavedSession() -> UserSession? {
        // Attempt to retrieve from Keychain
        if let userData = UserDefaults.standard.dictionary(forKey: "userData") as? [String: String],
           let email = userData["email"] {
            return UserSession(userId: UUID().uuidString, email: email)
        }
        return nil
    }
}

struct UserSession: Identifiable {
    let id: String
    let userId: String
    let email: String
    let labAffiliation: String?
    let createdAt: Date

    init(userId: String, email: String, labAffiliation: String? = nil) {
        self.id = UUID().uuidString
        self.userId = userId
        self.email = email
        self.labAffiliation = labAffiliation
        self.createdAt = Date()
    }
}
