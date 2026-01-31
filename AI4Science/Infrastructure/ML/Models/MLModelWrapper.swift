import Foundation
import CoreML
import Vision

/// Protocol for wrapping different CoreML model types
/// Provides unified interface for various ML models
protocol MLModelWrapper: Sendable {
    /// Unique identifier for the model
    var modelIdentifier: String { get }

    /// Human-readable model name
    var modelName: String { get }

    /// Model version
    var version: String { get }

    /// Input size requirement
    var inputSize: CGSize { get }

    /// Array of supported output types
    var supportedOutputTypes: [MLOutputType] { get }

    /// Whether model requires GPU acceleration
    var requiresGPU: Bool { get }

    /// Estimated memory footprint in bytes
    var estimatedMemoryFootprint: Int { get }

    /// Perform inference on input
    /// - Parameter input: MLFeatureProvider containing model input
    /// - Returns: MLFeatureProvider with model output
    /// - Throws: MLModelError if inference fails
    func predict(from input: MLFeatureProvider) async throws -> MLFeatureProvider
}

/// Supported ML model output types
enum MLOutputType: String, Sendable, Codable, CaseIterable {
    case classification
    case objectDetection
    case semanticSegmentation
    case instanceSegmentation
    case poseEstimation
    case depthEstimation
    case customOutput

    var description: String {
        switch self {
        case .classification:
            return "Image Classification"
        case .objectDetection:
            return "Object Detection"
        case .semanticSegmentation:
            return "Semantic Segmentation"
        case .instanceSegmentation:
            return "Instance Segmentation"
        case .poseEstimation:
            return "Pose Estimation"
        case .depthEstimation:
            return "Depth Estimation"
        case .customOutput:
            return "Custom Output"
        }
    }
}

/// Model inference configuration
struct ModelInferenceConfig: Sendable {
    /// Maximum inference time in milliseconds
    let maxInferenceTime: Int = 5000

    /// Whether to use GPU if available
    let useGPU: Bool = true

    /// Whether to use Neural Engine if available
    let useNeuralEngine: Bool = true

    /// Whether to cache results
    let cacheResults: Bool = false

    /// Batch size for inference
    let batchSize: Int = 1
}

/// Model information and metadata
struct ModelMetadata: Sendable, Codable {
    let identifier: String
    let name: String
    let version: String
    let description: String?
    let author: String?
    let createdDate: Date?
    let lastUpdatedDate: Date?
    let requiredIOSVersion: String
    let estimatedSize: Int
    let supportedDevices: [ModelDevice]
    let performance: ModelPerformanceInfo?
    let documentation: String?

    enum ModelDevice: String, Codable, CaseIterable {
        case iPhone
        case iPad
        case simulator
    }
}

/// Model performance characteristics
struct ModelPerformanceInfo: Sendable, Codable {
    /// Average inference time in milliseconds
    let averageInferenceTime: Int

    /// Memory used during inference in bytes
    let peakMemoryUsage: Int

    /// Model accuracy percentage
    let accuracy: Float?

    /// Precision of model
    let precision: ModelPrecision

    enum ModelPrecision: String, Codable {
        case float32
        case float16
        case int8
        case mixed
    }
}

/// Base implementation for ML model wrappers
class BaseMLModelWrapper: MLModelWrapper {
    let modelIdentifier: String
    let modelName: String
    let version: String
    let inputSize: CGSize
    let supportedOutputTypes: [MLOutputType]
    let requiresGPU: Bool
    let estimatedMemoryFootprint: Int

    private let mlModel: MLModel
    private let config: MLModelConfiguration

    init(
        modelIdentifier: String,
        modelName: String,
        version: String,
        inputSize: CGSize,
        supportedOutputTypes: [MLOutputType],
        requiresGPU: Bool = false,
        estimatedMemoryFootprint: Int = 50_000_000,
        mlModel: MLModel,
        config: MLModelConfiguration
    ) {
        self.modelIdentifier = modelIdentifier
        self.modelName = modelName
        self.version = version
        self.inputSize = inputSize
        self.supportedOutputTypes = supportedOutputTypes
        self.requiresGPU = requiresGPU
        self.estimatedMemoryFootprint = estimatedMemoryFootprint
        self.mlModel = mlModel
        self.config = config
    }

    func predict(from input: MLFeatureProvider) async throws -> MLFeatureProvider {
        return try mlModel.prediction(from: input)
    }
}

/// Factory for creating model wrappers
struct MLModelWrapperFactory {
    /// Create wrapper for a loaded model
    /// - Parameters:
    ///   - model: Loaded MLModel
    ///   - metadata: Model metadata
    /// - Returns: MLModelWrapper instance
    static func createWrapper(
        for model: MLModel,
        metadata: ModelMetadata
    ) -> MLModelWrapper {
        let config = MLModelConfiguration()
        config.computeUnits = .all

        return BaseMLModelWrapper(
            modelIdentifier: metadata.identifier,
            modelName: metadata.name,
            version: metadata.version,
            inputSize: CGSize(width: 224, height: 224), // Default, should be detected
            supportedOutputTypes: [], // Should be determined from model
            requiresGPU: metadata.supportedDevices.contains(.iPhone),
            estimatedMemoryFootprint: metadata.estimatedSize,
            mlModel: model,
            config: config
        )
    }

    /// Create wrapper from model bundle
    /// - Parameters:
    ///   - modelName: Name of model in bundle
    ///   - modelManager: MLModelManager for loading
    /// - Returns: MLModelWrapper instance
    /// - Throws: MLModelError if creation fails
    static func createWrapper(
        modelName: String,
        modelManager: MLModelManager
    ) async throws -> MLModelWrapper {
        let model = try await modelManager.loadModel(named: modelName)

        let config = MLModelConfiguration()
        config.computeUnits = .all

        // Extract input size from model
        var inputSize = CGSize(width: 224, height: 224)
        if let imageConstraint = model.modelDescription.inputDescriptionsByName.values.first?.imageConstraint {
            inputSize = CGSize(width: imageConstraint.pixelsWide, height: imageConstraint.pixelsHigh)
        }

        // Determine output types from model outputs
        var outputTypes: [MLOutputType] = []
        if model.modelDescription.outputDescriptionsByName.keys.contains(where: { $0.contains("class") }) {
            outputTypes.append(.classification)
        }
        if model.modelDescription.outputDescriptionsByName.keys.contains(where: { $0.contains("box") }) {
            outputTypes.append(.objectDetection)
        }

        return BaseMLModelWrapper(
            modelIdentifier: modelName,
            modelName: modelName,
            version: "1.0",
            inputSize: inputSize,
            supportedOutputTypes: outputTypes,
            estimatedMemoryFootprint: 50_000_000,
            mlModel: model,
            config: config
        )
    }
}
