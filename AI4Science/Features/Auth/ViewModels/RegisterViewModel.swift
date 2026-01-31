import Foundation
import Observation

@Observable
@MainActor
final class RegisterViewModel {
    var fullName = ""
    var email = ""
    var password = ""
    var confirmPassword = ""
    var institution = ""
    var agreedToTerms = false
    var isLoading = false
    var showError = false
    var errorMessage = ""

    var emailValidationMessage = ""
    var isEmailValid = false
    var passwordStrength: PasswordStrength = .weak

    enum PasswordStrength {
        case weak
        case fair
        case good
        case strong
    }

    init() {}

    func register() async {
        guard validateForm() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Simulate network call
            try await Task.sleep(nanoseconds: 2_000_000_000)

            // Save user data
            try saveUserData()
            // Continue to next screen (handled by navigation)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func validateForm() -> Bool {
        // Validate full name
        guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your full name"
            showError = true
            return false
        }

        // Validate email
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            showError = true
            return false
        }

        // Validate password
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            showError = true
            return false
        }

        // Validate password match
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showError = true
            return false
        }

        // Validate terms
        guard agreedToTerms else {
            errorMessage = "You must agree to the Terms of Service"
            showError = true
            return false
        }

        return true
    }

    var isFormValid: Bool {
        !fullName.isEmpty &&
        isEmailValid &&
        passwordStrength != .weak &&
        password == confirmPassword &&
        !password.isEmpty &&
        agreedToTerms
    }

    func validateEmail(_ email: String) {
        self.email = email

        if email.isEmpty {
            emailValidationMessage = ""
            isEmailValid = false
            return
        }

        let isValid = isValidEmail(email)
        isEmailValid = isValid
        emailValidationMessage = isValid ? "Valid email" : "Invalid email format"
    }

    func validatePassword(_ password: String) {
        self.password = password
        updatePasswordStrength()
    }

    private func updatePasswordStrength() {
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumbers = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        let lengthScore = password.count

        let strengthScore = [hasUppercase, hasLowercase, hasNumbers, hasSpecial].filter { $0 }.count

        if lengthScore < 8 {
            passwordStrength = .weak
        } else if strengthScore <= 1 {
            passwordStrength = .weak
        } else if strengthScore == 2 {
            passwordStrength = .fair
        } else if strengthScore == 3 {
            passwordStrength = .good
        } else {
            passwordStrength = .strong
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func saveUserData() throws {
        let userData = [
            "fullName": fullName,
            "email": email,
            "institution": institution
        ]
        UserDefaults.standard.set(userData, forKey: "userData")
    }
}
