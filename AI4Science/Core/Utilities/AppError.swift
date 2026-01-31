import Foundation

/// Comprehensive error types for the application
@frozen
public enum AppError: LocalizedError, Sendable, Hashable {
    case invalidInput(String)
    case notFound(String)
    case duplicateEntry(String)
    case validationFailed(String)
    case networkError(NetworkErrorType)
    case storageError(StorageErrorType)
    case authenticationError(AuthenticationErrorType)
    case mlModelError(MLModelErrorType)
    case cameraError(CameraErrorType)
    case syncError(SyncErrorType)
    case fileError(FileErrorType)
    case decodingError(String)
    case encodingError(String)
    case permissionDenied(String)
    case timeout
    case cancelled
    case unknown(String)

    // MARK: - Subtypes

    @frozen
    public enum NetworkErrorType: String, Sendable, Hashable {
        case noConnection
        case invalidResponse
        case serverError
        case badRequest
        case unauthorized
        case forbidden
        case notFound
        case rateLimit
        case unknown
    }

    @frozen
    public enum StorageErrorType: String, Sendable, Hashable {
        case directoryCreationFailed
        case writeFailed
        case readFailed
        case deleteFailed
        case quotaExceeded
        case corruptedData
        case unknown
    }

    @frozen
    public enum AuthenticationErrorType: String, Sendable, Hashable {
        case invalidCredentials
        case expiredToken
        case refreshFailed
        case biometricFailed
        case userNotAuthenticated
        case unknown
    }

    @frozen
    public enum MLModelErrorType: String, Sendable, Hashable {
        case modelNotFound
        case downloadFailed
        case loadFailed
        case inferenceError
        case incompatibleModel
        case insufficientMemory
        case unknown
    }

    @frozen
    public enum CameraErrorType: String, Sendable, Hashable {
        case notAvailable
        case permissionDenied
        case sessionError
        case captureError
        case processingError
        case unknown
    }

    @frozen
    public enum SyncErrorType: String, Sendable, Hashable {
        case conflictDetected
        case invalidData
        case networkUnavailable
        case authenticationRequired
        case quotaExceeded
        case unknown
    }

    @frozen
    public enum FileErrorType: String, Sendable, Hashable {
        case fileNotFound
        case directoryNotFound
        case permissionDenied
        case quotaExceeded
        case corruptedFile
        case invalidPath
        case unknown
    }

    // MARK: - Error Descriptions

    public var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            "Invalid Input: \(message)"
        case .notFound(let message):
            "Not Found: \(message)"
        case .duplicateEntry(let message):
            "Duplicate Entry: \(message)"
        case .validationFailed(let message):
            "Validation Failed: \(message)"
        case .networkError(let type):
            "Network Error: \(type.rawValue)"
        case .storageError(let type):
            "Storage Error: \(type.rawValue)"
        case .authenticationError(let type):
            "Authentication Error: \(type.rawValue)"
        case .mlModelError(let type):
            "ML Model Error: \(type.rawValue)"
        case .cameraError(let type):
            "Camera Error: \(type.rawValue)"
        case .syncError(let type):
            "Sync Error: \(type.rawValue)"
        case .fileError(let type):
            "File Error: \(type.rawValue)"
        case .decodingError(let message):
            "Decoding Error: \(message)"
        case .encodingError(let message):
            "Encoding Error: \(message)"
        case .permissionDenied(let message):
            "Permission Denied: \(message)"
        case .timeout:
            "Operation Timed Out"
        case .cancelled:
            "Operation Cancelled"
        case .unknown(let message):
            "Unknown Error: \(message)"
        }
    }

    public var failureReason: String? {
        errorDescription
    }

    public var recoverySuggestion: String? {
        switch self {
        case .networkError:
            "Check your internet connection and try again."
        case .storageError:
            "Check available storage space and try again."
        case .authenticationError:
            "Please log in again."
        case .permissionDenied:
            "Please grant the required permissions in Settings."
        case .timeout:
            "The operation took too long. Please try again."
        case .mlModelError:
            "Please try downloading the model again."
        default:
            nil
        }
    }

    // MARK: - Helpers

    public var isNetworkError: Bool {
        if case .networkError = self {
            return true
        }
        return false
    }

    public var isAuthenticationError: Bool {
        if case .authenticationError = self {
            return true
        }
        return false
    }

    public var isStorageError: Bool {
        if case .storageError = self {
            return true
        }
        return false
    }

    public var isUserCancelled: Bool {
        if case .cancelled = self {
            return true
        }
        return false
    }

    public var isTimeout: Bool {
        if case .timeout = self {
            return true
        }
        return false
    }

    // MARK: - Equatable

    public static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidInput(let l), .invalidInput(let r)):
            return l == r
        case (.notFound(let l), .notFound(let r)):
            return l == r
        case (.duplicateEntry(let l), .duplicateEntry(let r)):
            return l == r
        case (.validationFailed(let l), .validationFailed(let r)):
            return l == r
        case (.networkError(let l), .networkError(let r)):
            return l == r
        case (.storageError(let l), .storageError(let r)):
            return l == r
        case (.authenticationError(let l), .authenticationError(let r)):
            return l == r
        case (.mlModelError(let l), .mlModelError(let r)):
            return l == r
        case (.cameraError(let l), .cameraError(let r)):
            return l == r
        case (.syncError(let l), .syncError(let r)):
            return l == r
        case (.fileError(let l), .fileError(let r)):
            return l == r
        case (.decodingError(let l), .decodingError(let r)):
            return l == r
        case (.encodingError(let l), .encodingError(let r)):
            return l == r
        case (.permissionDenied(let l), .permissionDenied(let r)):
            return l == r
        case (.timeout, .timeout):
            return true
        case (.cancelled, .cancelled):
            return true
        case (.unknown(let l), .unknown(let r)):
            return l == r
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .invalidInput(let msg):
            hasher.combine("invalidInput")
            hasher.combine(msg)
        case .notFound(let msg):
            hasher.combine("notFound")
            hasher.combine(msg)
        case .timeout:
            hasher.combine("timeout")
        case .cancelled:
            hasher.combine("cancelled")
        default:
            hasher.combine(errorDescription)
        }
    }
}

// MARK: - Error Conversion

extension AppError {
    /// Create AppError from URLError
    static func from(_ error: URLError) -> AppError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkError(.noConnection)
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        case .badServerResponse, .cannotParseResponse:
            return .networkError(.invalidResponse)
        default:
            return .networkError(.unknown)
        }
    }

    /// Create AppError from DecodingError
    static func from(_ error: DecodingError) -> AppError {
        switch error {
        case let .dataCorrupted(context):
            return .decodingError(context.debugDescription)
        case let .keyNotFound(_, context):
            return .decodingError(context.debugDescription)
        case let .typeMismatch(_, context):
            return .decodingError(context.debugDescription)
        case let .valueNotFound(_, context):
            return .decodingError(context.debugDescription)
        @unknown default:
            return .decodingError("Unknown decoding error")
        }
    }

    /// Create AppError from EncodingError
    static func from(_ error: EncodingError) -> AppError {
        switch error {
        case let .invalidValue(_, context):
            return .encodingError(context.debugDescription)
        @unknown default:
            return .encodingError("Unknown encoding error")
        }
    }
}
