import Foundation
import Observation

@Observable
@MainActor
final class ProjectCreateViewModel {
    var name: String = ""
    var description: String = ""
    var isLoading = false
    var showError = false
    var errorMessage = ""
    var isEditMode = false
    var isDirty = false

    private let repository: any ProjectRepositoryProtocol
    private let ownerId: UUID
    private var editingProjectId: UUID?

    // MARK: - Create Mode

    init(repository: any ProjectRepositoryProtocol, ownerId: UUID) {
        self.repository = repository
        self.ownerId = ownerId
    }

    // MARK: - Edit Mode

    init(repository: any ProjectRepositoryProtocol, project: Project) {
        self.repository = repository
        self.ownerId = project.ownerId
        self.name = project.name
        self.description = project.description
        self.isEditMode = true
        self.editingProjectId = project.id
    }

    // MARK: - Validation

    var nameValidationError: String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return "Project name is required" }
        if trimmed.count < 3 { return "Project name must be at least 3 characters" }
        if trimmed.count > 100 { return "Project name must be 100 characters or fewer" }
        return nil
    }

    var descriptionValidationError: String? {
        if description.count > 500 { return "Description must be 500 characters or fewer" }
        return nil
    }

    var canSubmit: Bool {
        nameValidationError == nil && descriptionValidationError == nil && !isLoading
    }

    // MARK: - Actions

    func submit() async -> Project? {
        guard canSubmit else {
            showError = true
            errorMessage = nameValidationError ?? descriptionValidationError ?? "Invalid input"
            return nil
        }

        isLoading = true
        defer { isLoading = false }

        do {
            if isEditMode, let editId = editingProjectId {
                guard var existing = try await repository.findById(editId) else {
                    showError = true
                    errorMessage = "Project not found"
                    return nil
                }
                existing.name = name.trimmingCharacters(in: .whitespaces)
                existing.description = description
                existing.updatedAt = Date()
                try await repository.save(existing)
                return existing
            } else {
                let now = Date()
                let project = Project(
                    id: UUID(),
                    name: name.trimmingCharacters(in: .whitespaces),
                    description: description,
                    ownerId: ownerId,
                    status: .draft,
                    createdAt: now,
                    updatedAt: now
                )
                try await repository.save(project)
                return project
            }
        } catch {
            showError = true
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func markDirty() {
        isDirty = true
    }
}
