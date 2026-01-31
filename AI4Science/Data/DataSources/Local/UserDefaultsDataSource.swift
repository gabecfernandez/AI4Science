import Foundation

/// Data source for UserDefaults operations
actor UserDefaultsDataSource: Sendable {
    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let suiteName: String

    // MARK: - Initialization

    init(suiteName: String = "com.ai4science.app") {
        self.suiteName = suiteName
        self.userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.suiteName = userDefaults.suiteName ?? "com.ai4science.app"
    }

    // MARK: - Public Methods

    // MARK: - String Operations

    /// Store string value
    /// - Parameters:
    ///   - value: Value to store
    ///   - key: Storage key
    func set(_ value: String?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// Retrieve string value
    /// - Parameter key: Storage key
    /// - Returns: String value or nil
    func string(forKey key: String) -> String? {
        userDefaults.string(forKey: key)
    }

    // MARK: - Integer Operations

    /// Store integer value
    /// - Parameters:
    ///   - value: Value to store
    ///   - key: Storage key
    func set(_ value: Int, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// Retrieve integer value
    /// - Parameter key: Storage key
    /// - Returns: Integer value
    func integer(forKey key: String) -> Int {
        userDefaults.integer(forKey: key)
    }

    // MARK: - Boolean Operations

    /// Store boolean value
    /// - Parameters:
    ///   - value: Value to store
    ///   - key: Storage key
    func set(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// Retrieve boolean value
    /// - Parameter key: Storage key
    /// - Returns: Boolean value
    func bool(forKey key: String) -> Bool {
        userDefaults.bool(forKey: key)
    }

    // MARK: - Double Operations

    /// Store double value
    /// - Parameters:
    ///   - value: Value to store
    ///   - key: Storage key
    func set(_ value: Double, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// Retrieve double value
    /// - Parameter key: Storage key
    /// - Returns: Double value
    func double(forKey key: String) -> Double {
        userDefaults.double(forKey: key)
    }

    // MARK: - Data Operations

    /// Store data value
    /// - Parameters:
    ///   - value: Data to store
    ///   - key: Storage key
    func set(_ value: Data?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// Retrieve data value
    /// - Parameter key: Storage key
    /// - Returns: Data or nil
    func data(forKey key: String) -> Data? {
        userDefaults.data(forKey: key)
    }

    // MARK: - Codable Operations

    /// Store encodable object
    /// - Parameters:
    ///   - object: Object to encode and store
    ///   - key: Storage key
    func setCodable<T: Encodable>(_ object: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        userDefaults.set(data, forKey: key)
    }

    /// Retrieve decodable object
    /// - Parameters:
    ///   - type: Expected type
    ///   - key: Storage key
    /// - Returns: Decoded object or nil
    func codable<T: Decodable>(as type: T.Type, forKey key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }

    // MARK: - Dictionary/Array Operations

    /// Store dictionary
    /// - Parameters:
    ///   - value: Dictionary to store
    ///   - key: Storage key
    func set(_ value: [String: Any]?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// Retrieve dictionary
    /// - Parameter key: Storage key
    /// - Returns: Dictionary or empty dictionary
    func dictionary(forKey key: String) -> [String: Any]? {
        userDefaults.dictionary(forKey: key)
    }

    /// Store array
    /// - Parameters:
    ///   - value: Array to store
    ///   - key: Storage key
    func set(_ value: [Any]?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// Retrieve array
    /// - Parameter key: Storage key
    /// - Returns: Array or empty array
    func array(forKey key: String) -> [Any]? {
        userDefaults.array(forKey: key)
    }

    // MARK: - Generic Operations

    /// Store any object
    /// - Parameters:
    ///   - object: Object to store
    ///   - key: Storage key
    func set(_ object: Any?, forKey key: String) {
        userDefaults.set(object, forKey: key)
    }

    /// Retrieve any object
    /// - Parameter key: Storage key
    /// - Returns: Object or nil
    func object(forKey key: String) -> Any? {
        userDefaults.object(forKey: key)
    }

    // MARK: - Existence and Removal

    /// Check if key exists
    /// - Parameter key: Storage key
    /// - Returns: True if key exists
    func hasKey(_ key: String) -> Bool {
        userDefaults.object(forKey: key) != nil
    }

    /// Remove value for key
    /// - Parameter key: Storage key
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }

    /// Clear all stored values
    func clear() {
        for key in userDefaults.dictionaryRepresentation().keys {
            userDefaults.removeObject(forKey: key)
        }
        Logger.warning("UserDefaults cleared for \(suiteName)")
    }

    /// Get all stored keys
    /// - Returns: Array of keys
    func allKeys() -> [String] {
        Array(userDefaults.dictionaryRepresentation().keys)
    }

    /// Synchronize to disk
    func synchronize() {
        userDefaults.synchronize()
    }
}

// MARK: - Convenience Extensions

extension UserDefaultsDataSource {
    /// Preference key definitions
    struct PreferenceKey {
        static let userId = "com.ai4science.userId"
        static let userEmail = "com.ai4science.userEmail"
        static let authToken = "com.ai4science.authToken"
        static let appVersion = "com.ai4science.appVersion"
        static let lastSyncDate = "com.ai4science.lastSyncDate"
        static let onboardingCompleted = "com.ai4science.onboardingCompleted"
        static let appSettings = "com.ai4science.appSettings"
    }

    /// Set user preferences
    /// - Parameters:
    ///   - id: User ID
    ///   - email: User email
    ///   - token: Auth token
    func setUserPreferences(id: String, email: String, token: String) {
        set(id, forKey: PreferenceKey.userId)
        set(email, forKey: PreferenceKey.userEmail)
        set(token, forKey: PreferenceKey.authToken)
    }

    /// Get user ID
    func getUserId() -> String? {
        string(forKey: PreferenceKey.userId)
    }

    /// Get user email
    func getUserEmail() -> String? {
        string(forKey: PreferenceKey.userEmail)
    }

    /// Get auth token
    func getAuthToken() -> String? {
        string(forKey: PreferenceKey.authToken)
    }

    /// Check if onboarding is completed
    func isOnboardingCompleted() -> Bool {
        bool(forKey: PreferenceKey.onboardingCompleted)
    }

    /// Mark onboarding as completed
    func markOnboardingCompleted() {
        set(true, forKey: PreferenceKey.onboardingCompleted)
    }
}
