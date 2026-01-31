import Foundation
import CoreML
import os.log

/// ML compute unit preferences and configuration
/// Manages Neural Engine, GPU, and CPU usage
struct MLConfiguration: Sendable, Codable {
    /// Preferred compute unit for inference
    let computeUnit: ComputeUnit

    /// Whether to allow fallback to CPU
    let allowCPUFallback: Bool

    /// Maximum concurrent inference operations
    let maxConcurrentOperations: Int

    /// Cache inference results
    let cacheResults: Bool

    /// Maximum cache size in bytes
    let maxCacheSize: Int

    /// Batch processing configuration
    let batchConfig: BatchConfig

    /// Memory optimization settings
    let memoryConfig: MemoryConfig

    /// Performance monitoring settings
    let performanceConfig: PerformanceConfig

    // MARK: - Compute Units

    enum ComputeUnit: String, Codable, Sendable {
        case neuralEngine = "NeuralEngine"
        case gpu = "GPU"
        case cpu = "CPU"
        case all = "All"

        var mlComputeUnit: MLComputeUnit {
            switch self {
            case .neuralEngine:
                return .neuralEngine
            case .gpu:
                return .gpuOnly
            case .cpu:
                return .cpuOnly
            case .all:
                return .all
            }
        }

        var description: String {
            switch self {
            case .neuralEngine:
                return "Neural Engine"
            case .gpu:
                return "GPU"
            case .cpu:
                return "CPU"
            case .all:
                return "All Available"
            }
        }
    }

    // MARK: - Initialization

    init(
        computeUnit: ComputeUnit = .all,
        allowCPUFallback: Bool = true,
        maxConcurrentOperations: Int = 4,
        cacheResults: Bool = true,
        maxCacheSize: Int = 500_000_000,
        batchConfig: BatchConfig = .default,
        memoryConfig: MemoryConfig = .default,
        performanceConfig: PerformanceConfig = .default
    ) {
        self.computeUnit = computeUnit
        self.allowCPUFallback = allowCPUFallback
        self.maxConcurrentOperations = maxConcurrentOperations
        self.cacheResults = cacheResults
        self.maxCacheSize = maxCacheSize
        self.batchConfig = batchConfig
        self.memoryConfig = memoryConfig
        self.performanceConfig = performanceConfig
    }

    // MARK: - Preset Configurations

    static let performance = MLConfiguration(
        computeUnit: .neuralEngine,
        allowCPUFallback: true,
        maxConcurrentOperations: 8,
        cacheResults: false,
        memoryConfig: .init(
            enableMemoryMapping: false,
            maxMemoryUsage: 300_000_000
        )
    )

    static let balanced = MLConfiguration(
        computeUnit: .all,
        allowCPUFallback: true,
        maxConcurrentOperations: 4,
        cacheResults: true
    )

    static let efficiency = MLConfiguration(
        computeUnit: .cpu,
        allowCPUFallback: false,
        maxConcurrentOperations: 2,
        cacheResults: true,
        maxCacheSize: 100_000_000,
        memoryConfig: .init(
            enableMemoryMapping: true,
            maxMemoryUsage: 100_000_000
        )
    )

    // MARK: - Configuration Building

    static func builder() -> MLConfigurationBuilder {
        return MLConfigurationBuilder()
    }
}

// MARK: - Batch Configuration

struct BatchConfig: Sendable, Codable {
    /// Enable batch processing
    let enabled: Bool

    /// Preferred batch size
    let preferredSize: Int

    /// Maximum batch size
    let maxSize: Int

    /// Timeout for batch accumulation in milliseconds
    let batchTimeoutMs: Int

    static let `default` = BatchConfig(
        enabled: true,
        preferredSize: 4,
        maxSize: 16,
        batchTimeoutMs: 100
    )

    init(
        enabled: Bool = true,
        preferredSize: Int = 4,
        maxSize: Int = 16,
        batchTimeoutMs: Int = 100
    ) {
        self.enabled = enabled
        self.preferredSize = preferredSize
        self.maxSize = maxSize
        self.batchTimeoutMs = batchTimeoutMs
    }
}

// MARK: - Memory Configuration

struct MemoryConfig: Sendable, Codable {
    /// Enable memory mapping for large models
    let enableMemoryMapping: Bool

    /// Maximum memory to use for inference in bytes
    let maxMemoryUsage: Int

    /// Enable memory compression
    let enableCompression: Bool

    /// Clear cache when memory pressure detected
    let autoClearCache: Bool

    static let `default` = MemoryConfig(
        enableMemoryMapping: false,
        maxMemoryUsage: 500_000_000,
        enableCompression: false,
        autoClearCache: true
    )

