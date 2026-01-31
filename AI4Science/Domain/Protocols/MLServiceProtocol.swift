import Foundation

/// ML service abstraction for managing machine learning models
public protocol MLServiceProtocol: Sendable {
    /// Loads an ML model into memory
    /// - Parameter modelId: Model identifier
    /// - Returns: LoadedMLModel
    /// - Throws: MLError if loading fails
    func loadModel(modelId: String) async throws -> LoadedMLModel

    /// Unloads a model from memory
    /// - Parameter modelId: Model identifier
    /// - Throws: MLError if unloading fails
    func unloadModel(modelId: String) async throws

    /// Preloads multiple models
    /// - Parameter modelIds: Array of model identifiers
    /// - Returns: PreloadResult
    /// - Throws: MLError if preloading fails
    func preloadModels(modelIds: [String]) async throws -> PreloadResult

    /// Lists available models
    /// - Returns: Array of ModelInfo
    /// - Throws: MLError if fetch fails
    func listAvailableModels() async throws -> [ModelInfo]

    /// Gets information about a model
    /// - Parameter modelId: Model identifier
    /// - Returns: ModelInfo
    /// - Throws: MLError if fetch fails
    func getModelInfo(modelId: String) async throws -> ModelInfo

    /// Filters models by type
    /// - Parameter type: Model type
    /// - Returns: Filtered models
    /// - Throws: MLError if fetch fails
    func getModels(ofType type: ModelType) async throws -> [ModelInfo]

    /// Downloads a model for offline use
    /// - Parameter modelId: Model identifier
    /// - Returns: ModelDownloadProgress
    /// - Throws: MLError if download fails
    func downloadModel(modelId: String) async throws -> ModelDownloadProgress

    /// Downloads multiple models
    /// - Parameter modelIds: Array of model identifiers
    /// - Returns: BatchDownloadResult
    /// - Throws: MLError if download fails
    func downloadModels(modelIds: [String]) async throws -> BatchDownloadResult

    /// Checks for model updates
    /// - Parameter modelId: Model identifier
    /// - Returns: ModelUpdateInfo if update available
    /// - Throws: MLError if check fails
    func checkForUpdates(modelId: String) async throws -> ModelUpdateInfo?

    /// Checks for updates across multiple models
    /// - Parameter modelIds: Array of model identifiers
    /// - Returns: Array of available updates
    /// - Throws: MLError if check fails
    func checkForUpdates(modelIds: [String]) async throws -> [ModelUpdateInfo]

    /// Installs a model update
    /// - Parameter updateInfo: Update information
    /// - Returns: Updated ModelInfo
    /// - Throws: MLError if installation fails
    func installUpdate(_ updateInfo: ModelUpdateInfo) async throws -> ModelInfo

    /// Automatically installs all available updates
    /// - Returns: UpdateInstallationResult
    /// - Throws: MLError if installation fails
    func installAllUpdates() async throws -> UpdateInstallationResult

    /// Gets model storage usage
    /// - Returns: Storage usage in bytes
    /// - Throws: MLError if fetch fails
    func getStorageUsage() async throws -> Int

    /// Cleans up unused models
    /// - Returns: Bytes freed
    /// - Throws: MLError if cleanup fails
    func cleanupUnusedModels() async throws -> Int
}
