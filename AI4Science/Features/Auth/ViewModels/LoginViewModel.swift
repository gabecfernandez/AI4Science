import Foundation
import Observation

@Observable
@MainActor
final class LoginViewModel {
    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?
    var isAuthenticated = false

    private let authService: (any AuthServiceProtocol)?

    init(authService: (any AuthServiceProtocol)? = nil) {
        self.authService = authService
    }

    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    var isPasswordValid: Bool {
        password.count >= 6
    }

    var canSubmit: Bool {
        isEmailValid && isPasswordValid && !isLoading
    }

    func login() async {
        isLoading = true
        defer { isLoading = false }

        guard let service = authService else {
            isAuthenticated = true
            return
        }

        do {
            _ = try await service.login(email: email, password: password)
            isAuthenticated = true
            errorMessage = nil
        } catch {
            isAuthenticated = false
            errorMessage = error.localizedDescription
        }
    }
}

