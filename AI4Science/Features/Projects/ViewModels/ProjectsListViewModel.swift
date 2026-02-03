import Foundation
import Observation

/// Filter options for project status
enum ProjectStatusFilter: String, CaseIterable, Sendable {
    case all = "All"
    case draft = "Draft"
    case active = "Active"
    case completed = "Completed"
    case archived = "Archived"

    var projectStatus: ProjectStatus? {
        switch self {
        case .all: return nil
        case .draft: return .planning
        case .active: return .active
        case .completed: return .completed
        case .archived: return .archived
        }
    }
}

@Observable
@MainActor
final class ProjectsListViewModel {
    // MARK: - Published Properties

    private(set) var projects: [Project] = []
    private(set) var filteredProjects: [Project] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    var searchText = "" {
        didSet {
            debouncedSearch(searchText)
        }
    }

    var selectedStatus: ProjectStatusFilter = .all {
        didSet {
            Task { await applyFilters() }
        }
    }

    // MARK: - Private Properties

    private let repository: ProjectRepository
    private var searchTask: Task<Void, Never>?

    // MARK: - Initialization

    init(repository: ProjectRepository) {
        self.repository = repository
    }

    // MARK: - Public Methods

    /// Load all projects from repository
    func loadProjects() async {
        isLoading = true
        error = nil

        do {
            projects = try await repository.findAll()
            await applyFilters()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Refresh projects (pull-to-refresh)
    func refresh() async {
        await loadProjects()
    }

    /// Delete a project by ID
    func deleteProject(_ id: UUID) async {
        isLoading = true
        error = nil

        do {
            try await repository.delete(id)
            projects.removeAll { $0.id == id }
            await applyFilters()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Archive a project by ID
    func archiveProject(_ id: UUID) async {
        isLoading = true
        error = nil

        do {
            try await repository.archiveProject(id: id.uuidString)
            await loadProjects()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Clear any displayed error
    func clearError() {
        error = nil
    }

    // MARK: - Private Methods

    /// Debounced search with 300ms delay
    private func debouncedSearch(_ query: String) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await applyFilters()
        }
    }

    /// Apply search and status filters to projects
    private func applyFilters() async {
        var result = projects

        // Apply status filter
        if let status = selectedStatus.projectStatus {
            result = result.filter { $0.status == status }
        }

        // Apply search filter
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            result = result.filter { project in
                project.title.localizedCaseInsensitiveContains(trimmedSearch) ||
                project.description.localizedCaseInsensitiveContains(trimmedSearch) ||
                project.tags.contains { $0.localizedCaseInsensitiveContains(trimmedSearch) }
            }
        }

        filteredProjects = result
    }
}

// MARK: - Convenience Extensions

extension ProjectsListViewModel {
    /// Check if there are any projects to display
    var isEmpty: Bool {
        filteredProjects.isEmpty && !isLoading
    }

    /// Check if current filter/search yields no results but projects exist
    var isFilteredEmpty: Bool {
        filteredProjects.isEmpty && !projects.isEmpty && !isLoading
    }

    /// Get error message for display
    var errorMessage: String? {
        error?.localizedDescription
    }

    /// Count of projects matching current filter
    var projectCount: Int {
        filteredProjects.count
    }

    /// Count of total projects (unfiltered)
    var totalProjectCount: Int {
        projects.count
    }
}
