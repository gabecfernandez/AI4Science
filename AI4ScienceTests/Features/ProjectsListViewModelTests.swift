//
//  ProjectsListViewModelTests.swift
//  AI4ScienceTests
//
//  Tests for ProjectsListViewModel
//

import Testing
import Foundation
@testable import AI4Science

@Suite("ProjectsListViewModel Tests")
@MainActor
struct ProjectsListViewModelTests {

    // MARK: - Setup

    private func createViewModel(with repository: MockProjectRepository = MockProjectRepository()) -> ProjectsListViewModel {
        ProjectsListViewModel(repository: repository as! ProjectRepository)
    }

    private func createTestProjects() -> [Project] {
        [
            TestDataGenerator.createProject(
                title: "Materials Analysis 2024",
                description: "Comprehensive analysis of materials",
                status: .active
            ),
            TestDataGenerator.createProject(
                title: "Protein Study",
                description: "AI-driven protein analysis",
                status: .planning
            ),
            TestDataGenerator.createProject(
                title: "Crystal Growth",
                description: "Semiconductor crystal testing",
                status: .completed
            ),
            TestDataGenerator.createProject(
                title: "Archived Project",
                description: "An old archived project",
                status: .archived
            )
        ]
    }

    // MARK: - Load Projects Tests

    @Test("Load projects populates array")
    func testLoadProjectsPopulatesArray() async {
        let repository = MockProjectRepository()
        let projects = createTestProjects()
        await repository.addProjects(projects)

        let viewModel = ProjectsListViewModel(repository: repository as! ProjectRepository)
        await viewModel.loadProjects()

        #expect(viewModel.projects.count == 4)
        #expect(!viewModel.isLoading)
        #expect(viewModel.error == nil)
    }

    @Test("Load projects handles empty state")
    func testLoadProjectsEmptyState() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectsListViewModel(repository: repository as! ProjectRepository)

        await viewModel.loadProjects()

