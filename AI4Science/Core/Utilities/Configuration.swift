import Foundation

/// Application configuration
public actor Configuration {
    /// API endpoints
    public struct APIEndpoints: Sendable {
        public let baseURL: URL
        public let authPath: String
        public let projectsPath: String
        public let samplesPath: String
        public let capturesPath: String
        public let annotationsPath: String
        public let modelsPath: String
        public let analysisPath: String
        public let syncPath: String

        public init(
            baseURL: URL,
            authPath: String = "/api/v1/auth",
            projectsPath: String = "/api/v1/projects",
            samplesPath: String = "/api/v1/samples",
            capturesPath: String = "/api/v1/captures",
            annotationsPath: String = "/api/v1/annotations",
            modelsPath: String = "/api/v1/models",
            analysisPath: String = "/api/v1/analysis",
            syncPath: String = "/api/v1/sync"
        ) {
            self.baseURL = baseURL
            self.authPath = authPath
            self.projectsPath = projectsPath
            self.samplesPath = samplesPath
            self.capturesPath = capturesPath
            self.annotationsPath = annotationsPath
            self.modelsPath = modelsPath
            self.analysisPath = analysisPath
            self.syncPath = syncPath
        }
    }

    /// Network configuration
    public struct NetworkConfig: Sendable {
        public let timeoutInterval: TimeInterval
        public let maxRetries: Int
        public let retryDelay: TimeInterval
        public let enableLogging: Bool

        public init(
            timeoutInterval: TimeInterval = 30,
            maxRetries: Int = 3,
            retryDelay: TimeInterval = 1.0,
            enableLogging: Bool = true
        ) {
            self.timeoutInterval = timeoutInterval
            self.maxRetries = maxRetries
            self.retryDelay = retryDelay
            self.enableLogging = enableLogging
        }
    }

    /// Storage configuration
    public struct StorageConfig: Sendable {
        public let maxCacheSize: Int64
        public let maxLocalStorageSize: Int64
        public let cacheExpiration: TimeInterval
        public let useCloudSync: Bool

        public init(
            maxCacheSize: Int64 = 1024 * 1024 * 100,
            maxLocalStorageSize: Int64 = 1024 * 1024 * 500,
            cacheExpiration: TimeInterval = 3600 * 24 * 7,
            useCloudSync: Bool = true
        ) {
            self.maxCacheSize = maxCacheSize
            self.maxLocalStorageSize = maxLocalStorageSize
            self.cacheExpiration = cacheExpiration
            self.useCloudSync = useCloudSync
        }
    }

    /// Feature flags
    public struct FeatureFlags: Sendable {
        public var enableOfflineMode: Bool
        public var enableAnalytics: Bool
        public var enableCrashReporting: Bool
        public var enableAdvancedML: Bool
        public var enableBetaFeatures: Bool
        public var enableDebugMenu: Bool

        public init(
            enableOfflineMode: Bool = true,
            enableAnalytics: Bool = true,
            enableCrashReporting: Bool = true,
            enableAdvancedML: Bool = false,
            enableBetaFeatures: Bool = false,
            enableDebugMenu: Bool = false
        ) {
            self.enableOfflineMode = enableOfflineMode
            self.enableAnalytics = enableAnalytics
            self.enableCrashReporting = enableCrashReporting
            self.enableAdvancedML = enableAdvancedML
            self.enableBetaFeatures = enableBetaFeatures
            self.enableDebugMenu = enableDebugMenu
        }
    }

    private static let instance = Configuration()

    private var apiEndpoints: APIEndpoints
    private var networkConfig: NetworkConfig
    private var storageConfig: StorageConfig
    private var featureFlags: FeatureFlags
    private var environment: AppEnvironment

    private init() {
        self.environment = .development
        self.apiEndpoints = APIEndpoints(baseURL: URL(string: "https://api.ai4science.local")!)
        self.networkConfig = NetworkConfig()
        self.storageConfig = StorageConfig()
        self.featureFlags = FeatureFlags()
    }

    /// Get shared configuration instance
    public static var shared: Configuration {
        instance
    }

    /// Environment
    public enum AppEnvironment: String, Sendable {
        case development
        case staging
        case production
    }

    // MARK: - Getters

    nonisolated public var endpoints: APIEndpoints {
        get async {
            await instance.apiEndpoints
        }
    }

    nonisolated public var network: NetworkConfig {
        get async {
            await instance.networkConfig
        }
    }

    nonisolated public var storage: StorageConfig {
        get async {
            await instance.storageConfig
        }
    }

    nonisolated public var features: FeatureFlags {
        get async {
            await instance.featureFlags
        }
    }

    nonisolated public var env: AppEnvironment {
        get async {
            await instance.environment
        }
    }

    // MARK: - Setters

    func setEnvironment(_ env: AppEnvironment) {
        self.environment = env
    }

    func setAPIEndpoints(_ endpoints: APIEndpoints) {
        self.apiEndpoints = endpoints
    }

    func setNetworkConfig(_ config: NetworkConfig) {
        self.networkConfig = config
    }

    func setStorageConfig(_ config: StorageConfig) {
        self.storageConfig = config
    }

    func setFeatureFlags(_ flags: FeatureFlags) {
        self.featureFlags = flags
    }

    func updateFeatureFlag(_ keyPath: WritableKeyPath<FeatureFlags, Bool>, to value: Bool) {
        self.featureFlags[keyPath: keyPath] = value
    }

    // MARK: - Initialization

    /// Initialize configuration for development
    func initializeDevelopment() {
        self.environment = .development
        self.apiEndpoints = APIEndpoints(baseURL: URL(string: "http://localhost:8000")!)
        self.networkConfig = NetworkConfig(enableLogging: true)
        self.featureFlags.enableDebugMenu = true
        self.featureFlags.enableBetaFeatures = true
    }

    /// Initialize configuration for staging
    func initializeStaging() {
        self.environment = .staging
        self.apiEndpoints = APIEndpoints(baseURL: URL(string: "https://staging-api.ai4science.app")!)
        self.networkConfig = NetworkConfig(enableLogging: true)
    }

    /// Initialize configuration for production
    func initializeProduction() {
        self.environment = .production
        self.apiEndpoints = APIEndpoints(baseURL: URL(string: "https://api.ai4science.app")!)
        self.networkConfig = NetworkConfig(enableLogging: false)
        self.featureFlags.enableDebugMenu = false
        self.featureFlags.enableBetaFeatures = false
    }

    // MARK: - Helpers

    nonisolated public var isDevelopment: Bool {
        get async {
            await instance.environment == .development
        }
    }

    nonisolated public var isStaging: Bool {
        get async {
            await instance.environment == .staging
        }
    }

    nonisolated public var isProduction: Bool {
        get async {
            await instance.environment == .production
        }
    }
}
