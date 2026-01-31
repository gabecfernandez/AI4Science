import Foundation
import SwiftData

/// ML Model persistence model for SwiftData
/// Represents downloaded and available ML models for analysis
@Model
final class MLModelEntity {
    /// Unique identifier for the model
    @Attribute(.unique) var id: String

    /// Model name
    var name: String

    /// Model description
    var description: String

    /// Model version
    var version: String

    /// Model type (classification, segmentation, detection, etc.)
    var modelType: String

    /// Model framework (CoreML, PyTorch, etc.)
    var framework: String

    /// Input specifications (JSON)
    var inputSpec: String

    /// Output specifications (JSON)
    var outputSpec: String

    /// Local file path to the model
    var localPath: String?

    /// Remote URL for downloading
    var remoteURL: String?

    /// File size in bytes
    var fileSize: Int64 = 0

    /// Checksum for integrity verification
    var checksum: String?

    /// Download status
    var downloadStatus: String = "not_downloaded"

    /// Download progress (0-1)
    var downloadProgress: Double = 0.0

    /// Creation timestamp
    var createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    /// Whether model is enabled for use
    var isEnabled: Bool = true

    /// Minimum iOS version required
    var minIOSVersion: String = "15.0"

    /// Whether model requires network access
    var requiresNetwork: Bool = false

    /// Model accuracy/performance info
    var performanceMetrics: [String: Double] = [:]

    /// Supported input formats
    var supportedFormats: [String] = []

    /// Relationship to analysis configurations
    @Relationship(deleteRule: .cascade) var analysisConfigs: [AnalysisConfig] = []

    /// Initialization
    init(
        id: String,
        name: String,
        description: String,
        version: String,
        modelType: String,
        framework: String,
        inputSpec: String,
        outputSpec: String
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.version = version
        self.modelType = modelType
        self.framework = framework
        self.inputSpec = inputSpec
        self.outputSpec = outputSpec
    }

    /// Update download status
    @MainActor
    func updateDownloadStatus(_ status: String, progress: Double = 0.0) {
        self.downloadStatus = status
        self.downloadProgress = min(max(progress, 0.0), 1.0)
        self.updatedAt = Date()
    }

    /// Mark download as completed
    @MainActor
    func markDownloadCompleted(localPath: String) {
        self.downloadStatus = "downloaded"
        self.downloadProgress = 1.0
        self.localPath = localPath
        self.updatedAt = Date()
    }

    /// Set performance metrics
    @MainActor
    func setPerformanceMetrics(_ metrics: [String: Double]) {
        self.performanceMetrics = metrics
        self.updatedAt = Date()
    }

    /// Toggle model enabled status
    @MainActor
    func toggleEnabled() {
        self.isEnabled.toggle()
        self.updatedAt = Date()
    }

    /// Check if model is ready for use
    nonisolated var isReadyForUse: Bool {
        downloadStatus == "downloaded" && localPath != nil && isEnabled
    }

    /// Get config count
    nonisolated var configCount: Int {
        analysisConfigs.count
    }
}

/// Analysis configuration for ML models
@Model
final class AnalysisConfig {
    var configName: String
    var configType: String
    var parameters: [String: String] = [:]
    var isDefault: Bool = false
    var createdAt: Date = Date()

    init(
        configName: String,
        configType: String,
        isDefault: Bool = false
    ) {
        self.configName = configName
        self.configType = configType
        self.isDefault = isDefault
    }
}
