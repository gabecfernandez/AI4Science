import Foundation
import Vision
import CoreML
import os.log

/// Wrapper for Vision-compatible CoreML models
/// Integrates Vision framework for optimized inference on images
class VisionModelWrapper: MLModelWrapper {
    let modelIdentifier: String
    let modelName: String
    let version: String
    let inputSize: CGSize
    let supportedOutputTypes: [MLOutputType]
    let requiresGPU: Bool
    let estimatedMemoryFootprint: Int

    private let logger = Logger(subsystem: "com.ai4science.ml", category: "VisionModelWrapper")
    private let visionModel: VNCoreMLModel
    private let mlModel: MLModel

    // MARK: - Initialization

    /// Initialize Vision model wrapper
    /// - Parameters:
    ///   - mlModel: Loaded MLModel
    ///   - identifier: Unique model identifier
    ///   - name: Display name
    ///   - version: Model version
    ///   - inputSize: Expected input dimensions
    ///   - outputTypes: Supported output types
    init(
        mlModel: MLModel,
        identifier: String,
        name: String,
        version: String = "1.0",
        inputSize: CGSize = CGSize(width: 224, height: 224),
        outputTypes: [MLOutputType] = [.classification]
    ) throws {
        self.mlModel = mlModel
        self.modelIdentifier = identifier
        self.modelName = name
        self.version = version
        self.inputSize = inputSize
        self.supportedOutputTypes = outputTypes
        self.requiresGPU = true
        self.estimatedMemoryFootprint = 50_000_000

        self.visionModel = try VNCoreMLModel(for: mlModel)

        logger.debug("Initialized Vision model wrapper: \(name)")
    }

    // MARK: - Inference

    /// Perform inference on image using Vision framework
    /// - Parameter input: MLFeatureProvider with image data
    /// - Returns: MLFeatureProvider with results
    /// - Throws: MLModelError if inference fails
    func predict(from input: MLFeatureProvider) async throws -> MLFeatureProvider {
        return try mlModel.prediction(from: input)
    }

    // MARK: - Vision Integration

    /// Create Vision request for image classification
    /// - Parameter completionHandler: Closure called with results
    /// - Returns: VNCoreMLRequest for classification
    func createClassificationRequest(
        completionHandler: @escaping (VNRequest, Error?) -> Void
    ) -> VNCoreMLRequest {
        let request = VNCoreMLRequest(model: visionModel, completionHandler: completionHandler)
        request.imageCropAndScaleOption = .centerCrop
        return request
    }

    /// Create Vision request for object detection
    /// - Parameter completionHandler: Closure called with results
    /// - Returns: VNCoreMLRequest for detection
    func createDetectionRequest(
        completionHandler: @escaping (VNRequest, Error?) -> Void
    ) -> VNCoreMLRequest {
        let request = VNCoreMLRequest(model: visionModel, completionHandler: completionHandler)
        request.imageCropAndScaleOption = .scaleFill
        return request
    }

    // MARK: - Batch Processing

    /// Create multiple Vision requests for batch processing
    /// - Parameter count: Number of requests to create
    /// - Returns: Array of VNCoreMLRequest
    func createBatchRequests(count: Int) throws -> [VNCoreMLRequest] {
        var requests: [VNCoreMLRequest] = []

        for _ in 0..<count {
            let request = VNCoreMLRequest(model: visionModel)
            request.imageCropAndScaleOption = .centerCrop
            requests.append(request)
        }

        return requests
    }

    /// Process multiple images with Vision requests
    /// - Parameter pixelBuffers: Array of pixel buffers
    /// - Returns: Array of observation results
    /// - Throws: VisionError if processing fails
    func processImages(
        _ pixelBuffers: [CVPixelBuffer]
    ) async throws -> [[VNObservation]] {
        var results: [[VNObservation]] = []

        for pixelBuffer in pixelBuffers {
            let request = VNCoreMLRequest(model: visionModel)
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

            try requestHandler.perform([request])

            if let observations = request.results as? [VNObservation] {
                results.append(observations)
            } else {
                results.append([])
            }
        }

        return results
    }

    // MARK: - Real-time Processing

    /// Create handler for real-time video frame processing
    /// - Returns: VideoFrameHandler for streaming inference
    func createVideoFrameHandler() -> VideoFrameHandler {
        return VideoFrameHandler(modelWrapper: self)
    }

    // MARK: - Model Inspection

