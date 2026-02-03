import Foundation

/// Application configuration singleton
public actor AppConfiguration: Sendable {
    public static let shared = AppConfiguration()

    // MARK: - App Info

    public var appName: String { "AI4Science" }
    public var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    public var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Environment

    public enum Environment {
        case development
        case staging
        case production
    }

    private var _environment: Environment = .development

    public var environment: Environment {
        get { _environment }
        set { _environment = newValue }
    }

    public var isDevelopment: Bool { environment == .development }
    public var isStaging: Bool { environment == .staging }
    public var isProduction: Bool { environment == .production }

    // MARK: - Feature Flags

    private var _featureFlags: [String: Bool] = [:]

    public func setFeatureFlag(_ name: String, enabled: Bool) {
        _featureFlags[name] = enabled
    }

    public func isFeatureEnabled(_ name: String) -> Bool {
        _featureFlags[name] ?? false
    }

    // MARK: - Logging

    public var logLevel: AppLogger.Level = .info

    // MARK: - Timeouts

    public var networkTimeoutSeconds: TimeInterval = 30
    public var cacheExpirationSeconds: TimeInterval = 3600

    // MARK: - ML Model Configuration

    public var mlModelOutputSizeBytes: Int = 1024 * 1024 // 1MB default
    public var enableNeuralEngineAcceleration: Bool = true
    public var mlModelQuantized: Bool = true

    // MARK: - Camera Configuration

    public var defaultCameraResolution: CGSize = CGSize(width: 1920, height: 1080)
    public var enableAutoFocus: Bool = true
    public var enableExposureControl: Bool = true

    // MARK: - Storage Configuration

    public var maxCacheSize: Int = 500 * 1024 * 1024 // 500MB
    public var maxDatabaseSize: Int = 1000 * 1024 * 1024 // 1GB

    // MARK: - Sync Configuration

    public var autoSyncEnabled: Bool = true
    public var syncIntervalSeconds: TimeInterval = 300 // 5 minutes

    private init() {}

    public var description: String {
        """
        AppConfiguration:
        - App: \(appName) v\(appVersion) (\(buildNumber))
        - Environment: \(environment)
        - Log Level: \(logLevel)
        - Network Timeout: \(networkTimeoutSeconds)s
        - Cache Expiration: \(cacheExpirationSeconds)s
        - ML Output Size: \(mlModelOutputSizeBytes) bytes
        - Neural Engine: \(enableNeuralEngineAcceleration)
        - Quantized Models: \(mlModelQuantized)
        - Max Cache: \(maxCacheSize) bytes
        - Max DB: \(maxDatabaseSize) bytes
        - Auto Sync: \(autoSyncEnabled) @ \(syncIntervalSeconds)s
        """
    }
}
