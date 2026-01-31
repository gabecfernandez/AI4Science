import Foundation

/// Application-wide constants
public struct AppConstants: Sendable {
    /// Bundle information
    public struct Bundle: Sendable {
        public static let appName = "AI4Science"
        public static let bundleIdentifier = "com.ai4science"
        public static let version = "1.0.0"
        public static let buildNumber = "1"
    }

    /// User defaults keys
    public struct UserDefaults: Sendable {
        public static let lastSyncTime = "com.ai4science.lastSyncTime"
        public static let isOnboarded = "com.ai4science.isOnboarded"
        public static let authToken = "com.ai4science.authToken"
        public static let userId = "com.ai4science.userId"
        public static let userEmail = "com.ai4science.userEmail"
        public static let preferredCamera = "com.ai4science.preferredCamera"
        public static let enableNotifications = "com.ai4science.enableNotifications"
        public static let enableOfflineMode = "com.ai4science.enableOfflineMode"
        public static let appTheme = "com.ai4science.appTheme"
    }

    /// Keychain keys
    public struct Keychain: Sendable {
        public static let authTokenKey = "com.ai4science.authToken"
        public static let refreshTokenKey = "com.ai4science.refreshToken"
        public static let userPasswordKey = "com.ai4science.userPassword"
        public static let biometricKey = "com.ai4science.biometric"
    }

    /// Database identifiers
    public struct Database: Sendable {
        public static let modelName = "AI4Science"
        public static let schemaVersion: UInt64 = 1
    }

    /// Directory names
    public struct Directories: Sendable {
        public static let captures = "Captures"
        public static let projects = "Projects"
        public static let models = "MLModels"
        public static let cache = "Cache"
        public static let temp = "Temp"
        public static let annotations = "Annotations"
        public static let analysis = "Analysis"
    }

    /// File names
    public struct Files: Sendable {
        public static let syncQueue = "sync_queue.json"
        public static let offlineData = "offline_data.json"
        public static let appConfig = "app_config.json"
        public static let userPreferences = "preferences.json"
    }

    /// Network timeouts
    public struct NetworkTimeouts: Sendable {
        public static let defaultTimeout: TimeInterval = 30
        public static let uploadTimeout: TimeInterval = 300
        public static let downloadTimeout: TimeInterval = 600
        public static let modelDownloadTimeout: TimeInterval = 1800
    }

    /// Cache settings
    public struct Cache: Sendable {
        public static let maxCacheSize: Int64 = 1024 * 1024 * 100 // 100 MB
        public static let maxLocalStorage: Int64 = 1024 * 1024 * 500 // 500 MB
        public static let cacheExpiration: TimeInterval = 3600 * 24 * 7 // 7 days
        public static let imageCacheExpiration: TimeInterval = 3600 * 24 * 30 // 30 days
    }

    /// Image settings
    public struct Images: Sendable {
        public static let maxPhotoWidth: CGFloat = 4096
        public static let maxPhotoHeight: CGFloat = 4096
        public static let thumbnailWidth: CGFloat = 256
        public static let thumbnailHeight: CGFloat = 256
        public static let maxPhotoFileSize: Int64 = 1024 * 1024 * 50 // 50 MB
        public static let jpegCompressionQuality: CGFloat = 0.85
    }

    /// Video settings
    public struct Video: Sendable {
        public static let maxVideoDuration: TimeInterval = 300 // 5 minutes
        public static let maxVideoFileSize: Int64 = 1024 * 1024 * 500 // 500 MB
        public static let videoBitrate: Int = 5_000_000 // 5 Mbps
        public static let audioSampleRate: Int = 44100
    }

    /// ML Model settings
    public struct MLModel: Sendable {
        public static let modelCacheSize: Int64 = 1024 * 1024 * 200 // 200 MB
        public static let maxSimultaneousModels = 2
        public static let inferenceTimeout: TimeInterval = 30
        public static let batchInferenceSize = 10
    }

    /// Sync settings
    public struct Sync: Sendable {
        public static let autoSyncInterval: TimeInterval = 300 // 5 minutes
        public static let maxRetries = 3
        public static let retryDelay: TimeInterval = 5
        public static let exponentialBackoffMultiplier: Double = 2.0
    }

    /// UI constants
    public struct UI: Sendable {
        public static let cornerRadius: CGFloat = 8
        public static let smallCornerRadius: CGFloat = 4
        public static let largeCornerRadius: CGFloat = 16
        public static let defaultPadding: CGFloat = 16
        public static let smallPadding: CGFloat = 8
        public static let largePadding: CGFloat = 24
        public static let animationDuration: TimeInterval = 0.3
        public static let defaultLineWidth: CGFloat = 1
    }

    /// Validation
    public struct Validation: Sendable {
        public static let minPasswordLength = 8
        public static let maxProjectNameLength = 100
        public static let maxProjectDescriptionLength = 1000
        public static let maxSampleNameLength = 100
        public static let maxAnnotationNotesLength = 500
    }

    /// Analytics
    public struct Analytics: Sendable {
        public static let eventBatchSize = 50
        public static let eventFlushInterval: TimeInterval = 60
        public static let maxEventQueueSize = 1000
    }

    /// Error codes
    public struct ErrorCodes: Sendable {
        public static let unknownError = -1
        public static let networkError = 1000
        public static let authenticationError = 2000
        public static let validationError = 3000
        public static let storageError = 4000
        public static let mlModelError = 5000
        public static let cameraError = 6000
        public static let syncError = 7000
    }

    /// Notification names
    public struct Notifications: Sendable {
        public static let authTokenRefreshed = NSNotification.Name("com.ai4science.authTokenRefreshed")
        public static let userLoggedOut = NSNotification.Name("com.ai4science.userLoggedOut")
        public static let projectUpdated = NSNotification.Name("com.ai4science.projectUpdated")
        public static let captureCompleted = NSNotification.Name("com.ai4science.captureCompleted")
        public static let syncStarted = NSNotification.Name("com.ai4science.syncStarted")
        public static let syncCompleted = NSNotification.Name("com.ai4science.syncCompleted")
        public static let offlineModeEnabled = NSNotification.Name("com.ai4science.offlineModeEnabled")
    }

    /// Date formats
    public struct DateFormats: Sendable {
        public static let iso8601 = "yyyy-MM-dd'T'HH:mm:ssZ"
        public static let dateOnly = "yyyy-MM-dd"
        public static let timeOnly = "HH:mm:ss"
        public static let dateTime = "yyyy-MM-dd HH:mm:ss"
        public static let displayDate = "MMM d, yyyy"
        public static let displayDateTime = "MMM d, yyyy h:mm a"
    }

    /// Locale settings
    public struct Locale: Sendable {
        public static let defaultLocale = Foundation.Locale.current
        public static let usLocale = Foundation.Locale(identifier: "en_US")
    }
}
