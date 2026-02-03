import Foundation
import Observation

@Observable
@MainActor
final class ProjectListViewModel {
    var projects: [Project] = []
    var isLoading = false
    var errorMessage = ""
    var showError = false
    var searchText = ""

    private let demoUserID = UUID()

    func loadProjects() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 500_000_000)

            // Create sample projects
            projects = [
                Project(
                    title: "Materials Analysis 2024",
                    description: "Comprehensive analysis of novel composite materials",
                    status: .active,
                    principalInvestigatorID: demoUserID,
                    labAffiliation: .placeholder,
                    createdAt: Date().addingTimeInterval(-86400 * 30)
                ),
                Project(
                    title: "Protein Structure Study",
                    description: "AI-driven protein folding predictions",
                    status: .active,
                    principalInvestigatorID: demoUserID,
                    labAffiliation: .placeholder,
                    createdAt: Date().addingTimeInterval(-86400 * 60)
                ),
                Project(
                    title: "Crystal Growth Optimization",
                    description: "Testing growth parameters for semiconductor crystals",
                    status: .onHold,
                    principalInvestigatorID: demoUserID,
                    labAffiliation: .placeholder,
                    createdAt: Date().addingTimeInterval(-86400 * 90)
                )
            ]
        } catch {
            errorMessage = "Failed to load projects"
            showError = true
        }
    }

    func deleteProject(_ projectID: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 500_000_000)

            projects.removeAll { $0.id == projectID }
        } catch {
            errorMessage = "Failed to delete project"
            showError = true
        }
    }

    func archiveProject(_ projectID: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 500_000_000)

            if let index = projects.firstIndex(where: { $0.id == projectID }) {
                // Update project status
                _ = index // Placeholder
            }
        } catch {
            errorMessage = "Failed to archive project"
            showError = true
        }
    }
}
