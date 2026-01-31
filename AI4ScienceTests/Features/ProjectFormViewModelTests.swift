//
//  ProjectFormViewModelTests.swift
//  AI4ScienceTests
//
//  Tests for ProjectFormViewModel
//

import Testing
import Foundation
@testable import AI4Science

@Suite("ProjectFormViewModel Tests")
@MainActor
struct ProjectFormViewModelTests {

    // MARK: - Title Validation Tests

    @Test("Title validation - empty title is invalid")
    func testTitleValidationEmpty() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.title = ""
        viewModel.validateTitle()

        #expect(viewModel.titleError != nil)
        #expect(viewModel.titleError == "Title is required")
        #expect(!viewModel.isFormValid)
    }

    @Test("Title validation - too short title is invalid")
    func testTitleValidationTooShort() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.title = "AB"
        viewModel.validateTitle()

        #expect(viewModel.titleError != nil)
        #expect(viewModel.titleError == "Title must be at least 3 characters")
    }

    @Test("Title validation - minimum length is valid")
    func testTitleValidationMinimumLength() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.title = "ABC"
        viewModel.validateTitle()

        #expect(viewModel.titleError == nil)
    }

    @Test("Title validation - too long title is invalid")
    func testTitleValidationTooLong() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.title = String(repeating: "A", count: 101)
        viewModel.validateTitle()

        #expect(viewModel.titleError != nil)
        #expect(viewModel.titleError == "Title must be 100 characters or less")
    }

    @Test("Title validation - maximum length is valid")
    func testTitleValidationMaximumLength() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.title = String(repeating: "A", count: 100)
        viewModel.validateTitle()

        #expect(viewModel.titleError == nil)
    }

    @Test("Title validation - whitespace only is invalid")
    func testTitleValidationWhitespaceOnly() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.title = "   "
        viewModel.validateTitle()

        #expect(viewModel.titleError != nil)
        #expect(viewModel.titleError == "Title is required")
    }

    // MARK: - Description Validation Tests

    @Test("Description validation - empty is valid")
    func testDescriptionValidationEmpty() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.descriptionText = ""
        viewModel.validateDescription()

        #expect(viewModel.descriptionError == nil)
    }

    @Test("Description validation - within limit is valid")
    func testDescriptionValidationWithinLimit() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.descriptionText = "A valid description within the character limit."
        viewModel.validateDescription()

        #expect(viewModel.descriptionError == nil)
    }

    @Test("Description validation - exactly at limit is valid")
    func testDescriptionValidationAtLimit() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.descriptionText = String(repeating: "A", count: 500)
        viewModel.validateDescription()

        #expect(viewModel.descriptionError == nil)
    }

    @Test("Description validation - exceeds limit is invalid")
    func testDescriptionValidationExceedsLimit() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.descriptionText = String(repeating: "A", count: 501)
        viewModel.validateDescription()

        #expect(viewModel.descriptionError != nil)
        #expect(viewModel.descriptionError == "Description must be 500 characters or less")
    }

    // MARK: - isDirty Tests

    @Test("isDirty - new form starts clean")
    func testIsDirtyNewFormStartsClean() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        #expect(!viewModel.isDirty)
    }

    @Test("isDirty - title change makes form dirty")
    func testIsDirtyTitleChange() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.title = "New Title"

        #expect(viewModel.isDirty)
    }

    @Test("isDirty - description change makes form dirty")
    func testIsDirtyDescriptionChange() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.descriptionText = "New description"

        #expect(viewModel.isDirty)
    }

    @Test("isDirty - project type change makes form dirty")
    func testIsDirtyProjectTypeChange() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.projectType = .biology

        #expect(viewModel.isDirty)
    }

    @Test("isDirty - edit mode starts clean")
    func testIsDirtyEditModeStartsClean() async {
        let repository = MockProjectRepository()
        let project = TestDataGenerator.createProject(title: "Test Project")
        let viewModel = ProjectFormViewModel(mode: .edit(project), repository: repository as! ProjectRepository)

        #expect(!viewModel.isDirty)
    }

    @Test("isDirty - edit mode becomes dirty on change")
    func testIsDirtyEditModeBecomesDirty() async {
        let repository = MockProjectRepository()
        let project = TestDataGenerator.createProject(title: "Test Project")
        let viewModel = ProjectFormViewModel(mode: .edit(project), repository: repository as! ProjectRepository)

        viewModel.title = "Modified Title"

        #expect(viewModel.isDirty)
    }

    // MARK: - isFormValid Tests

    @Test("isFormValid - valid form")
    func testIsFormValidTrue() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.title = "Valid Project Title"
        viewModel.descriptionText = "A valid description"

        #expect(viewModel.isFormValid)
    }

    @Test("isFormValid - invalid with short title")
    func testIsFormValidFalseShortTitle() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.title = "AB"
        viewModel.descriptionText = "A valid description"

        #expect(!viewModel.isFormValid)
    }

    @Test("isFormValid - invalid with long description")
    func testIsFormValidFalseLongDescription() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.title = "Valid Title"
        viewModel.descriptionText = String(repeating: "A", count: 501)

        #expect(!viewModel.isFormValid)
    }

    // MARK: - Save Tests

    @Test("Save - creates project successfully")
    func testSaveCreatesProject() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.title = "New Test Project"
        viewModel.descriptionText = "Test description"
        viewModel.projectType = .materialsScience

        await viewModel.save()

        #expect(viewModel.isSaved)
        #expect(viewModel.saveError == nil)
        #expect(await repository.saveCallCount == 1)
    }

    @Test("Save - updates project successfully")
    func testSaveUpdatesProject() async {
        let repository = MockProjectRepository()
        let project = TestDataGenerator.createProject(title: "Original Title")
        await repository.addProjects([project])

        let viewModel = ProjectFormViewModel(mode: .edit(project), repository: repository as! ProjectRepository)
        viewModel.title = "Updated Title"

        await viewModel.save()

        #expect(viewModel.isSaved)
        #expect(viewModel.saveError == nil)
        #expect(await repository.updateCallCount == 1)
    }

    @Test("Save - does not save invalid form")
    func testSaveDoesNotSaveInvalidForm() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.title = "AB" // Too short

        await viewModel.save()

        #expect(!viewModel.isSaved)
        #expect(await repository.saveCallCount == 0)
    }

    @Test("Save - handles error")
    func testSaveHandlesError() async {
        let repository = MockProjectRepository()
        await repository.setErrorState(true)

        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)
        viewModel.title = "Valid Title"

        await viewModel.save()

        #expect(!viewModel.isSaved)
        #expect(viewModel.saveError != nil)
    }

    // MARK: - Reset Tests

    @Test("Reset - clears create form")
    func testResetClearsCreateForm() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.title = "Test Title"
        viewModel.descriptionText = "Test description"
        viewModel.projectType = .biology

        viewModel.reset()

        #expect(viewModel.title.isEmpty)
        #expect(viewModel.descriptionText.isEmpty)
        #expect(viewModel.projectType == .materialsScience)
        #expect(!viewModel.isDirty)
    }

    @Test("Reset - restores edit form to original")
    func testResetRestoresEditForm() async {
        let repository = MockProjectRepository()
        let project = TestDataGenerator.createProject(
            title: "Original Title",
            description: "Original description"
        )
        let viewModel = ProjectFormViewModel(mode: .edit(project), repository: repository as! ProjectRepository)

        viewModel.title = "Modified Title"
        viewModel.descriptionText = "Modified description"

        viewModel.reset()

        #expect(viewModel.title == "Original Title")
        #expect(viewModel.descriptionText == "Original description")
        #expect(!viewModel.isDirty)
    }

    // MARK: - Character Count Tests

    @Test("Title character count is accurate")
    func testTitleCharacterCount() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.title = "Hello World"

        #expect(viewModel.titleCharacterCount == 11)
    }

    @Test("Description character count is accurate")
    func testDescriptionCharacterCount() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        viewModel.descriptionText = "This is a test description."

        #expect(viewModel.descriptionCharacterCount == 27)
    }

    // MARK: - Mode Tests

    @Test("Mode - create mode properties")
    func testCreateModeProperties() async {
        let repository = MockProjectRepository()
        let viewModel = ProjectFormViewModel(mode: .create, repository: repository as! ProjectRepository)

        #expect(!viewModel.mode.isEditing)
        #expect(viewModel.mode.existingProject == nil)
        #expect(viewModel.navigationTitle == "Create Project")
        #expect(viewModel.saveButtonTitle == "Create Project")
    }

    @Test("Mode - edit mode properties")
    func testEditModeProperties() async {
        let repository = MockProjectRepository()
        let project = TestDataGenerator.createProject(title: "Test Project")
        let viewModel = ProjectFormViewModel(mode: .edit(project), repository: repository as! ProjectRepository)

        #expect(viewModel.mode.isEditing)
        #expect(viewModel.mode.existingProject?.id == project.id)
        #expect(viewModel.navigationTitle == "Edit Project")
        #expect(viewModel.saveButtonTitle == "Save Changes")
    }

    // MARK: - Edit Mode Initialization Tests

    @Test("Edit mode populates fields from project")
    func testEditModePopulatesFields() async {
        let repository = MockProjectRepository()
        let project = TestDataGenerator.createProject(
            title: "Test Project",
            description: "Test description"
        )
        let viewModel = ProjectFormViewModel(mode: .edit(project), repository: repository as! ProjectRepository)

        #expect(viewModel.title == "Test Project")
        #expect(viewModel.descriptionText == "Test description")
    }
}
