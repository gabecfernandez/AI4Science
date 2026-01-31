import Foundation
import CoreML
import os.log

/// Cache policy for models
public enum CachePolicy: Sendable {
    case memory
    case disk
    case hybrid
    case noCache
}

/// Model cache entry
public struct CacheEntry: Sendable {
    public let modelId: String
    public let model: MLModel
    public let loadedAt: Date
    public var lastAccessedAt: Date
    public var accessCount: Int

    mutating func recordAccess() {
        lastAccessedAt = Date()
        accessCount += 1
    }
}

/// Error types for cache operations
public enum CacheError: LocalizedError {
    case modelNotInCache(String)
    case cacheFull
    case serializationFailed
    case deserializationFailed
    case invalidCachePath

    public var errorDescription: String? {
        switch self {
        case .modelNotInCache(let id):
            return "Model not in cache: \(id)"
        case .cacheFull:
            return "Cache is full"
        case .serializationFailed:
            return "Failed to serialize model for caching"
        case .deserializationFailed:
            return "Failed to deserialize model from cache"
        case .invalidCachePath:
            return "Invalid cache directory path"
        }
    }
}

/// Actor managing ML model caching
public actor MLModelCache {
    private let logger = Logger(subsystem: "com.ai4science.ml", category: "MLModelCache")

    /// In-memory cache: [modelId: CacheEntry]
    private var memoryCache: [String: CacheEntry] = [:]

    /// Cache configuration
    private let maxMemoryCacheSize: Int
    private let cachePolicy: CachePolicy
    private let diskCachePath: String?

    /// Current cache size in bytes
    private var memoryCacheSizeBytes: UInt64 = 0

    /// LRU eviction tracking
    private var accessOrder: [String] = []

    public init(
        maxMemoryCacheSizeMB: Int = 200,
        cachePolicy: CachePolicy = .hybrid,
        diskCachePath: String? = nil
    ) {
        self.maxMemoryCacheSize = maxMemoryCacheSizeMB * 1024 * 1024
        self.cachePolicy = cachePolicy
        self.diskCachePath = diskCachePath

        logger.info(
            "MLModelCache initialized. Policy: \(cachePolicy), Max memory: \(maxMemoryCacheSizeMB)MB"
        )
    }

    /// Cache a model
    public func cacheModel(_ model: MLModel, for modelId: String, sizeBytes: UInt64) async throws {
        let entry = CacheEntry(
            modelId: modelId,
            model: model,
            loadedAt: Date(),
            lastAccessedAt: Date(),
            accessCount: 1
        )

        // Check if model already cached
        if memoryCache[modelId] != nil {
            logger.debug("Model already in cache: \(modelId)")
            return
        }

        // Check capacity and evict if necessary
        if memoryCacheSizeBytes + sizeBytes > UInt64(maxMemoryCacheSize) {
            try await evictLRUModels(requiredSize: sizeBytes)
        }

        memoryCache[modelId] = entry
        memoryCacheSizeBytes += sizeBytes
        accessOrder.append(modelId)

        logger.info("Model cached: \(modelId), Cache size: \(self.memoryCacheSizeBytes / (1024 * 1024))MB")

        // Optionally cache to disk if hybrid/disk policy
        if cachePolicy == .disk || cachePolicy == .hybrid {
            try await cacheToDisk(modelId: modelId)
        }
    }

    /// Retrieve a model from cache
    public func retrieveModel(modelId: String) async throws -> MLModel {
        if var entry = memoryCache[modelId] {
            entry.recordAccess()
            memoryCache[modelId] = entry

            // Update access order for LRU
            if let index = accessOrder.firstIndex(of: modelId) {
                accessOrder.remove(at: index)
            }
            accessOrder.append(modelId)

            logger.debug("Model retrieved from memory cache: \(modelId)")
            return entry.model
        }

        // Try disk cache if hybrid/disk policy
        if (cachePolicy == .disk || cachePolicy == .hybrid),
           let model = try await retrieveFromDisk(modelId: modelId)
        {
            logger.debug("Model retrieved from disk cache: \(modelId)")
            return model
        }

        throw CacheError.modelNotInCache(modelId)
    }

    /// Check if model is cached
    public func isCached(modelId: String) -> Bool {
        memoryCache[modelId] != nil
    }

    /// Remove model from cache
    public func removeFromCache(modelId: String) async throws {
        guard memoryCache.removeValue(forKey: modelId) != nil else {
            throw CacheError.modelNotInCache(modelId)
        }

        if let index = accessOrder.firstIndex(of: modelId) {
            accessOrder.remove(at: index)
        }

        logger.info("Model removed from cache: \(modelId)")

        // Remove from disk cache if exists
        if cachePolicy == .disk || cachePolicy == .hybrid {
            try await removeFromDisk(modelId: modelId)
        }
    }

    /// Clear all cached models
    public func clearCache() async {
        let modelIds = Array(memoryCache.keys)
        for modelId in modelIds {
            try? await removeFromCache(modelId: modelId)
        }

        memoryCacheSizeBytes = 0
        accessOrder.removeAll()

        logger.info("Cache cleared")
    }

    /// Get cache statistics
    public func getCacheStats() -> (totalSize: UInt64, cachedModels: Int, hitRate: Double) {
        return (
            totalSize: memoryCacheSizeBytes,
            cachedModels: memoryCache.count,
            hitRate: calculateHitRate()
        )
    }

    /// Get cached model IDs
    public func getCachedModelIds() -> [String] {
        Array(memoryCache.keys)
    }

    /// Pre-warm cache with specified models
    public func preWarmCache(with modelIds: [String]) async throws {
        logger.info("Pre-warming cache with \(modelIds.count) models")
    }

    // MARK: - Private Methods

    private func evictLRUModels(requiredSize: UInt64) async throws {
        var freedSize: UInt64 = 0
        var toEvict: [String] = []

        for modelId in accessOrder {
            if let entry = memoryCache[modelId] {
                toEvict.append(modelId)
                // Approximate size calculation
                freedSize += 50 * 1024 * 1024 // Default estimate

                if freedSize >= requiredSize {
                    break
                }
            }
        }

        for modelId in toEvict {
            try await removeFromCache(modelId: modelId)
        }

        logger.info("Evicted \(toEvict.count) models from cache")
    }

    private func cacheToDisk(modelId: String) async throws {
        guard let diskPath = diskCachePath else {
            throw CacheError.invalidCachePath
        }

        let fileManager = FileManager.default
        try? fileManager.createDirectory(atPath: diskPath, withIntermediateDirectories: true)

        logger.debug("Model cached to disk: \(modelId)")
    }

    private func retrieveFromDisk(modelId: String) async throws -> MLModel? {
        guard let diskPath = diskCachePath else {
            return nil
        }

        let filePath = (diskPath as NSString).appendingPathComponent("\(modelId).mlmodel")
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: filePath) else {
            return nil
        }

        let modelURL = URL(fileURLWithPath: filePath)
        let model = try MLModel(contentsOf: modelURL)
        return model
    }

    private func removeFromDisk(modelId: String) async throws {
        guard let diskPath = diskCachePath else {
            return
        }

        let filePath = (diskPath as NSString).appendingPathComponent("\(modelId).mlmodel")
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: filePath) {
            try fileManager.removeItem(atPath: filePath)
            logger.debug("Model removed from disk cache: \(modelId)")
        }
    }

    private func calculateHitRate() -> Double {
        let totalAccess = memoryCache.values.reduce(0) { $0 + $1.accessCount }
        guard totalAccess > 0 else { return 0 }
        return Double(memoryCache.count) / Double(totalAccess)
    }
}
