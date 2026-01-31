import Foundation
import Observation

@Observable
@MainActor
final class ProjectDetailViewModel {
    var projectDetails: ProjectDetail?
    var isLoading = false
    var errorMessage = ""
    var showError = false

    struct ProjectDetail {
        let projectID: String
        let name: String
        let description: String
        let members: [String]
        let samples: [String]
        let createdDate: Date
        let lastModified: Date
    }

    func loadProjectDetails(for projectID: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 2_000_000_000)

            projectDetails = ProjectDetail(
                projectID: projectID,
                name: "Sample Project",
                description: "Project description",
                members: ["user1@example.com", "user2@example.com"],
                samples: ["sample1", "sample2", "sample3"],
                createdDate: Date().addingTimeInterval(-86400 * 30),
                lastModified: Date()
            )
        } catch {
            errorMessage = "Failed to load project details"
            showError = true
        }
    }

    func updateProjectDetails(
        name: String,
        description: String
    ) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_500_000_000)

            if var details = projectDetails {
                details.lastModified = Date()
                projectDetails = details
            }
        } catch {
            errorMessage = "Failed to update project details"
            showError = true
        }
    }

    func addSample(_ sampleID: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_000_000_000)

            if var details = projectDetails {
                details.samples.append(sampleID)
                details.lastModified = Date()
                projectDetails = details
            }
        } catch {
            errorMessage = "Failed to add sample"
            showError = true
        }
    }

    func removeSample(_ sampleID: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_000_000_000)

            if var details = projectDetails {
                details.samples.removeAll { $0 == sampleID }
                details.lastModified = Date()
                projectDetails = details
            }
        } catch {
            errorMessage = "Failed to remove sample"
            showError = true
        }
    }

    func inviteMember(_ email: String, role: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_500_000_000)

            if var details = projectDetails {
                details.members.append(email)
                details.lastModified = Date()
                projectDetails = details
            }
        } catch {
            errorMessage = "Failed to invite member"
            showError = true
        }
    }

    func removeMember(_ email: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_500_000_000)

            if var details = projectDetails {
                details.members.removeAll { $0 == email }
                details.lastModified = Date()
                projectDetails = details
            }
        } catch {
            errorMessage = "Failed to remove member"
            showError = true
        }
    }
}
