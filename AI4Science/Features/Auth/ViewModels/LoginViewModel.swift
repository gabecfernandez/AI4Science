import Foundation
import Observation

@Observable
@MainActor
final class LoginViewModel {
    var email = ""
    var password = ""
    var rememberMe = false
    var isLoading = false
    var showError = false
    var errorMessage = ""

    /// Injected by LoginView via .onAppear
    var authService: AuthenticationService?
    var appState: AppState?

    func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            if !isValidEmail(email) {
                throw ViewModelAuthError.invalidEmail
            }
            guard let authService = authService else {
                throw ViewModelAuthError.unknownError
            }
            let user = try await authService.signIn(email: email, password: password)
            appState?.signIn(user: user)
            if rememberMe {
                try saveCredentials(email: email)
            }
        } catch let error as AuthError {
            errorMessage = error.errorDescription ?? "Authentication failed"
            showError = true
        } catch {
            errorMessage = (error as? ViewModelAuthError)?.localizedDescription
                           ?? error.localizedDescription
            showError = true
        }
    }

    func loginWithBiometric() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Simulate biometric authentication
            try await Task.sleep(nanoseconds: 2_000_000_000)
            // Continue to next screen
        } catch {
            errorMessage = "Biometric authentication failed"
            showError = true
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func saveCredentials(email: String) throws {
        // Save to Keychain
        let credentials = ["email": email]
        UserDefaults.standard.set(credentials, forKey: "savedCredentials")
    }
}

enum ViewModelAuthError: LocalizedError {
    case invalidEmail
    case invalidPassword
    case networkError
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPassword:
            return "Password must be at least 6 characters"
        case .networkError:
            return "Network connection error. Please try again."
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}
