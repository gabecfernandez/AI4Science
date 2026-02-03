import Foundation
import Security
import Auth

/// Keychain-backed AuthLocalStorage for the Supabase SDK.
///
/// Uses the same Keychain service name as KeychainManager ("com.ai4science.ios")
/// so sign-out cleanup via KeychainManager.shared remains consistent.
/// The SDK owns the key strings; we just persist the raw Data blobs.
nonisolated struct SupabaseSessionStorage: AuthLocalStorage {
    private static let serviceName = "com.ai4science.ios"

    func store(key: String, value: Data) throws {
        let deleteQuery: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String:          kSecClassGenericPassword,
            kSecAttrService as String:    Self.serviceName,
            kSecAttrAccount as String:    key,
            kSecValueData as String:      value,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        guard SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }

    func retrieve(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    func remove(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed
        }
    }
}
