import Foundation

/// Errors thrown by AuthenticationService.
/// Each case includes a user-friendly description and maps to AppError for
/// propagation through the existing error-handling pipeline.
@frozen
enum AuthError: LocalizedError, Sendable {
    case invalidCredentials
    case expiredToken
    case refreshFailed
    case supabaseError(String)
    case oauthFailed(String)
    case appleSignInFailed(String)
    case invalidUserId(String)
    case signOutFailed(String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:         return "Invalid email or password."
        case .expiredToken:               return "Your session has expired. Please sign in again."
        case .refreshFailed:              return "Could not refresh your session. Please sign in again."
        case .supabaseError(let msg):     return msg
        case .oauthFailed(let msg):       return "Sign-in failed: \(msg)"
        case .appleSignInFailed(let msg): return "Apple Sign In failed: \(msg)"
        case .invalidUserId(let raw):     return "Invalid user ID received: \(raw)"
        case .signOutFailed(let msg):     return "Sign out failed: \(msg)"
        }
    }

    // MARK: - AppError bridge

    /// Convert to the app-wide error type for ViewModel / AppState consumption.
    var appError: AppError {
        switch self {
        case .invalidCredentials:       return .authenticationError(.invalidCredentials)
        case .expiredToken:             return .authenticationError(.expiredToken)
        case .refreshFailed:            return .authenticationError(.refreshFailed)
        case .supabaseError(let m):     return .unknown(m)
        case .oauthFailed(let m):       return .unknown(m)
        case .appleSignInFailed(let m): return .unknown(m)
        case .invalidUserId(let m):     return .unknown("Invalid user ID: \(m)")
        case .signOutFailed(let m):     return .unknown(m)
        }
    }
}
