import UIKit
import os.log

/// LRU cache service for media thumbnails and processed images
actor MediaCacheService {
    static let shared = MediaCacheService()

    private let logger = Logger(subsystem: "com.ai4science.media", category: "MediaCacheService")

    private var cache: [String: CacheEntry] = [:]
    private let maxCacheSize: Int
    private let maxMemoryUsage: Int64

    private var currentMemoryUsage: Int64 = 0
    private let queue = DispatchQueue(label: "com.ai4science.media.cache", attributes: .concurrent)

    enum CacheError: LocalizedError {
        case itemNotFound
        case cacheFull

        var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "Item not found in cache"
            case .cacheFull:
                return "Cache is full"
            }
        }
    }

    private struct CacheEntry {
        let key: String
        let data: UIImage
        let size: Int64
        var lastAccessDate: Date
        let createdDate: Date
    }

    init(maxCacheSize: Int = 100, maxMemoryUsage: Int64 = 500 * 1024 * 1024) { // 500MB
        self.maxCacheSize = maxCacheSize
        self.maxMemoryUsage = maxMemoryUsage

        logger.info("MediaCacheService initialized with max \(maxCacheSize) items, \(maxMemoryUsage) bytes")
    }

    /// Store image in cache
    func cacheImage(_ image: UIImage, for key: String) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            logger.warning("Failed to convert image to data")
            return
        }

        let size = Int64(data.count)

        let entry = CacheEntry(
            key: key,
            data: image,
            size: size,
            lastAccessDate: Date(),
            createdDate: Date()
        )

        // Check if we need to evict
        if currentMemoryUsage + size > maxMemoryUsage || cache.count >= maxCacheSize {
            evictLRUItems(neededSpace: size)
        }

        cache[key] = entry
        currentMemoryUsage += size

        logger.debug("Image cached with key: \(key), size: \(size) bytes")
    }

    /// Retrieve image from cache
    func getCachedImage(for key: String) async -> UIImage? {
        guard var entry = cache[key] else {
            return nil
        }

        // Update access date
        entry.lastAccessDate = Date()
        cache[key] = entry

        logger.debug("Image retrieved from cache: \(key)")
        return entry.data
    }

    /// Remove image from cache
    func removeImage(for key: String) async {
        guard let entry = cache.removeValue(forKey: key) else {
            logger.debug("Image not found in cache: \(key)")
            return
        }

        currentMemoryUsage -= entry.size
        logger.debug("Image removed from cache: \(key)")
    }

    /// Clear entire cache
    func clearCache() async {
        cache.removeAll()
        currentMemoryUsage = 0
        logger.info("Cache cleared")
    }

    /// Get cache statistics
    func getCacheStatistics() async -> CacheStatistics {
        let itemCount = cache.count
        let largestItem = cache.values.max { $0.size < $1.size }
        let averageSize = itemCount > 0 ? currentMemoryUsage / Int64(itemCount) : 0

        return CacheStatistics(
            itemCount: itemCount,
            totalSize: currentMemoryUsage,
            maxSize: maxMemoryUsage,
            maxItems: maxCacheSize,
            largestItemSize: largestItem?.size ?? 0,
            averageItemSize: averageSize
        )
    }

    /// Check if item exists in cache
    func isCached(key: String) -> Bool {
        return cache[key] != nil
    }

    /// Prefetch multiple images
    func prefetchImages(_ images: [UIImage], with keys: [String]) async {
        guard images.count == keys.count else {
            logger.warning("Image and key counts don't match")
            return
        }

        for (image, key) in zip(images, keys) {
            await cacheImage(image, for: key)
        }

        logger.info("Prefetched \(images.count) images")
    }

    /// Get all cached keys
    func getAllCachedKeys() async -> [String] {
        return Array(cache.keys)
    }

    /// Get cache hit rate
    func getCacheHitRate() async -> Double {
        // This would require tracking hits and misses
        // For now, return estimated rate based on cache utilization
        let utilizationRate = Double(cache.count) / Double(maxCacheSize)
        return utilizationRate
    }

    // MARK: - Private Methods

    private func evictLRUItems(neededSpace: Int64) {
        var sortedByAccess = cache.values.sorted { $0.lastAccessDate < $1.lastAccessDate }

        var freedSpace: Int64 = 0

        for entry in sortedByAccess {
            guard freedSpace < neededSpace else {
                break
            }

            if let removedEntry = cache.removeValue(forKey: entry.key) {
                freedSpace += removedEntry.size
                currentMemoryUsage -= removedEntry.size
                logger.debug("Evicted cache entry: \(entry.key)")
            }
        }
    }

    private func trimIfNeeded() {
        if currentMemoryUsage > maxMemoryUsage {
            let targetSize = maxMemoryUsage / 2  // Reduce to 50% of max
            let neededReduction = currentMemoryUsage - targetSize

            evictLRUItems(neededSpace: neededReduction)
        }
    }
}

struct CacheStatistics {
    let itemCount: Int
    let totalSize: Int64
    let maxSize: Int64
    let maxItems: Int
    let largestItemSize: Int64
    let averageItemSize: Int64

    var percentageUsed: Double {
        Double(totalSize) / Double(maxSize) * 100
    }

    var totalSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }

    var maxSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: maxSize)
    }

    var averageSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: averageItemSize)
    }
}
