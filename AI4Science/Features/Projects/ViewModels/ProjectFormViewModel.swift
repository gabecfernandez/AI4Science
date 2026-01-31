import Foundation
import Observation

/// Project type options
enum ProjectType: String, CaseIterable, Sendable {
    case materialsScience = "materials_science"
    case biology = "biology"
    case chemistry = "chemistry"
    case physics = "physics"
    case engineering = "engineering"
    case other = "other"

    var displayName: String {
        switch self {
        case .materialsScience: return "Materials Science"
        case .biology: return "Biology"
        case .chemistry: return "Chemistry"
        case .physics: return "Physics"
        case .engineering: return "Engineering"
        case .other: return "Other"
        }
    }
}

/// Project visibility options
enum ProjectVisibility: String, CaseIterable, Sendable {
    case `private` = "private"
    case lab = "lab"
    case `public` = "public"

    var displayName: String {
        switch self {
        case .private: return "Private"
        case .lab: return "Lab Only"
        case .public: return "Public"
        }
    }

    var description: String {
        switch self {
        case .private: return "Only you can access"
        case .lab: return "Visible to lab members"
        case .public: return "Anyone can view"
        }
    }
}

/// Form mode for create vs edit
enum ProjectFormMode: Sendable {
    case create
    case edit(Project)

    var isEditing: Bool {
        if case .edit = self { return true }
        return false
    }

    var existingProject: Project? {
        if case .edit(let project) = self { return project }
        return nil
    }
}

@Observable
@MainActor
final class ProjectFormViewModel {
    // MARK: - Form Fields

    var title = ""
    var descriptionText = ""
    var projectType: ProjectType = .materialsScience
    var visibility: ProjectVisibility = .private

    // MARK: - Validation Errors

    private(set) var titleError: String?
    private(set) var descriptionError: String?

    // MARK: - State

    private(set) var isLoading = false
    private(set) var isSaved = false
    private(set) var saveError: Error?

    // MARK: - Mode

    let mode: ProjectFormMode

    // MARK: - Private Properties

    private let repository: ProjectRepository
    private var initialTitle = ""
    private var initialDescription = ""
    private var initialProjectType: ProjectType = .materialsScience
    private var initialVisibility: ProjectVisibility = .private

    // MARK: - Initialization

    init(mode: ProjectFormMode, repository: ProjectRepository) {
        self.mode = mode
        self.repository = repository

        if let project = mode.existingProject {
            populateFromProject(project)
        }
    }

    // MARK: - Computed Properties

    /// Check if the form has valid data
    var isFormValid: Bool {
        validateTitleSilent() && validateDescriptionSilent()
    }

    /// Check if any field has been modified
    var isDirty: Bool {
        title != initialTitle ||
        descriptionText != initialDescription ||
        projectType != initialProjectType ||
        visibility != initialVisibility
    }

    /// Character count for title
    var titleCharacterCount: Int {
        title.count
    }

    /// Character count for description
    var descriptionCharacterCount: Int {
        descriptionText.count
    }

    // MARK: - Validation

    /// Validate title and set error message
    func validateTitle() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            titleError = "Title is required"
        } else if trimmed.count < 3 {
            titleError = "Title must be at least 3 characters"
        } else if trimmed.count > 100 {
            titleError = "Title must be 100 characters or less"
        } else {
            titleError = nil
        }
    }

    /// Validate description and set error message
    func validateDescription() {
        let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 500 {
            descriptionError = "Description must be 500 characters or less"
        } else {
            descriptionError = nil
        }
    }

    /// Clear all validation errors
    func clearErrors() {
        titleError = nil
        descriptionError = nil
        saveError = nil
    }

    // MARK: - Actions

    /// Save the project (create or update)
    func save() async {
        validateTitle()
        validateDescription()

        guard isFormValid else { return }

        isLoading = true
        saveError = nil

        do {
            if let existingProject = mode.existingProject {
                try await updateProject(existingProject)
            } else {
                try await createProject()
            }
            isSaved = true
        } catch {
            saveError = error
        }

        isLoading = false
    }

    /// Reset form to initial state
    func reset() {
        if let project = mode.existingProject {
            populateFromProject(project)
        } else {
            title = ""
            descriptionText = ""
            projectType = .materialsScience
            visibility = .private
        }
        clearErrors()
        isSaved = false
    }

    // MARK: - Private Methods

    private func validateTitleSilent() -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count >= 3 && trimmed.count <= 100
    }

    private func validateDescriptionSilent() -> Bool {
        let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count <= 500
    }

    private func populateFromProject(_ project: Project) {
        title = project.title
        descriptionText = project.description
        projectType = ProjectType(rawValue: project.metadata["projectType"] ?? "") ?? .materialsScience
        visibility = .private // Default for now

        initialTitle = title
        initialDescription = descriptionText
        initialProjectType = projectType
        initialVisibility = visibility
    }

    private func createProject() async throws {
        let newProject = Project(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
            status: .planning,
            principalInvestigatorID: UUID(), // Placeholder - should come from auth
            labAffiliation: LabAffiliation(name: "Vision & AI Lab", institution: "UTSA"),
            metadata: ["projectType": projectType.rawValue, "visibility": visibility.rawValue],
            tags: []
        )
        try await repository.save(newProject)
    }

    private func updateProject(_ existing: Project) async throws {
        var updated = existing
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.description = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.metadata["projectType"] = projectType.rawValue
        updated.metadata["visibility"] = visibility.rawValue
        updated.updatedAt = Date()
        try await repository.update(updated)
    }
}

// MARK: - Convenience Properties

extension ProjectFormViewModel {
    var saveErrorMessage: String? {
        saveError?.localizedDescription
    }

    var navigationTitle: String {
        mode.isEditing ? "Edit Project" : "Create Project"
    }

    var saveButtonTitle: String {
        mode.isEditing ? "Save Changes" : "Create Project"
    }
}