        #expect(viewModel.projects.isEmpty)
        #expect(viewModel.isEmpty)
        #expect(!viewModel.isLoading)
    }

    @Test("Load projects handles error")
    func testLoadProjectsHandlesError() async {
        let repository = MockProjectRepository()
        await repository.setErrorState(true)

        let viewModel = ProjectsListViewModel(repository: repository as! ProjectRepository)
        await viewModel.loadProjects()

        #expect(viewModel.error != nil)
        #expect(viewModel.projects.isEmpty)
    }

    // MARK: - Filter Tests

    @Test("Filter by status - active")
    func testFilterByStatusActive() async {
        let repository = MockProjectRepository()
        let projects = createTestProjects()
        await repository.addProjects(projects)

        let viewModel = ProjectsListViewModel(repository: repository as! ProjectRepository)
        await viewModel.loadProjects()

        viewModel.selectedStatus = .active
        // Allow filter to apply
        try? await Task.sleep(for: .milliseconds(50))

        #expect(viewModel.filteredProjects.count == 1)
        #expect(viewModel.filteredProjects.first?.status == .active)
    }

    @Test("Filter by status - all")
    func testFilterByStatusAll() async {
        let repository = MockProjectRepository()
        let projects = createTestProjects()
        await repository.addProjects(projects)

        let viewModel = ProjectsListViewModel(repository: repository as! ProjectRepository)
        await viewModel.loadProjects()

        viewModel.selectedStatus = .all

        #expect(viewModel.filteredProjects.count == 4)
    }

    @Test("Filter by status - draft (planning)")
    func testFilterByStatusDraft() async {
        let repository = MockProjectRepository()
        let projects = createTestProjects()
        await repository.addProjects(projects)

        let viewModel = ProjectsListViewModel(repository: repository as! ProjectRepository)
        await viewModel.loadProjects()

        viewModel.selectedStatus = .draft
        try? await Task.sleep(for: .milliseconds(50))

        #expect(viewModel.filteredProjects.allSatisfy { $0.status == .planning })
    }

    // MARK: - Search Tests

    @Test("Search filters by title")
    func testSearchFiltersByTitle() async {
        let repository = MockProjectRepository()
        let projects = createTestProjects()
        await repository.addProjects(projects)

        let viewModel = ProjectsListViewModel(repository: repository as! ProjectRepository)
        await viewModel.loadProjects()

        viewModel.searchText = "Materials"
        // Allow debounced search to complete
        try? await Task.sleep(for: .milliseconds(400))

        #expect(viewModel.filteredProjects.count == 1)
        #expect(viewModel.filteredProjects.first?.title.contains("Materials") == true)
    }

    @Test("Search filters by description")
    func testSearchFiltersByDescription() async {
        let repository = MockProjectRepository()
        let projects = createTestProjects()
        await repository.addProjects(projects)

        let viewModel = ProjectsListViewModel(repository: repository as! ProjectRepository)
        await viewModel.loadProjects()

        viewModel.searchText = "protein"
        try? await Task.sleep(for: .milliseconds(400))

        #expect(viewModel.filteredProjects.count == 1)
        #expect(viewModel.filteredProjects.first?.title == "Protein Study")
    }

    @Test("Search is case insensitive")
    func testSearchIsCaseInsensitive() async {
        let repository = MockProjectRepository()
        let projects = createTestProjects()
        await repository.addProjects(projects)

        let viewModel = ProjectsListViewModel(repository: repository as! ProjectRepository)
        await viewModel.loadProjects()

        viewModel.searchText = "CRYSTAL"
        try? await Task.sleep(for: .milliseconds(400))

        #expect(viewModel.filteredProjects.count == 1)
        #expect(viewModel.filteredProjects.first?.title == "Crystal Growth")
    }

    @Test("Search with no results")
    func testSearchNoResults() async {
        let repository = MockProjectRepository()
        let projects = createTestProjects()
        await repository.addProjects(projects)

        let viewModel = ProjectsListViewModel(repository: repository as! ProjectRepository)
        await viewModel.loadProjects()

        viewModel.searchText = "nonexistent"
        try? await Task.sleep(for: .milliseconds(400))

        #expect(viewModel.filteredProjects.isEmpty)
        #expect(viewModel.isFilteredEmpty)
    }

    @Test("Clear search shows all projects")
    func testClearSearchShowsAll() async {
        let repository = MockProjectRepository()
        let projects = createTestProjects()
        await repository.addProjects(projects)

        let viewModel = ProjectsListViewModel(repository: repository as! ProjectRepository)
        await viewModel.loadProjects()

        viewModel.searchText = "Materials"
        try? await Task.sleep(for: .milliseconds(400))
        #expect(viewModel.filteredProjects.count == 1)

        viewModel.searchText = ""
        try? await Task.sleep(for: .milliseconds(400))
        #expect(viewModel.filteredProjects.count == 4)
    }

    // MARK: - Delete Tests

    @Test("Delete project removes from list")
    func testDeleteProjectRemovesFromList() async {
        let repository = MockProjectRepository()
        let projects = createTestProjects()
        await repository.addProjects(projects)

        let viewModel = ProjectsListViewModel(repository: repository as! ProjectRepository)
        await viewModel.loadProjects()

        let projectToDelete = projects[0]
        await viewModel.deleteProject(projectToDelete.id)

        #expect(viewModel.projects.count == 3)
        #expect(!viewModel.projects.contains { $0.id == projectToDelete.id })
    }

    // MARK: - Refresh Tests

    @Test("Refresh reloads projects")
    func testRefreshReloadsProjects() async {
        let repository = MockProjectRepository()
        let projects = createTestProjects()
        await repository.addProjects(projects)

        let viewModel = ProjectsListViewModel(repository: repository as! ProjectRepository)
        await viewModel.loadProjects()

        #expect(viewModel.projects.count == 4)

        // Add a new project
        let newProject = TestDataGenerator.createProject(title: "New Project")
        await repository.addProjects([newProject])

        await viewModel.refresh()

        #expect(viewModel.projects.count == 5)
    }

    // MARK: - Computed Properties Tests

    @Test("Project count returns filtered count")
    func testProjectCountReturnsFilteredCount() async {
        let repository = MockProjectRepository()
        let projects = createTestProjects()
        await repository.addProjects(projects)

        let viewModel = ProjectsListViewModel(repository: repository as! ProjectRepository)
        await viewModel.loadProjects()

        #expect(viewModel.projectCount == 4)
        #expect(viewModel.totalProjectCount == 4)

        viewModel.selectedStatus = .active
        try? await Task.sleep(for: .milliseconds(50))

        #expect(viewModel.projectCount == 1)
        #expect(viewModel.totalProjectCount == 4)
    }
}

// MARK: - MockProjectRepository Test Extension

extension MockProjectRepository {
    func setErrorState(_ shouldError: Bool) {
        self.shouldThrowError = shouldError
    }
}
