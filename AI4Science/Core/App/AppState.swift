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
    var featureFlags: FeatureFlags = FeatureFlags()

    // MARK: - Error Handling
    var currentError: AppError?
    var showingError: Bool = false

    // MARK: - Initialization

    init() {
        setupNetworkMonitoring()
    }

    // MARK: - Authentication Methods

    func checkAuthenticationState() async {
        // Check for stored credentials/tokens
        if let storedUser = await loadStoredUser() {
            currentUser = storedUser
            authState = .authenticated
        } else {
            authState = .unauthenticated
        }
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
        AppLogger.shared.error("App error: \(error.localizedDescription)")
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

// MARK: - Feature Flags

struct FeatureFlags: Sendable {
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
