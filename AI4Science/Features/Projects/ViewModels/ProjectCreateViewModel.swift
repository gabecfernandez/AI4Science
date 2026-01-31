import Foundation
import Observation

@Observable
@MainActor
final class ProjectCreateViewModel {
    var projectName = ""
    var projectDescription = ""
    var researchArea = "materials"
    var visibility = "private"
    var collaborators = ""
    var isLoading = false
    var showError = false
    var errorMessage = ""

    func createProject() async {
        guard !projectName.isEmpty else {
            errorMessage = "Project name is required"
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Validate inputs
            try validateInputs()

            // Simulate API call
            try await Task.sleep(nanoseconds: 2_000_000_000)

            // Project created successfully
            resetForm()
        } catch let error as ValidationError {
            errorMessage = error.message
            showError = true
        } catch {
            errorMessage = "Failed to create project"
            showError = true
        }
    }

    private func validateInputs() throws {
        let trimmedName = projectName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty && trimmedName.count >= 3 else {
            throw ValidationError(message: "Project name must be at least 3 characters")
        }

        if !projectDescription.isEmpty && projectDescription.count < 10 {
            throw ValidationError(message: "Description must be at least 10 characters")
        }

        // Validate collaborator emails if any
        if !collaborators.isEmpty {
            let emails = collaborators.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            for email in emails {
                guard isValidEmail(email) else {
                    throw ValidationError(message: "Invalid email: \(email)")
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func resetForm() {
        projectName = ""
        projectDescription = ""
        researchArea = "materials"
        visibility = "private"
        collaborators = ""
    }
}

struct ValidationError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}
