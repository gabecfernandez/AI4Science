import Foundation
import Observation

@Observable
@MainActor
final class ProjectDetailViewModel {
    var project: Project?
    var isLoading = false
    var showError = false
    var errorMessage = ""
    var showDeleteConfirmation = false

    private let repository: any ProjectRepositoryProtocol

    init(repository: any ProjectRepositoryProtocol) {
        self.repository = repository
    }

    func loadProject(id: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            project = try await repository.findById(id)
            if project == nil {
                showError = true
                errorMessage = "Project not found"
            }
        } catch {
            showError = true
            errorMessage = "Failed to load project"
        }
    }

    func deleteProject() async -> Bool {
        guard let proj = project else { return false }
        do {
            try await repository.delete(proj.id)
            return true
        } catch {
            showError = true
            errorMessage = "Failed to delete project"
            return false
        }
    }
}
