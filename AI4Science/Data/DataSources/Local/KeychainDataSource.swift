import Foundation
import Security

/// Data source for secure Keychain operations
actor KeychainDataSource: Sendable {
    // MARK: - Constants

    private static let serviceName = "com.ai4science.app"

    // MARK: - Error Types

    enum KeychainError: LocalizedError {
        case noPassword
        case unexpectedPasswordData
        case unhandledError(status: OSStatus)
        case invalidData

        var errorDescription: String? {
            switch self {
            case .noPassword:
                return "Password not found in Keychain"
            case .unexpectedPasswordData:
                return "Invalid password data in Keychain"
            case .unhandledError(let status):
                return "Keychain error: \(status)"
            case .invalidData:
                return "Invalid data format"
            }
        }
    }

    // MARK: - Public Methods

    /// Store sensitive string in Keychain
    /// - Parameters:
    ///   - value: Value to store
    ///   - key: Storage key
    func store(_ value: String, forKey key: String) async throws {
        let data = value.data(using: .utf8)!

        // Try to delete existing value first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(deleteQuery as CFDictionary)

        // Add new value
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }

        AppLogger.info("Stored value in Keychain for key: \(key)")
    }

    /// Retrieve sensitive string from Keychain
    /// - Parameter key: Storage key
    /// - Returns: Retrieved value
    func retrieve(forKey key: String) async throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.noPassword
            }
            throw KeychainError.unhandledError(status: status)
        }

        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedPasswordData
        }

        return string
    }

    /// Delete value from Keychain
    /// - Parameter key: Storage key
    func delete(forKey key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }

        AppLogger.info("Deleted value from Keychain for key: \(key)")
    }

    /// Check if value exists
    /// - Parameter key: Storage key
    /// - Returns: True if value exists
    func exists(forKey key: String) async -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Store data in Keychain
    /// - Parameters:
    ///   - data: Data to store
    ///   - key: Storage key
    func storeData(_ data: Data, forKey key: String) async throws {
        // Try to delete existing value first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(deleteQuery as CFDictionary)

        // Add new value
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    /// Retrieve data from Keychain
    /// - Parameter key: Storage key
    /// - Returns: Retrieved data
    func retrieveData(forKey key: String) async throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.noPassword
            }
            throw KeychainError.unhandledError(status: status)
        }

        guard let data = result as? Data else {
            throw KeychainError.unexpectedPasswordData
        }

        return data
    }

    /// Store codable object in Keychain
    /// - Parameters:
    ///   - object: Object to encode and store
    ///   - key: Storage key
    func storeCodable<T: Encodable>(_ object: T, forKey key: String) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        try await storeData(data, forKey: key)
    }

    /// Retrieve codable object from Keychain
    /// - Parameters:
    ///   - type: Expected type
    ///   - key: Storage key
    /// - Returns: Decoded object
    func retrieveCodable<T: Decodable>(as type: T.Type, forKey key: String) async throws -> T {
        let data = try await retrieveData(forKey: key)
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }

    /// Delete all Keychain items for this service
    func deleteAll() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }

        AppLogger.warning("Deleted all Keychain items for service: \(Self.serviceName)")
    }
}

// MARK: - Convenience Extensions

extension KeychainDataSource {
    /// Keys for sensitive data
    struct SecureKey {
        static let authToken = "authToken"
        static let refreshToken = "refreshToken"
        static let userCredentials = "userCredentials"
        static let apiKeys = "apiKeys"
        static let encryptionKey = "encryptionKey"
    }

    /// Store authentication token
    /// - Parameter token: Auth token
    func storeAuthToken(_ token: String) async throws {
        try await store(token, forKey: SecureKey.authToken)
    }

    /// Retrieve authentication token
    /// - Returns: Auth token or nil
    func retrieveAuthToken() async -> String? {
        try? await retrieve(forKey: SecureKey.authToken)
    }

    /// Store refresh token
    /// - Parameter token: Refresh token
    func storeRefreshToken(_ token: String) async throws {
        try await store(token, forKey: SecureKey.refreshToken)
    }

    /// Retrieve refresh token
    /// - Returns: Refresh token or nil
    func retrieveRefreshToken() async -> String? {
        try? await retrieve(forKey: SecureKey.refreshToken)
    }

    /// Clear authentication tokens
    func clearAuthTokens() async throws {
        try await delete(forKey: SecureKey.authToken)
        try await delete(forKey: SecureKey.refreshToken)
    }
}
