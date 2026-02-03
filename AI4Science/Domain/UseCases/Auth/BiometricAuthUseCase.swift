import Foundation
import LocalAuthentication

/// Use case for biometric authentication (Face ID/Touch ID)
@available(iOS 15.0, *)
public actor BiometricAuthUseCase: Sendable {
    private let authService: any AuthServiceProtocol
    private let context = LAContext()

    public init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    /// Check if biometric authentication is available
    /// - Returns: True if Face ID or Touch ID is available
    public func isBiometricAvailable() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
    }

    /// Get biometric type available on device
    /// - Returns: The type of biometric available
    public func getBiometricType() -> BiometricType {
        var error: NSError?
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            return .none
        }

        if #available(iOS 16.0, *) {
            switch context.biometryType {
            case .faceID:
                return .faceID
            case .touchID:
                return .touchID
            case .opticID:
                return .opticID
            @unknown default:
                return .unknown
            }
        } else {
            if context.biometryType == .touchID {
                return .touchID
            } else if context.biometryType == .faceID {
                return .faceID
            }
            return .unknown
        }
    }

    /// Authenticate user with biometric
    /// - Returns: Authentication session with tokens
    /// - Throws: ServiceAuthError if authentication fails
    public func execute() async throws -> AuthSession {
        guard isBiometricAvailable() else {
            throw ServiceAuthError.biometricNotAvailable
        }

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            throw ServiceAuthError.biometricFailed
        }

        do {
            let authenticated = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access your research data"
            )

            guard authenticated else {
                throw ServiceAuthError.biometricFailed
            }

            let session = try await authService.authenticateWithBiometric()
            return session
        } catch let error as ServiceAuthError {
            throw error
        } catch {
            throw ServiceAuthError.biometricFailed
        }
    }

    /// Enable biometric authentication
    /// - Throws: ServiceAuthError if enabling fails
    public func enableBiometric() async throws {
        guard isBiometricAvailable() else {
            throw ServiceAuthError.biometricNotAvailable
        }

        // The actual enablement logic would be handled by the auth service
        // This use case just validates availability
    }
}

/// Biometric type enumeration
public enum BiometricType: Sendable {
    case none
    case faceID
    case touchID
    case opticID
    case unknown
}
