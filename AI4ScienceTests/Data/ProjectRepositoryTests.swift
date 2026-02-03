//
//  ProjectRepositoryTests.swift
//  AI4ScienceTests
//
//  Tests for ProjectRepository
//

import Testing
import Foundation
import SwiftData
@testable import AI4Science

@Suite("ProjectRepository Tests")
struct ProjectRepositoryTests {

    // MARK: - Save Tests

    @Test("Save project persists to storage")
    @MainActor
    func testSaveProject() async throws {
        let container = try TestContainerFactory.createInMemoryContainer(for: ProjectEntity.self)
        let repository = ProjectRepository(modelContext: container.mainContext)

        let project = TestDataGenerator.createProject(
            title: "Test Project",
            description: "A test description"
        )

        try await repository.save(project)

        let fetched = try await repository.findById(project.id)
        #expect(fetched != nil)
        #expect(fetched?.title == "Test Project")
        #expect(fetched?.description == "A test description")
    }

    @Test("Save multiple projects")
    @MainActor
    func testSaveMultipleProjects() async throws {
        let container = try TestContainerFactory.createInMemoryContainer(for: ProjectEntity.self)
        let repository = ProjectRepository(modelContext: container.mainContext)

        let project1 = TestDataGenerator.createProject(title: "Project 1")
        let project2 = TestDataGenerator.createProject(title: "Project 2")
        let project3 = TestDataGenerator.createProject(title: "Project 3")

        try await repository.save(project1)
        try await repository.save(project2)
        try await repository.save(project3)

        let allProjects = try await repository.findAll()
        #expect(allProjects.count == 3)
    }

    // MARK: - Find Tests

    @Test("FindById returns correct project")
    @MainActor
    func testFindById() async throws {
        let container = try TestContainerFactory.createInMemoryContainer(for: ProjectEntity.self)
        let repository = ProjectRepository(modelContext: container.mainContext)

        let project = TestDataGenerator.createProject(title: "Find Me")
        try await repository.save(project)

        let found = try await repository.findById(project.id)

        #expect(found != nil)
        #expect(found?.id == project.id)
        #expect(found?.title == "Find Me")
    }

    @Test("FindById returns nil for non-existent ID")
    @MainActor
    func testFindByIdNonExistent() async throws {
        let container = try TestContainerFactory.createInMemoryContainer(for: ProjectEntity.self)
        let repository = ProjectRepository(modelContext: container.mainContext)

        let found = try await repository.findById(UUID())

        #expect(found == nil)
    }

    @Test("FindAll returns all projects sorted by createdAt")
    @MainActor
    func testFindAll() async throws {
        let container = try TestContainerFactory.createInMemoryContainer(for: ProjectEntity.self)
        let repository = ProjectRepository(modelContext: container.mainContext)

        let now = Date()
        var project1 = TestDataGenerator.createProject(title: "Old Project")
        project1 = Project(
            id: project1.id,
            title: project1.title,
            description: project1.description,
            status: project1.status,
            principalInvestigatorID: project1.principalInvestigatorID,
            labAffiliation: project1.labAffiliation,
            createdAt: now.addingTimeInterval(-3600)
        )

        var project2 = TestDataGenerator.createProject(title: "New Project")
        project2 = Project(
            id: project2.id,
            title: project2.title,
            description: project2.description,
            status: project2.status,
            principalInvestigatorID: project2.principalInvestigatorID,
            labAffiliation: project2.labAffiliation,
            createdAt: now
        )

        try await repository.save(project1)
        try await repository.save(project2)

        let allProjects = try await repository.findAll()

        #expect(allProjects.count == 2)
        // Sorted by createdAt descending, so newest first
        #expect(allProjects.first?.title == "New Project")
    }

    // MARK: - Update Tests

    @Test("Update project modifies storage")
    @MainActor
    func testUpdateProject() async throws {
        let container = try TestContainerFactory.createInMemoryContainer(for: ProjectEntity.self)
        let repository = ProjectRepository(modelContext: container.mainContext)

        var project = TestDataGenerator.createProject(title: "Original Title")
        try await repository.save(project)

        project.title = "Updated Title"
        project.description = "Updated description"
        try await repository.update(project)

        let fetched = try await repository.findById(project.id)
        #expect(fetched?.title == "Updated Title")
        #expect(fetched?.description == "Updated description")
    }