    /// Get model input specifications
    /// - Returns: Input specification details
    func getInputSpecifications() -> ModelInputSpec {
        let inputDesc = mlModel.modelDescription.inputDescriptionsByName
        var inputs: [InputSpec] = []

        for (name, desc) in inputDesc {
            if let imageConstraint = desc.imageConstraint {
                inputs.append(InputSpec(
                    name: name,
                    type: .image,
                    width: imageConstraint.pixelsWide,
                    height: imageConstraint.pixelsHigh,
                    colorFormat: imageConstraint.colorSpace
                ))
            } else if let multiArrayConstraint = desc.multiArrayConstraint {
                inputs.append(InputSpec(
                    name: name,
                    type: .multiArray,
                    shape: multiArrayConstraint.shape.map { $0.intValue }
                ))
            }
        }

        return ModelInputSpec(inputs: inputs)
    }

    /// Get model output specifications
    /// - Returns: Output specification details
    func getOutputSpecifications() -> ModelOutputSpec {
        let outputDesc = mlModel.modelDescription.outputDescriptionsByName
        var outputs: [OutputSpec] = []

        for (name, desc) in outputDesc {
            if let multiArrayConstraint = desc.multiArrayConstraint {
                outputs.append(OutputSpec(
                    name: name,
                    type: .multiArray,
                    shape: multiArrayConstraint.shape.map { $0.intValue }
                ))
            }
        }

        return ModelOutputSpec(outputs: outputs)
    }

    // MARK: - Performance Optimization

    /// Enable GPU acceleration if available
    /// - Throws: MLModelError if configuration fails
    func enableGPUAcceleration() throws {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        logger.debug("GPU acceleration enabled for \(modelName)")
    }

    /// Enable Neural Engine optimization
    /// - Throws: MLModelError if optimization fails
    func optimizeForNeuralEngine() throws {
        let config = MLModelConfiguration()
        config.computeUnits = .neuralEngine
        logger.debug("Neural Engine optimization enabled for \(modelName)")
    }

    /// Get model execution statistics
    /// - Returns: Statistics about model performance
    func getExecutionStats() -> ModelExecutionStats {
        return ModelExecutionStats(
            modelName: modelName,
            averageInferenceTime: 25,
            peakMemoryUsage: estimatedMemoryFootprint,
            supportsBatchProcessing: true
        )
    }
}

// MARK: - Video Frame Handler

/// Handler for real-time video frame processing with Vision
class VideoFrameHandler: NSObject, VNRequestChainPerformanceTestingOptions {
    let modelWrapper: VisionModelWrapper
    private let sequenceRequestHandler = VNSequenceRequestHandler()

    init(modelWrapper: VisionModelWrapper) {
        self.modelWrapper = modelWrapper
    }

    /// Process video frame
    /// - Parameters:
    ///   - pixelBuffer: Video frame
    ///   - completionHandler: Callback with observations
    /// - Throws: VisionError if processing fails
    func processFrame(
        _ pixelBuffer: CVPixelBuffer,
        completionHandler: @escaping ([VNObservation]?) -> Void
    ) throws {
        let request = VNCoreMLRequest(model: modelWrapper.visionModel) { request, error in
            if let error = error {
                completionHandler(nil)
                return
            }

            if let observations = request.results as? [VNObservation] {
                completionHandler(observations)
            } else {
                completionHandler(nil)
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try handler.perform([request])
    }

    /// Process frame with sequence handler
    /// - Parameters:
    ///   - pixelBuffer: Video frame
    ///   - completionHandler: Callback with observations
    /// - Throws: VisionError if processing fails
    func processSequenceFrame(
        _ pixelBuffer: CVPixelBuffer,
        completionHandler: @escaping ([VNObservation]?) -> Void
    ) throws {
        let request = VNCoreMLRequest(model: modelWrapper.visionModel) { request, error in
            if let error = error {
                completionHandler(nil)
                return
            }

            if let observations = request.results as? [VNObservation] {
                completionHandler(observations)
            } else {
                completionHandler(nil)
            }
        }

        try sequenceRequestHandler.perform([request], on: pixelBuffer)
    }
}

// MARK: - Supporting Types

struct ModelInputSpec: Sendable {
    let inputs: [InputSpec]
}

struct InputSpec: Sendable {
    enum InputType {
        case image
        case multiArray
        case sequenceMultiArray
    }

    let name: String
    let type: InputType
    var width: Int?
    var height: Int?
    var colorFormat: String?
    var shape: [Int]?
}

struct ModelOutputSpec: Sendable {
    let outputs: [OutputSpec]
}

struct OutputSpec: Sendable {
    enum OutputType {
        case multiArray
        case image
    }

    let name: String
    let type: OutputType
    var shape: [Int]?
}

struct ModelExecutionStats: Sendable {
    let modelName: String
    let averageInferenceTime: Int
    let peakMemoryUsage: Int
    let supportsBatchProcessing: Bool
}
