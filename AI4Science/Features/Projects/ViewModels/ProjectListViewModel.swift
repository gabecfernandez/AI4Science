import Foundation
import Observation

@Observable
@MainActor
final class ProjectsViewModel {
    var projects: [Project] = []
    var filterStatus: ProjectStatus? = nil
    var searchText: String = ""
    var isLoading = false
    var showError = false
    var errorMessage = ""

    private let repository: any ProjectRepositoryProtocol

    init(repository: any ProjectRepositoryProtocol) {
        self.repository = repository
    }

    var filteredProjects: [Project] {
        var result = projects
        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }
        if !searchText.isEmpty {
            let lower = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(lower) ||
                $0.description.lowercased().contains(lower)
            }
        }
        return result
    }

    func loadProjects() async {
        isLoading = true
        defer { isLoading = false }
        do {
            projects = try await repository.findAll()
        } catch {
            errorMessage = "Failed to load projects"
            showError = true
        }
    }

    func deleteProject(id: UUID) async {
        do {
            try await repository.delete(id)
            projects.removeAll { $0.id == id }
        } catch {
            errorMessage = "Failed to delete project"
            showError = true
        }
    }

    func refresh() async {
        await loadProjects()
    }
}