    @Test("Update non-existent project throws error")
    @MainActor
    func testUpdateNonExistentProject() async throws {
        let container = try TestContainerFactory.createInMemoryContainer(for: ProjectEntity.self)
        let repository = ProjectRepository(modelContext: container.mainContext)

        let project = TestDataGenerator.createProject(title: "Non-existent")

        await #expect(throws: RepositoryError.self) {
            try await repository.update(project)
        }
    }

    // MARK: - Delete Tests

    @Test("Delete project removes from storage")
    @MainActor
    func testDeleteProject() async throws {
        let container = try TestContainerFactory.createInMemoryContainer(for: ProjectEntity.self)
        let repository = ProjectRepository(modelContext: container.mainContext)

        let project = TestDataGenerator.createProject(title: "To Delete")
        try await repository.save(project)

        let beforeDelete = try await repository.findById(project.id)
        #expect(beforeDelete != nil)

        try await repository.delete(project.id)

        let afterDelete = try await repository.findById(project.id)
        #expect(afterDelete == nil)
    }

    @Test("Delete non-existent project throws error")
    @MainActor
    func testDeleteNonExistentProject() async throws {
        let container = try TestContainerFactory.createInMemoryContainer(for: ProjectEntity.self)
        let repository = ProjectRepository(modelContext: container.mainContext)

        await #expect(throws: RepositoryError.self) {
            try await repository.delete(UUID())
        }
    }

    // MARK: - Search Tests

    @Test("Search by title finds matching projects")
    @MainActor
    func testSearchByTitle() async throws {
        let container = try TestContainerFactory.createInMemoryContainer(for: ProjectEntity.self)
        let repository = ProjectRepository(modelContext: container.mainContext)

        let project1 = TestDataGenerator.createProject(title: "Materials Analysis")
        let project2 = TestDataGenerator.createProject(title: "Protein Study")
        let project3 = TestDataGenerator.createProject(title: "Crystal Materials")

        try await repository.save(project1)
        try await repository.save(project2)
        try await repository.save(project3)

        let results = try await repository.search(query: "Materials")

        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.title.contains("Materials") })
    }

    @Test("Search by description finds matching projects")
    @MainActor
    func testSearchByDescription() async throws {
        let container = try TestContainerFactory.createInMemoryContainer(for: ProjectEntity.self)
        let repository = ProjectRepository(modelContext: container.mainContext)

        let project1 = TestDataGenerator.createProject(
            title: "Project A",
            description: "Analysis of steel samples"
        )
        let project2 = TestDataGenerator.createProject(
            title: "Project B",
            description: "Testing aluminum properties"
        )

        try await repository.save(project1)
        try await repository.save(project2)

        let results = try await repository.search(query: "steel")

        #expect(results.count == 1)
        #expect(results.first?.title == "Project A")
    }

    @Test("Search with no matches returns empty")
    @MainActor
    func testSearchNoMatches() async throws {
        let container = try TestContainerFactory.createInMemoryContainer(for: ProjectEntity.self)
        let repository = ProjectRepository(modelContext: container.mainContext)

        let project = TestDataGenerator.createProject(title: "Test Project")
        try await repository.save(project)

        let results = try await repository.search(query: "nonexistent")

        #expect(results.isEmpty)
    }

    // MARK: - Filter by Status Tests

    @Test("Filter by status returns matching projects")
    @MainActor
    func testFilterByStatus() async throws {
        let container = try TestContainerFactory.createInMemoryContainer(for: ProjectEntity.self)
        let repository = ProjectRepository(modelContext: container.mainContext)

        let activeProject = TestDataGenerator.createProject(title: "Active", status: .active)
        let planningProject = TestDataGenerator.createProject(title: "Planning", status: .planning)
        let archivedProject = TestDataGenerator.createProject(title: "Archived", status: .archived)

        try await repository.save(activeProject)
        try await repository.save(planningProject)
        try await repository.save(archivedProject)

        let activeResults = try await repository.filterByStatus(.active)
        #expect(activeResults.count == 1)
        #expect(activeResults.first?.title == "Active")

        let planningResults = try await repository.filterByStatus(.planning)
        #expect(planningResults.count == 1)
        #expect(planningResults.first?.title == "Planning")

        let archivedResults = try await repository.filterByStatus(.archived)
        #expect(archivedResults.count == 1)
        #expect(archivedResults.first?.title == "Archived")
    }

    @Test("Filter by status with no matches returns empty")
    @MainActor
    func testFilterByStatusNoMatches() async throws {
        let container = try TestContainerFactory.createInMemoryContainer(for: ProjectEntity.self)
        let repository = ProjectRepository(modelContext: container.mainContext)

        let activeProject = TestDataGenerator.createProject(title: "Active", status: .active)
        try await repository.save(activeProject)

        let results = try await repository.filterByStatus(.completed)

        #expect(results.isEmpty)
    }

    // MARK: - Archive Tests

    @Test("Archive project changes status")
    @MainActor
    func testArchiveProject() async throws {
        let container = try TestContainerFactory.createInMemoryContainer(for: ProjectEntity.self)
        let repository = ProjectRepository(modelContext: container.mainContext)

        let project = TestDataGenerator.createProject(title: "To Archive", status: .active)
        try await repository.save(project)

        try await repository.archiveProject(id: project.id.uuidString)

        let archived = try await repository.findById(project.id)
        #expect(archived?.status == .archived)
    }

    @Test("Unarchive project changes status")
    @MainActor
    func testUnarchiveProject() async throws {
        let container = try TestContainerFactory.createInMemoryContainer(for: ProjectEntity.self)
        let repository = ProjectRepository(modelContext: container.mainContext)

        let project = TestDataGenerator.createProject(title: "Archived", status: .archived)
        try await repository.save(project)

        try await repository.unarchiveProject(id: project.id.uuidString)

        let unarchived = try await repository.findById(project.id)
        #expect(unarchived?.status == .active)
    }
}
