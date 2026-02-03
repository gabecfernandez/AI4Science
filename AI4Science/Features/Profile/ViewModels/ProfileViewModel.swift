//
//  ProfileViewModel.swift
//  AI4Science
//
//  ViewModel for the user profile screen
//

import Foundation
import Observation

/// Display model for user profile
struct ProfileUser: Sendable {
    let id: String
    let fullName: String
    let email: String
    let institution: String?
    let profileImageURL: String?
    let memberSince: Date
    let projectCount: Int
    let sampleCount: Int
    let captureCount: Int
}

@Observable
@MainActor
final class ProfileViewModel {
    // MARK: - Published Properties

    private(set) var user: ProfileUser?
    private(set) var isLoading = false
    private(set) var error: Error?

    // MARK: - Private Properties

    private let userRepository: UserRepository
    private let projectRepository: ProjectRepository
    private let captureRepository: CaptureRepository

    // MARK: - Initialization

    init(
        userRepository: UserRepository,
        projectRepository: ProjectRepository,
        captureRepository: CaptureRepository
    ) {
        self.userRepository = userRepository
        self.projectRepository = projectRepository
        self.captureRepository = captureRepository
    }

    // MARK: - Public Methods

    func loadProfile() async {
        isLoading = true
        error = nil

        do {
            // Get the first user (demo user) as Sendable display data
            guard let userData = try await userRepository.getFirstUserDisplayData() else {
                error = ProfileError.userNotFound
                isLoading = false
                return
            }

            // Get project count
            let projects = try await projectRepository.findAll()

            // Get sample count from projects
            let sampleCount = projects.reduce(0) { $0 + $1.sampleCount }

            // Get capture count using Sendable method
            let captureCount = try await captureRepository.getCaptureCount()

            user = ProfileUser(
                id: userData.id,
                fullName: userData.fullName,
                email: userData.email,
                institution: userData.institution,
                profileImageURL: userData.profileImageURL,
                memberSince: userData.createdAt,
                projectCount: projects.count,
                sampleCount: sampleCount,
                captureCount: captureCount
            )
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func refresh() async {
        await loadProfile()
    }
}

// MARK: - Profile Errors

enum ProfileError: LocalizedError {
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "No user profile found"
        }
    }
}
