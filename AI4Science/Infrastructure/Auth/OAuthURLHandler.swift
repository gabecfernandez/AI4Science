//
//  OAuthURLHandler.swift
//  AI4Science
//
//  OAuth URL handling and ASWebAuthenticationSession management
//

import Foundation
import AuthenticationServices
import UIKit

/// OAuth callback result
enum OAuthCallbackResult {
    case success(URL)
    case error(String)
}

/// Manager for OAuth authentication flows using ASWebAuthenticationSession
@MainActor
final class OAuthURLHandler: NSObject {
    static let shared = OAuthURLHandler()

    private var authSession: ASWebAuthenticationSession?
    private var continuation: CheckedContinuation<URL, Error>?

    private override init() {
        super.init()
    }

    // MARK: - OAuth Flow Management

    /// Open OAuth URL in ASWebAuthenticationSession
    /// - Parameter url: The OAuth authorization URL
    /// - Returns: The callback URL after successful authentication
    /// - Throws: OAuth errors including user cancellation
    func openOAuthURL(_ url: URL) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            // Create authentication session
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "ai4science"
            ) { [weak self] callbackURL, error in
                self?.handleSessionCompletion(callbackURL: callbackURL, error: error)
            }

            // Allow SSO (don't use ephemeral session)
            session.prefersEphemeralWebBrowserSession = false

            // Set presentation context provider
            session.presentationContextProvider = self

            // Start the session
            authSession = session
            if !session.start() {
                continuation.resume(throwing: ServiceAuthError.unknownError("Failed to start OAuth session"))
                self.continuation = nil
            }
        }
    }

    /// Parse and validate OAuth callback URL
    /// - Parameter url: The callback URL from the OAuth provider
    /// - Returns: Result indicating success with URL or error with message
    func parseCallback(_ url: URL) -> OAuthCallbackResult? {
        // Validate URL scheme
        guard url.scheme == "ai4science" else {
            AppLogger.warning("Invalid OAuth callback scheme: \(url.scheme ?? "nil")")
            return nil
        }

        // Validate host (should be "auth")
        guard url.host == "auth" else {
            AppLogger.warning("Invalid OAuth callback host: \(url.host ?? "nil")")
            return .error("Invalid OAuth callback URL")
        }

        // Validate path (should be "/callback")
        guard url.path == "/callback" else {
            AppLogger.warning("Invalid OAuth callback path: \(url.path)")
            return .error("Invalid OAuth callback path")
        }

        // Check for error parameter
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            if let errorParam = queryItems.first(where: { $0.name == "error" })?.value {
                return .error(errorParam)
            }
        }

        return .success(url)
    }

    // MARK: - Private Helpers

    private func handleSessionCompletion(callbackURL: URL?, error: Error?) {
        defer {
            authSession = nil
        }

        if let error = error {
            // Check for user cancellation
            if let authError = error as? ASWebAuthenticationSessionError,
               authError.code == .canceledLogin {
                continuation?.resume(throwing: ServiceAuthError.unknownError("OAuth sign-in was cancelled"))
            } else {
                continuation?.resume(throwing: ServiceAuthError.networkError(error.localizedDescription))
            }
            continuation = nil
            return
        }

        guard let callbackURL = callbackURL else {
            continuation?.resume(throwing: ServiceAuthError.unknownError("No callback URL received"))
            continuation = nil
            return
        }

        // Parse and validate callback
        switch parseCallback(callbackURL) {
        case .success(let url):
            continuation?.resume(returning: url)
        case .error(let message):
            continuation?.resume(throwing: ServiceAuthError.unknownError(message))
        case .none:
            continuation?.resume(throwing: ServiceAuthError.unknownError("Invalid callback URL format"))
        }

        continuation = nil
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension OAuthURLHandler: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the key window for presentation
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available for OAuth presentation")
        }
        return window
    }
}
