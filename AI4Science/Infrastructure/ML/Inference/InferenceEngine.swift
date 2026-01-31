import Foundation
import CoreML
import Vision
import os.log

/// Error types for inference
public enum InferenceError: LocalizedError {
    case modelNotLoaded(String)
    case invalidInput(String)
    case predictionFailed(String)
    case featureProviderCreationFailed(String)
    case unsupportedInputFormat(String)
    case outputProcessingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .modelNotLoaded(let id):
            return "Model not loaded: \(id)"
        case .invalidInput(let reason):
            return "Invalid input: \(reason)"
        case .predictionFailed(let reason):
            return "Prediction failed: \(reason)"
        case .featureProviderCreationFailed(let reason):
            return "Feature provider creation failed: \(reason)"
        case .unsupportedInputFormat(let format):
            return "Unsupported input format: \(format)"
        case .outputProcessingFailed(let reason):
            return "Output processing failed: \(reason)"
        }
    }
}

/// Inference metrics
public struct InferenceMetrics: Sendable {
    public let modelId: String
    public let inputSize: CGSize
    public let startTime: Date
    public let endTime: Date

    public var totalDurationMs: Double {
        endTime.timeIntervalSince(startTime) * 1000
    }

    public var inputPixelCount: Int {
        Int(inputSize.width * inputSize.height)
    }

    public var pixelsPerSecond: Double {
        guard totalDurationMs > 0 else { return 0 }
        return Double(inputPixelCount) / (totalDurationMs / 1000)
    }
}

/// Core inference actor using CoreML
public actor InferenceEngine {
    private let logger = Logger(subsystem: "com.ai4science.ml", category: "InferenceEngine")

    /// Model manager reference
    private let modelManager: MLModelManager

    /// Cache for loaded models
    private let modelCache: MLModelCache

    /// Inference queue for serialized operations
    private let inferenceQueue = DispatchQueue(
        label: "com.ai4science.ml.inference",
        qos: .userInitiated
    )

    /// Configuration for model execution
    private let modelConfiguration: MLModelConfiguration

    public nonisolated let modelId: String

    /// Initialize the inference engine
    public init(
        modelId: String,
        modelManager: MLModelManager,
        modelCache: MLModelCache
    ) {
        self.modelId = modelId
        self.modelManager = modelManager
        self.modelCache = modelCache

        let config = MLModelConfiguration()
        #if os(iOS)
        if #available(iOS 17.0, *) {
            config.computeUnits = .all
        } else {
            config.computeUnits = .cpuAndGPU
        }
        #endif
        self.modelConfiguration = config

        logger.info("InferenceEngine initialized for model: \(modelId)")
    }

    /// Run inference on a feature provider
    public func predict(
        featureProvider: MLFeatureProvider
    ) async throws -> MLFeatureProvider {
        let startTime = Date()

        do {
            // Get or load model
            let model = try await getModel()

            // Run prediction on inference queue
            let output = try await withCheckedThrowingContinuation { continuation in
                inferenceQueue.async { [weak self] in
                    do {
                        let prediction = try model.prediction(from: featureProvider)
                        continuation.resume(returning: prediction)
                    } catch {
                        continuation.resume(throwing: InferenceError.predictionFailed(error.localizedDescription))
                    }
                }
            }

            let endTime = Date()
            logMetrics(
                startTime: startTime,
                endTime: endTime,
                inputProvider: featureProvider
            )

            return output
        } catch {
            throw InferenceError.predictionFailed(error.localizedDescription)
        }
    }

    /// Run batch inference
    public func predictBatch(
        featureProviders: [MLFeatureProvider]
    ) async throws -> [MLFeatureProvider] {
        var results: [MLFeatureProvider] = []

        for provider in featureProviders {
            let result = try await predict(featureProvider: provider)
            results.append(result)
        }

        return results
    }

    /// Run inference with timeout
    public func predictWithTimeout(
        featureProvider: MLFeatureProvider,
        timeoutSeconds: TimeInterval = 30
    ) async throws -> MLFeatureProvider {
        try await withThrowingTaskGroup(of: MLFeatureProvider.self) { group in
            group.addTask {
                return try await self.predict(featureProvider: featureProvider)
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                throw InferenceError.predictionFailed("Inference timeout")
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    /// Get model information
    public func getModelDescription() async throws -> MLModelDescription {
        let model = try await getModel()
        return model.modelDescription
    }

    /// Get input feature descriptions
    public func getInputFeatures() async throws -> [String: MLFeatureDescription] {
        let model = try await getModel()
        return model.modelDescription.inputDescriptionsByName
    }

    /// Get output feature descriptions
    public func getOutputFeatures() async throws -> [String: MLFeatureDescription] {
        let model = try await getModel()
        return model.modelDescription.outputDescriptionsByName
    }

    // MARK: - Private Methods

    private func getModel() async throws -> MLModel {
        // Try to get from cache first
        if let cachedModel = try? await modelCache.retrieveModel(modelId: modelId) {
            return cachedModel
        }

        // Get from manager
        let model = try await modelManager.getModel(modelId: modelId)

        // Add to cache
        try? await modelCache.cacheModel(model, for: modelId, sizeBytes: 50 * 1024 * 1024)

        return model
    }

    private func logMetrics(
        startTime: Date,
        endTime: Date,
        inputProvider: MLFeatureProvider
    ) {
        let inputSize = extractInputSize(from: inputProvider)
        let metrics = InferenceMetrics(
            modelId: modelId,
            inputSize: inputSize,
            startTime: startTime,
            endTime: endTime
        )

        logger.debug(
            "Inference completed. Duration: \(String(format: "%.2f", metrics.totalDurationMs))ms, Pixels/sec: \(String(format: "%.0f", metrics.pixelsPerSecond))"
        )
    }

    private func extractInputSize(from featureProvider: MLFeatureProvider) -> CGSize {
        // Try to extract size from feature provider
        for (_, feature) in featureProvider.featureDictionary {
            if let imageFeature = feature as? MLFeatureValue {
                if let pixelBuffer = imageFeature.pixelBufferValue {
                    let width = CVPixelBufferGetWidth(pixelBuffer)
                    let height = CVPixelBufferGetHeight(pixelBuffer)
                    return CGSize(width: width, height: height)
                }
            }
        }
        return .zero
    }
}
