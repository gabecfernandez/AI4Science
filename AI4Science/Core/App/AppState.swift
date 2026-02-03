//
//  AppState.swift
//  AI4Science
//
//  Global application state management
//

import Foundation
import Observation

/// Global application state using Swift Observation
@Observable
@MainActor
final class AppState {
    // MARK: - Authentication
    var authState: AuthenticationState = .unknown
    var currentUser: User?

    // MARK: - Network
    var isOnline: Bool = true
    var syncStatus: SyncStatusState = .idle

    // MARK: - Feature Flags
    var featureFlags: AppFeatureFlags = AppFeatureFlags()

    // MARK: - Error Handling
    var currentError: AppError?
    var showingError: Bool = false

    // MARK: - Initialization

    init() {
        setupNetworkMonitoring()
    }

    // MARK: - Authentication Methods

    func checkAuthenticationState(serviceContainer: ServiceContainer) async {
        authState = .unknown

        do {
            // Check for existing Supabase session
            if let session = try await serviceContainer.authService.getCurrentSession(),
               try await serviceContainer.authService.validateSession() {

                // Load user from local database and extract display data
                let userDisplayData = try await serviceContainer.userRepository.getFirstUserDisplayData()

                if let displayData = userDisplayData, displayData.id == session.userId {
                    // Map display data to User domain model
                    currentUser = mapDisplayDataToUser(displayData)
                    authState = .authenticated
                    return
                }
            }
        } catch {
            AppLogger.error("Session restoration failed: \(error)")
        }

        authState = .unauthenticated
    }

    func signIn(user: User) {
        currentUser = user
        authState = .authenticated
    }

    func signOut() {
        currentUser = nil
        authState = .unauthenticated
        Task {
            await clearStoredCredentials()
        }
    }

    // MARK: - Error Handling

    func handleError(_ error: AppError) {
        currentError = error
        showingError = true
        AppLogger.error("App error: \(error.localizedDescription)")
    }

    func clearError() {
        currentError = nil
        showingError = false
    }

    // MARK: - Private Methods

    private func setupNetworkMonitoring() {
        // Network monitoring using NWPathMonitor
    }

    private func loadStoredUser() async -> User? {
        // Load from Keychain/secure storage
        nil
    }

    private func clearStoredCredentials() async {
        // Clear Keychain/secure storage
    }

    /// Map UserDisplayData to User domain model
    private func mapDisplayDataToUser(_ displayData: UserDisplayData) -> User {
        let nameComponents = displayData.fullName.components(separatedBy: " ")
        let firstName = nameComponents.first ?? ""
        let lastName = nameComponents.dropFirst().joined(separator: " ")

        return User(
            id: UUID(uuidString: displayData.id) ?? UUID(),
            firstName: firstName,
            lastName: lastName,
            email: displayData.email,
            role: .researcher, // Default role per requirement
            labAffiliation: nil // TODO: Map institution string to LabAffiliation object when profile management is implemented
        )
    }
}

// MARK: - Authentication State

enum AuthenticationState: Equatable, Sendable {
    case unknown
    case unauthenticated
    case authenticated
    case onboarding
}

// MARK: - Sync Status State

enum SyncStatusState: Equatable, Sendable {
    case idle
    case syncing(progress: Double)
    case completed
    case failed(String)

    var isInProgress: Bool {
        if case .syncing = self {
            return true
        }
        return false
    }
}

// MARK: - App Feature Flags

struct AppFeatureFlags: Sendable {
    var enableAROverlay: Bool = true
    var enableOfflineML: Bool = true
    var enableResearchKit: Bool = true
    var enableAppleIntelligence: Bool = true
    var enableRawCapture: Bool = true
    var enable4KVideo: Bool = true
    var enableCloudSync: Bool = false
    var maxCapturesPerSample: Int = 100
    var maxAnnotationsPerCapture: Int = 500
}
