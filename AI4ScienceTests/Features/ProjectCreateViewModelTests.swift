//
//  ProjectCreateViewModelTests.swift
//  AI4ScienceTests
//

import Testing
import Foundation
@testable import AI4Science

@Suite("ProjectCreateViewModel Tests")
@MainActor
struct ProjectCreateViewModelTests {

    @Test("Create mode initializes empty, canSubmit is false")
    func testCreateModeInitialState() {
        let repository = MockProjectRepository()
        let viewModel = ProjectCreateViewModel(repository: repository, ownerId: UUID())

        #expect(viewModel.name.isEmpty)
        #expect(viewModel.description.isEmpty)
        #expect(viewModel.isEditMode == false)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.canSubmit == false)
    }

    @Test("Edit mode pre-populates name and description")
    func testEditModeInitialState() {
        let repository = MockProjectRepository()
        let project = Project(
            id: UUID(),
            name: "Existing Project",
            description: "Existing description",
            ownerId: UUID(),
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )

        let viewModel = ProjectCreateViewModel(repository: repository, project: project)

        #expect(viewModel.name == "Existing Project")
        #expect(viewModel.description == "Existing description")
        #expect(viewModel.isEditMode == true)
    }

    @Test("Name too short produces validation error")
    func testNameTooShort() {
        let repository = MockProjectRepository()
        let viewModel = ProjectCreateViewModel(repository: repository, ownerId: UUID())

        viewModel.name = "ab"

        #expect(viewModel.nameValidationError != nil)
        #expect(viewModel.canSubmit == false)
    }

    @Test("Name too long produces validation error")
    func testNameTooLong() {
        let repository = MockProjectRepository()
        let viewModel = ProjectCreateViewModel(repository: repository, ownerId: UUID())

        viewModel.name = String(repeating: "x", count: 101)

        #expect(viewModel.nameValidationError != nil)
        #expect(viewModel.canSubmit == false)
    }

    @Test("Description too long produces validation error")
    func testDescriptionTooLong() {
        let repository = MockProjectRepository()
        let viewModel = ProjectCreateViewModel(repository: repository, ownerId: UUID())

        viewModel.name = "Valid Name"
        viewModel.description = String(repeating: "d", count: 501)

        #expect(viewModel.descriptionValidationError != nil)
        #expect(viewModel.canSubmit == false)
    }

    @Test("Valid create submits project with draft status")
    func testValidCreate() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectCreateViewModel(repository: repository, ownerId: UUID())

        viewModel.name = "New Project"
        viewModel.description = "A valid description"

        let result = await viewModel.submit()

        #expect(result != nil)
        #expect(result?.status == .draft)
        #expect(result?.name == "New Project")
        #expect(repository.savedProjects.count == 1)
    }

    @Test("Valid edit updates existing project")
    func testValidEdit() async {
        let repository = MockProjectRepository()
        let existingProject = Project(
            id: UUID(),
            name: "Original",
            description: "Original desc",
            ownerId: UUID(),
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )
        repository.savedProjects = [existingProject]

        let viewModel = ProjectCreateViewModel(repository: repository, project: existingProject)
        viewModel.name = "Updated Name"
        viewModel.description = "Updated desc"

        let result = await viewModel.submit()

        #expect(result != nil)
        #expect(result?.name == "Updated Name")
        #expect(repository.savedProjects.count == 1)
    }

    @Test("Empty name causes submit to return nil and show error")
    func testEmptyNameSubmit() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectCreateViewModel(repository: repository, ownerId: UUID())

        viewModel.name = ""

        let result = await viewModel.submit()

        #expect(result == nil)
        #expect(viewModel.showError == true)
    }
}
