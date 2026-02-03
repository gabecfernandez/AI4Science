import Foundation
import Observation

@Observable
@MainActor
final class MemberProfileViewModel {
    // MARK: - Published Properties

    private(set) var labs: [Lab] = []
    private(set) var projects: [Project] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    // MARK: - Context

    /// The member whose profile is being viewed.
    let member: LabMember
    /// Name of the lab from which this member was tapped (for PI badge context).
    let currentLabName: String

    // MARK: - Private Properties

    private let labRepository: LabRepository

    // MARK: - Initialization

    init(member: LabMember, currentLabName: String, labRepository: LabRepository) {
        self.member = member
        self.currentLabName = currentLabName
        self.labRepository = labRepository
    }

    // MARK: - Public Methods

    func loadProfile() async {
        isLoading = true
        error = nil
        do {
            labs     = try await labRepository.findByUser(userId: member.id)
            projects = try await labRepository.findProjectsByUser(userId: member.id)
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
