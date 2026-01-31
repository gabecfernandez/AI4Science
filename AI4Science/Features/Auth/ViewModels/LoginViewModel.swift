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

    func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Simulate network call
            try await Task.sleep(nanoseconds: 2_000_000_000)

            // Validate email format
            if !isValidEmail(email) {
                throw AuthError.invalidEmail
            }

            // Simulate successful login
            if password.count >= 6 {
                // Store credentials if remember me is selected
                if rememberMe {
                    try saveCredentials(email: email)
                }
                // Continue to next screen (handled by navigation)
            } else {
                throw AuthError.invalidPassword
            }
        } catch {
            errorMessage = (error as? AuthError)?.localizedDescription ?? error.localizedDescription
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

enum AuthError: LocalizedError {
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
