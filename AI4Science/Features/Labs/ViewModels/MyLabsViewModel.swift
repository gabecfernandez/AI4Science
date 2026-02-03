import Foundation
import Observation

@Observable
@MainActor
final class MyLabsViewModel {
    // MARK: - Published Properties

    private(set) var myLabs: [Lab] = []
    private(set) var exploreLabs: [Lab] = []   // public labs user hasn't joined
    private(set) var isLoading = false
    private(set) var error: Error?

    // MARK: - Private Properties

    private let labRepository: LabRepository
    private let userId: String?

    // MARK: - Initialization

    init(labRepository: LabRepository, userId: String?) {
        self.labRepository = labRepository
        self.userId = userId
    }

    // MARK: - Public Methods

    func loadLabs() async {
        isLoading = true
        error = nil
        do {
            if let userId = userId {
                myLabs = try await labRepository.findByUser(userId: userId)
            }
            let joinedIds = Set(myLabs.map { $0.id })
            let allLabs = try await labRepository.findAll()
            exploreLabs = allLabs.filter { $0.isPublic && !joinedIds.contains($0.id) }
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func refresh() async {
        await loadLabs()
    }

    func joinLab(_ labId: String) async {
        guard let userId = userId else { return }
        do {
            try await labRepository.addMember(userId, to: labId)
            await loadLabs()   // refresh both lists
        } catch {
            self.error = error
        }
    }
}
