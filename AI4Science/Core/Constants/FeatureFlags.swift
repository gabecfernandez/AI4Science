import Foundation

/// Feature flags for conditional feature availability
public actor FeatureFlags: Sendable {
    private static let instance = FeatureFlags()

    // MARK: - Core Features

    private var offlineModeEnabled: Bool = true
    private var cloudSyncEnabled: Bool = true
    private var analyticsEnabled: Bool = true
    private var crashReportingEnabled: Bool = true

    // MARK: - ML Features

    private var advancedMLEnabled: Bool = false
    private var onDeviceInferenceEnabled: Bool = true
    private var batchInferenceEnabled: Bool = true
    private var autoAnnotationEnabled: Bool = false

    // MARK: - Camera Features

    private var multiCameraCapureEnabled: Bool = true
    private var torchEnabled: Bool = true
    private var videoRecordingEnabled: Bool = true
    private var livePreviewEnabled: Bool = true

    // MARK: - Data Features

    private var cloudBackupEnabled: Bool = true
    private var dataCompressionEnabled: Bool = true
    private var encryptionEnabled: Bool = true
    private var differentialSyncEnabled: Bool = false

    // MARK: - UI Features

    private var darkModeEnabled: Bool = true
    private var landscapeOrientationEnabled: Bool = false
    private var tabletUIEnabled: Bool = true
    private var customThemeEnabled: Bool = false

    // MARK: - Experimental Features

    private var betaFeaturesEnabled: Bool = false
    private var debugMenuEnabled: Bool = false
    private var performanceMetricsEnabled: Bool = true
    private var experimentalAnnotationToolsEnabled: Bool = false

    // MARK: - Get Shared Instance

    nonisolated static var shared: FeatureFlags {
        Self.instance
    }

    // MARK: - Core Feature Getters

    nonisolated func isOfflineModeEnabled() async -> Bool {
        await Self.instance.offlineModeEnabled
    }

    nonisolated func isCloudSyncEnabled() async -> Bool {
        await Self.instance.cloudSyncEnabled
    }

    nonisolated func isAnalyticsEnabled() async -> Bool {
        await Self.instance.analyticsEnabled
    }

    nonisolated func isCrashReportingEnabled() async -> Bool {
        await Self.instance.crashReportingEnabled
    }

    // MARK: - ML Feature Getters

    nonisolated func isAdvancedMLEnabled() async -> Bool {
        await Self.instance.advancedMLEnabled
    }

    nonisolated func isOnDeviceInferenceEnabled() async -> Bool {
        await Self.instance.onDeviceInferenceEnabled
    }

    nonisolated func isBatchInferenceEnabled() async -> Bool {
        await Self.instance.batchInferenceEnabled
    }

    nonisolated func isAutoAnnotationEnabled() async -> Bool {
        await Self.instance.autoAnnotationEnabled
    }

    // MARK: - Camera Feature Getters

    nonisolated func isMultiCameraCapureEnabled() async -> Bool {
        await Self.instance.multiCameraCapureEnabled
    }

    nonisolated func isTorchEnabled() async -> Bool {
        await Self.instance.torchEnabled
    }

    nonisolated func isVideoRecordingEnabled() async -> Bool {
        await Self.instance.videoRecordingEnabled
    }

    nonisolated func isLivePreviewEnabled() async -> Bool {
        await Self.instance.livePreviewEnabled
    }

    // MARK: - Data Feature Getters

    nonisolated func isCloudBackupEnabled() async -> Bool {
        await Self.instance.cloudBackupEnabled
    }

    nonisolated func isDataCompressionEnabled() async -> Bool {
        await Self.instance.dataCompressionEnabled
    }

    nonisolated func isEncryptionEnabled() async -> Bool {
        await Self.instance.encryptionEnabled
    }

    nonisolated func isDifferentialSyncEnabled() async -> Bool {
        await Self.instance.differentialSyncEnabled
    }

    // MARK: - UI Feature Getters

    nonisolated func isDarkModeEnabled() async -> Bool {
        await Self.instance.darkModeEnabled
    }

    nonisolated func isLandscapeOrientationEnabled() async -> Bool {
        await Self.instance.landscapeOrientationEnabled
    }

    nonisolated func isTabletUIEnabled() async -> Bool {
        await Self.instance.tabletUIEnabled
    }

    nonisolated func isCustomThemeEnabled() async -> Bool {
        await Self.instance.customThemeEnabled
    }

    // MARK: - Experimental Feature Getters

    nonisolated func isBetaFeaturesEnabled() async -> Bool {
        await Self.instance.betaFeaturesEnabled
    }

    nonisolated func isDebugMenuEnabled() async -> Bool {
        await Self.instance.debugMenuEnabled
    }

    nonisolated func isPerformanceMetricsEnabled() async -> Bool {
        await Self.instance.performanceMetricsEnabled
    }

    nonisolated func isExperimentalAnnotationToolsEnabled() async -> Bool {
        await Self.instance.experimentalAnnotationToolsEnabled
    }

    // MARK: - Setters

    func setOfflineModeEnabled(_ enabled: Bool) {
        self.offlineModeEnabled = enabled
    }

    func setCloudSyncEnabled(_ enabled: Bool) {
        self.cloudSyncEnabled = enabled
    }

    func setAnalyticsEnabled(_ enabled: Bool) {
        self.analyticsEnabled = enabled
    }

    func setCrashReportingEnabled(_ enabled: Bool) {
        self.crashReportingEnabled = enabled
    }

    func setAdvancedMLEnabled(_ enabled: Bool) {
        self.advancedMLEnabled = enabled
    }

    func setOnDeviceInferenceEnabled(_ enabled: Bool) {
        self.onDeviceInferenceEnabled = enabled
    }

    func setBatchInferenceEnabled(_ enabled: Bool) {
        self.batchInferenceEnabled = enabled
    }

    func setAutoAnnotationEnabled(_ enabled: Bool) {
        self.autoAnnotationEnabled = enabled
    }

    func setMultiCameraCapureEnabled(_ enabled: Bool) {
        self.multiCameraCapureEnabled = enabled
    }

    func setTorchEnabled(_ enabled: Bool) {
        self.torchEnabled = enabled
    }

    func setVideoRecordingEnabled(_ enabled: Bool) {
        self.videoRecordingEnabled = enabled
    }

    func setLivePreviewEnabled(_ enabled: Bool) {
        self.livePreviewEnabled = enabled
    }

    func setCloudBackupEnabled(_ enabled: Bool) {
        self.cloudBackupEnabled = enabled
    }

    func setDataCompressionEnabled(_ enabled: Bool) {
        self.dataCompressionEnabled = enabled
    }

    func setEncryptionEnabled(_ enabled: Bool) {
        self.encryptionEnabled = enabled
    }

    func setDifferentialSyncEnabled(_ enabled: Bool) {
        self.differentialSyncEnabled = enabled
    }

    func setDarkModeEnabled(_ enabled: Bool) {
        self.darkModeEnabled = enabled
    }

    func setLandscapeOrientationEnabled(_ enabled: Bool) {
        self.landscapeOrientationEnabled = enabled
    }

    func setTabletUIEnabled(_ enabled: Bool) {
        self.tabletUIEnabled = enabled
    }

    func setCustomThemeEnabled(_ enabled: Bool) {
        self.customThemeEnabled = enabled
    }

    func setBetaFeaturesEnabled(_ enabled: Bool) {
        self.betaFeaturesEnabled = enabled
    }

    func setDebugMenuEnabled(_ enabled: Bool) {
        self.debugMenuEnabled = enabled
    }

    func setPerformanceMetricsEnabled(_ enabled: Bool) {
        self.performanceMetricsEnabled = enabled
    }

    func setExperimentalAnnotationToolsEnabled(_ enabled: Bool) {
        self.experimentalAnnotationToolsEnabled = enabled
    }

    // MARK: - Configuration Presets

    /// Configure for development environment
    func configureDevelopment() {
        self.debugMenuEnabled = true
        self.betaFeaturesEnabled = true
        self.performanceMetricsEnabled = true
        self.experimentalAnnotationToolsEnabled = true
    }

    /// Configure for staging environment
    func configureStaging() {
        self.debugMenuEnabled = true
        self.betaFeaturesEnabled = true
        self.performanceMetricsEnabled = true
        self.experimentalAnnotationToolsEnabled = false
    }

    /// Configure for production environment
    func configureProduction() {
        self.debugMenuEnabled = false
        self.betaFeaturesEnabled = false
        self.performanceMetricsEnabled = false
        self.experimentalAnnotationToolsEnabled = false
    }

    /// Reset to default values
    func resetToDefaults() {
        self.offlineModeEnabled = true
        self.cloudSyncEnabled = true
        self.analyticsEnabled = true
        self.crashReportingEnabled = true
        self.advancedMLEnabled = false
        self.onDeviceInferenceEnabled = true
        self.batchInferenceEnabled = true
        self.autoAnnotationEnabled = false
        self.multiCameraCapureEnabled = true
        self.torchEnabled = true
        self.videoRecordingEnabled = true
        self.livePreviewEnabled = true
        self.cloudBackupEnabled = true
        self.dataCompressionEnabled = true
        self.encryptionEnabled = true
        self.differentialSyncEnabled = false
        self.darkModeEnabled = true
        self.landscapeOrientationEnabled = false
        self.tabletUIEnabled = true
        self.customThemeEnabled = false
        self.betaFeaturesEnabled = false
        self.debugMenuEnabled = false
        self.performanceMetricsEnabled = true
        self.experimentalAnnotationToolsEnabled = false
    }

    // MARK: - Debug Helper

    nonisolated func getAllFlags() async -> [String: Bool] {
        await Self.instance.getAllFlagsInternal()
    }

    private func getAllFlagsInternal() -> [String: Bool] {
        [
            "offlineMode": offlineModeEnabled,
            "cloudSync": cloudSyncEnabled,
            "analytics": analyticsEnabled,
            "crashReporting": crashReportingEnabled,
            "advancedML": advancedMLEnabled,
            "onDeviceInference": onDeviceInferenceEnabled,
            "batchInference": batchInferenceEnabled,
            "autoAnnotation": autoAnnotationEnabled,
            "multiCameraCapure": multiCameraCapureEnabled,
            "torch": torchEnabled,
            "videoRecording": videoRecordingEnabled,
            "livePreview": livePreviewEnabled,
            "cloudBackup": cloudBackupEnabled,
            "dataCompression": dataCompressionEnabled,
            "encryption": encryptionEnabled,
            "differentialSync": differentialSyncEnabled,
            "darkMode": darkModeEnabled,
            "landscapeOrientation": landscapeOrientationEnabled,
            "tabletUI": tabletUIEnabled,
            "customTheme": customThemeEnabled,
            "betaFeatures": betaFeaturesEnabled,
            "debugMenu": debugMenuEnabled,
            "performanceMetrics": performanceMetricsEnabled,
            "experimentalAnnotationTools": experimentalAnnotationToolsEnabled
        ]
    }
}