    init(
        enableMemoryMapping: Bool = false,
        maxMemoryUsage: Int = 500_000_000,
        enableCompression: Bool = false,
        autoClearCache: Bool = true
    ) {
        self.enableMemoryMapping = enableMemoryMapping
        self.maxMemoryUsage = maxMemoryUsage
        self.enableCompression = enableCompression
        self.autoClearCache = autoClearCache
    }
}

// MARK: - Performance Configuration

struct PerformanceConfig: Sendable, Codable {
    /// Enable performance monitoring
    let enableMonitoring: Bool

    /// Maximum inference time allowed in milliseconds
    let maxInferenceTimeMs: Int

    /// Enable low precision accumulation on GPU
    let lowPrecisionAccumulation: Bool

    /// Enable warm-up runs
    let enableWarmup: Bool

    /// Number of warm-up iterations
    let warmupIterations: Int

    static let `default` = PerformanceConfig(
        enableMonitoring: true,
        maxInferenceTimeMs: 5000,
        lowPrecisionAccumulation: true,
        enableWarmup: true,
        warmupIterations: 3
    )

    init(
        enableMonitoring: Bool = true,
        maxInferenceTimeMs: Int = 5000,
        lowPrecisionAccumulation: Bool = true,
        enableWarmup: Bool = true,
        warmupIterations: Int = 3
    ) {
        self.enableMonitoring = enableMonitoring
        self.maxInferenceTimeMs = maxInferenceTimeMs
        self.lowPrecisionAccumulation = lowPrecisionAccumulation
        self.enableWarmup = enableWarmup
        self.warmupIterations = warmupIterations
    }
}

// MARK: - Configuration Builder

struct MLConfigurationBuilder {
    private var computeUnit: MLConfiguration.ComputeUnit = .all
    private var allowCPUFallback: Bool = true
    private var maxConcurrentOperations: Int = 4
    private var cacheResults: Bool = true
    private var maxCacheSize: Int = 500_000_000
    private var batchConfig: BatchConfig = .default
    private var memoryConfig: MemoryConfig = .default
    private var performanceConfig: PerformanceConfig = .default

    mutating func computeUnit(_ unit: MLConfiguration.ComputeUnit) -> Self {
        self.computeUnit = unit
        return self
    }

    mutating func allowCPUFallback(_ allow: Bool) -> Self {
        self.allowCPUFallback = allow
        return self
    }

    mutating func maxConcurrentOperations(_ max: Int) -> Self {
        self.maxConcurrentOperations = max
        return self
    }

    mutating func cacheResults(_ cache: Bool) -> Self {
        self.cacheResults = cache
        return self
    }

    mutating func maxCacheSize(_ size: Int) -> Self {
        self.maxCacheSize = size
        return self
    }

    mutating func batchConfig(_ config: BatchConfig) -> Self {
        self.batchConfig = config
        return self
    }

    mutating func memoryConfig(_ config: MemoryConfig) -> Self {
        self.memoryConfig = config
        return self
    }

    mutating func performanceConfig(_ config: PerformanceConfig) -> Self {
        self.performanceConfig = config
        return self
    }

    func build() -> MLConfiguration {
        return MLConfiguration(
            computeUnit: computeUnit,
            allowCPUFallback: allowCPUFallback,
            maxConcurrentOperations: maxConcurrentOperations,
            cacheResults: cacheResults,
            maxCacheSize: maxCacheSize,
            batchConfig: batchConfig,
            memoryConfig: memoryConfig,
            performanceConfig: performanceConfig
        )
    }
}

// MARK: - Device Capability Detection

struct DeviceCapabilities: Sendable {
    private static let logger = Logger(subsystem: "com.ai4science.ml", category: "DeviceCapabilities")

    /// Check if device supports Neural Engine
    static var supportsNeuralEngine: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        // Neural Engine available on A12 Bionic and later
        // Check device model to determine
        return deviceModelSupportsMachineLearning()
        #endif
    }

    /// Check if device supports GPU acceleration
    static var supportsGPU: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return true
        #endif
    }

    /// Get recommended compute unit for device
    static var recommendedComputeUnit: MLConfiguration.ComputeUnit {
        if supportsNeuralEngine {
            return .neuralEngine
        } else if supportsGPU {
            return .gpu
        } else {
            return .cpu
        }
    }

    /// Get optimal ML configuration for device
    static var optimalConfiguration: MLConfiguration {
        if supportsNeuralEngine {
            return .performance
        } else {
            return .balanced
        }
    }

    // MARK: - Private Helpers

    private static func deviceModelSupportsMachineLearning() -> Bool {
        #if os(iOS)
        let processInfo = ProcessInfo.processInfo
        let osVersion = processInfo.operatingSystemVersion

        // iOS 12+ supports Neural Engine on A12 Bionic
        return osVersion.majorVersion >= 12
        #else
        return false
        #endif
    }
}
