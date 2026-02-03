import Foundation
import Observation

@Observable
@MainActor
final class LabDetailViewModel {
    // MARK: - Published Properties

    private(set) var lab: Lab?
    private(set) var activeProjects: [Project] = []
    private(set) var pastProjects: [Project] = []
    private(set) var members: [LabMember] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    // MARK: - Private Properties

    private let labRepository: LabRepository
    private let projectRepository: ProjectRepository
    private let labId: String

    // MARK: - Initialization

    init(labRepository: LabRepository, projectRepository: ProjectRepository, labId: String) {
        self.labRepository = labRepository
        self.projectRepository = projectRepository
        self.labId = labId
    }

    // MARK: - Public Methods

    func loadLab() async {
        isLoading = true
        error = nil
        do {
            lab = try await labRepository.findById(labId)
            let allProjects = try await labRepository.findLabProjects(labId: labId)
            activeProjects = allProjects.filter { $0.status != .completed && $0.status != .archived }
            pastProjects   = allProjects.filter { $0.status == .completed || $0.status == .archived }
            members = try await labRepository.findLabMembers(labId: labId)
                .sorted { a, b in
                    if a.isPI != b.isPI { return a.isPI }
                    return a.fullName < b.fullName
                }
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func refresh() async {
        await loadLab()
    }

    func deleteProject(_ id: UUID) async {
        do {
            try await projectRepository.delete(id)
            await refresh()
        } catch {
            self.error = error
        }
    }
}
