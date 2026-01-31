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

    func loadProjects() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 2_000_000_000)

            // Create sample projects
            projects = [
                Project(
                    id: "1",
                    name: "Materials Analysis 2024",
                    description: "Comprehensive analysis of novel composite materials",
                    status: .active,
                    sampleCount: 24,
                    memberCount: 5,
                    createdDate: Date().addingTimeInterval(-86400 * 30)
                ),
                Project(
                    id: "2",
                    name: "Protein Structure Study",
                    description: "AI-driven protein folding predictions",
                    status: .active,
                    sampleCount: 15,
                    memberCount: 3,
                    createdDate: Date().addingTimeInterval(-86400 * 60)
                ),
                Project(
                    id: "3",
                    name: "Crystal Growth Optimization",
                    description: "Testing growth parameters for semiconductor crystals",
                    status: .paused,
                    sampleCount: 8,
                    memberCount: 2,
                    createdDate: Date().addingTimeInterval(-86400 * 90)
                )
            ]
        } catch {
            errorMessage = "Failed to load projects"
            showError = true
        }
    }

    func deleteProject(_ projectID: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_500_000_000)

            projects.removeAll { $0.id == projectID }
        } catch {
            errorMessage = "Failed to delete project"
            showError = true
        }
    }

    func archiveProject(_ projectID: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_500_000_000)

            if let index = projects.firstIndex(where: { $0.id == projectID }) {
                // Update project status
            }
        } catch {
            errorMessage = "Failed to archive project"
            showError = true
        }
    }
}
