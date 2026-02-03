import Foundation
import Observation

// Required for Supabase authentication integration

@Observable
@MainActor
final class LoginViewModel {
    var email = ""
    var password = ""
    var rememberMe = false
    var isLoading = false
    var showError = false
    var errorMessage = ""

    // Dependencies
    private let authService: SupabaseAuthenticationService
    private let appState: AppState

    init(authService: SupabaseAuthenticationService, appState: AppState) {
        self.authService = authService
        self.appState = appState
    }

    func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Authenticate with Supabase
            let session = try await authService.signIn(email: email, password: password)

            // Store credentials if remember me is selected
            if rememberMe {
                try saveCredentials(email: email)
            }

            // Update app state with authenticated user
            await appState.checkAuthenticationState(serviceContainer: ServiceContainer.shared)

            AppLogger.info("User logged in successfully: \(session.email)")

        } catch let error as ServiceAuthError {
            // Map Supabase auth errors to user-friendly messages
            errorMessage = error.localizedDescription ?? "Sign-in failed"
            showError = true
            AppLogger.error("Login failed: \(error)")
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
            showError = true
            AppLogger.error("Login failed with unexpected error: \(error)")
        }
    }

    func loginWithBiometric() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Attempt biometric authentication via Supabase service
            // Note: This is currently stubbed in SupabaseAuthenticationService
            let session = try await authService.authenticateWithBiometric()

            // Update app state with authenticated user
            await appState.checkAuthenticationState(serviceContainer: ServiceContainer.shared)

            AppLogger.info("User logged in with biometric: \(session.email)")

        } catch ServiceAuthError.biometricNotAvailable {
            errorMessage = "Biometric authentication is not yet available. Please use email and password."
            showError = true
        } catch let error as ServiceAuthError {
            errorMessage = error.localizedDescription ?? "Biometric authentication failed"
            showError = true
        } catch {
            errorMessage = "Biometric authentication failed. Please try again."
            showError = true
        }
    }

    private func saveCredentials(email: String) throws {
        // Save email to UserDefaults (password should never be stored here)
        UserDefaults.standard.set(email, forKey: "savedEmail")
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
