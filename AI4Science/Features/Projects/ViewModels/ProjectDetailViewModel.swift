import Foundation
import Observation

@Observable
@MainActor
final class ProjectDetailViewModel {
    // MARK: - Published Properties

    private(set) var project: Project?
    private(set) var isLoading = false
    private(set) var error: Error?
    var showDeleteConfirmation = false
    var showEditSheet = false

    // MARK: - Private Properties

    private let repository: ProjectRepository
    private let projectId: UUID

    // MARK: - Initialization

    init(projectId: UUID, repository: ProjectRepository) {
        self.projectId = projectId
        self.repository = repository
    }

    // MARK: - Public Methods

    /// Load project details from repository
    func loadProject() async {
        isLoading = true
        error = nil

        do {
            project = try await repository.findById(projectId)
            if project == nil {
                error = RepositoryError.notFound
            }
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Refresh project data
    func refresh() async {
        await loadProject()
    }

    /// Delete the current project
    func deleteProject() async {
        guard project != nil else { return }

        isLoading = true
        error = nil

        do {
            try await repository.delete(projectId)
            project = nil
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Archive the current project
    func archiveProject() async {
        guard var currentProject = project else { return }

        isLoading = true
        error = nil

        do {
            currentProject.status = .archived
            currentProject.updatedAt = Date()
            try await repository.update(currentProject)
            project = currentProject
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Unarchive the current project
    func unarchiveProject() async {
        guard var currentProject = project else { return }

        isLoading = true
        error = nil

        do {
            currentProject.status = .active
            currentProject.updatedAt = Date()
            try await repository.update(currentProject)
            project = currentProject
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Update project status
    func updateStatus(_ status: ProjectStatus) async {
        guard var currentProject = project else { return }

        isLoading = true
        error = nil

        do {
            currentProject.status = status
            currentProject.updatedAt = Date()
            try await repository.update(currentProject)
            project = currentProject
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Clear any error state
    func clearError() {
        error = nil
    }
}

// MARK: - Computed Properties

extension ProjectDetailViewModel {
    var errorMessage: String? {
        error?.localizedDescription
    }

    var isArchived: Bool {
        project?.status == .archived
    }

    var canEdit: Bool {
        project != nil && !isLoading
    }

    var canDelete: Bool {
        project != nil && !isLoading
    }

    var projectTitle: String {
        project?.title ?? "Loading..."
    }

    var projectDescription: String {
        project?.description ?? ""
    }

    var sampleCount: Int {
        project?.sampleCount ?? 0
    }

    var participantCount: Int {
        project?.participantCount ?? 0
    }

    var formattedStartDate: String {
        guard let date = project?.startDate else { return "N/A" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    var formattedCreatedDate: String {
        guard let date = project?.createdAt else { return "N/A" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    var formattedUpdatedDate: String {
        guard let date = project?.updatedAt else { return "N/A" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    var statusDisplayName: String {
        guard let status = project?.status else { return "Unknown" }
        switch status {
        case .planning: return "Draft"
        case .active: return "Active"
        case .onHold: return "On Hold"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }

    var tags: [String] {
        project?.tags ?? []
    }
}
