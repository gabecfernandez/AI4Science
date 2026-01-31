import Foundation
import Security

/// Error type for Keychain operations
public enum KeychainError: LocalizedError, Sendable {
    case saveFailed
    case retrieveFailed
    case deleteFailed
    case duplicateItem
    case itemNotFound
    case invalidData

    public var errorDescription: String? {
        switch self {
        case .saveFailed: return "Failed to save item to keychain"
        case .retrieveFailed: return "Failed to retrieve item from keychain"
        case .deleteFailed: return "Failed to delete item from keychain"
        case .duplicateItem: return "Item already exists in keychain"
        case .itemNotFound: return "Item not found in keychain"
        case .invalidData: return "Invalid data for keychain operation"
        }
    }
}

/// Secure credential storage using Keychain
public actor KeychainManager: Sendable {
    public static let shared = KeychainManager()

    private let service = "com.ai4science.ios"

    // MARK: - String Operations

    public func save(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        try save(data, for: key)
    }

    public func retrieve(for key: String) throws -> String {
        let data: Data = try retrieve(for: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }

    // MARK: - Data Operations

    public func save(_ data: Data, for key: String) throws {
        let query = baseQuery(for: key)

        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(addQuery as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }

    public func retrieve(for key: String) throws -> Data {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.retrieveFailed
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }

        return data
    }

    // MARK: - Deletion

    public func delete(for key: String) throws {
        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed
        }
    }

    public func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed
        }
    }

    // MARK: - Existence Check

    public func exists(for key: String) throws -> Bool {
        let query = baseQuery(for: key)
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Private

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }

    private init() {}
}
