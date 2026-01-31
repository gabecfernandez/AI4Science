import Foundation
import CoreML
import Vision
import os.log

/// Detection box structure
public struct DetectionBox: Sendable {
    public let x: Float
    public let y: Float
    public let width: Float
    public let height: Float
    public let confidence: Float
    public let classId: Int
    public let classLabel: String

    public var rect: CGRect {
        CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height))
    }

    public init(
        x: Float,
        y: Float,
        width: Float,
        height: Float,
        confidence: Float,
        classId: Int,
        classLabel: String
    ) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.confidence = confidence
        self.classId = classId
        self.classLabel = classLabel
    }

    /// Calculate IoU (Intersection over Union) with another box
    public func calculateIoU(with other: DetectionBox) -> Float {
        let intersectionX = max(x, other.x)
        let intersectionY = max(y, other.y)
        let intersectionWidth = max(0, min(x + width, other.x + other.width) - intersectionX)
        let intersectionHeight = max(0, min(y + height, other.y + other.height) - intersectionY)

        let intersectionArea = intersectionWidth * intersectionHeight
        let boxArea = width * height
        let otherArea = other.width * other.height
        let unionArea = boxArea + otherArea - intersectionArea

        guard unionArea > 0 else { return 0 }
        return intersectionArea / unionArea
    }
}

/// Object detection result
public struct ObjectDetectionResult: InferenceResultProtocol, Sendable {
    public let resultId: UUID
    public let timestamp: Date
    public let inferenceTimeMs: Double
    public let modelIdentifier: String
    public let inputImageSize: CGSize
    public let confidence: Float
    public let isValid: Bool
    public let errorMessage: String?

    public let detectionBoxes: [DetectionBox]
    public let detectionCount: Int
    public let nmsApplied: Bool

    public init(
        detectionBoxes: [DetectionBox],
        inferenceTimeMs: Double,
        modelIdentifier: String,
        inputImageSize: CGSize,
        nmsApplied: Bool = false,
        confidence: Float,
        isValid: Bool = true,
        errorMessage: String? = nil
    ) {
        self.resultId = UUID()
        self.timestamp = Date()
        self.detectionBoxes = detectionBoxes
        self.detectionCount = detectionBoxes.count
        self.inferenceTimeMs = inferenceTimeMs
        self.modelIdentifier = modelIdentifier
        self.inputImageSize = inputImageSize
        self.nmsApplied = nmsApplied
        self.confidence = confidence
        self.isValid = isValid
        self.errorMessage = errorMessage
    }
}

/// Object detection inference actor
public actor ObjectDetectionInference {
    private let logger = Logger(subsystem: "com.ai4science.ml", category: "ObjectDetectionInference")

    /// Inference engine
    private let inferenceEngine: InferenceEngine

    /// Image preprocessor
    private let preprocessor: ImagePreprocessor

    /// Confidence threshold
    private let confidenceThreshold: Float

    /// Non-Maximum Suppression IOU threshold
    private let nmsIOUThreshold: Float

    /// Class labels mapping
    private let classLabels: [Int: String]

    public init(
        inferenceEngine: InferenceEngine,
        preprocessor: ImagePreprocessor,
        confidenceThreshold: Float = 0.5,
        nmsIOUThreshold: Float = 0.5,
        classLabels: [Int: String] = [
            0: "defect",
            1: "scratch",
            2: "crack"
        ]
    ) {
        self.inferenceEngine = inferenceEngine
        self.preprocessor = preprocessor
        self.confidenceThreshold = confidenceThreshold
        self.nmsIOUThreshold = nmsIOUThreshold
        self.classLabels = classLabels

        logger.info("ObjectDetectionInference initialized")
    }

    /// Detect objects in image
    public func detectObjects(_ image: UIImage) async throws -> ObjectDetectionResult {
        let startTime = Date()

        do {
            // Preprocess image
            let featureProvider = try await preprocessor.preprocess(image)

            // Run inference
            let outputProvider = try await inferenceEngine.predict(featureProvider: featureProvider)

            // Process output
            let result = try processOutput(
                outputProvider: outputProvider,
                imageSize: image.size,
                startTime: startTime,
                inputImageSize: preprocessor.targetImageSize
            )

            logger.info(
                "Object detection completed: \(result.detectionCount) objects detected"
            )

            return result
        } catch {
            logger.error("Object detection failed: \(error.localizedDescription)")
            return createErrorResult(
                image: image,
                error: error,
                startTime: startTime
            )
        }
    }

    /// Detect objects in multiple images
    public func detectObjectsInImages(_ images: [UIImage]) async throws -> [ObjectDetectionResult] {
        var results: [ObjectDetectionResult] = []

        for image in images {
            let result = try await detectObjects(image)
            results.append(result)
        }

        return results
    }

    // MARK: - Private Methods

    private func processOutput(
        outputProvider: MLFeatureProvider,
        imageSize: CGSize,
        startTime: Date,
        inputImageSize: CGSize
    ) throws -> ObjectDetectionResult {
        let endTime = Date()
        let inferenceTimeMs = endTime.timeIntervalSince(startTime) * 1000

        var detectionBoxes: [DetectionBox] = []

        // Extract bounding boxes from output
        // This assumes YOLO-style output with shape [1, num_detections, 6]
        // where each detection has [x, y, width, height, confidence, classId]

        if let boxesOutput = outputProvider.featureDictionary["boxes"],
           let boxesArray = boxesOutput.multiArrayValue
        {
            detectionBoxes = try extractDetectionBoxes(
                from: boxesArray,
                imageSize: imageSize,
                inputImageSize: inputImageSize
            )
        }

        // Apply NMS (Non-Maximum Suppression)
        let nmsBoxes = applyNMS(to: detectionBoxes, iouThreshold: nmsIOUThreshold)

        // Filter by confidence threshold
        let filteredBoxes = nmsBoxes.filter { $0.confidence >= confidenceThreshold }

        let avgConfidence = !filteredBoxes.isEmpty
            ? filteredBoxes.map { $0.confidence }.reduce(0, +) / Float(filteredBoxes.count)
            : 0

        return ObjectDetectionResult(
            detectionBoxes: filteredBoxes,
            inferenceTimeMs: inferenceTimeMs,
            modelIdentifier: inferenceEngine.modelId,
            inputImageSize: imageSize,
            nmsApplied: true,
            confidence: avgConfidence,
            isValid: !filteredBoxes.isEmpty
        )
    }

    private func extractDetectionBoxes(
        from boxesArray: MLMultiArray,
        imageSize: CGSize,
        inputImageSize: CGSize
    ) throws -> [DetectionBox] {
        var boxes: [DetectionBox] = []

        let strides = boxesArray.strides
        let shape = boxesArray.shape

        // Iterate through detections
        if shape.count >= 2 {
            let numDetections = Int(shape[1])

            for i in 0..<numDetections {
                let x = Float(truncating: boxesArray[[0, i, 0]])
                let y = Float(truncating: boxesArray[[0, i, 1]])
                let width = Float(truncating: boxesArray[[0, i, 2]])
                let height = Float(truncating: boxesArray[[0, i, 3]])
                let confidence = Float(truncating: boxesArray[[0, i, 4]])
                let classId = Int(truncating: boxesArray[[0, i, 5]])

                // Scale boxes to original image size
                let scaleX = Float(imageSize.width / inputImageSize.width)
                let scaleY = Float(imageSize.height / inputImageSize.height)

                let box = DetectionBox(
                    x: x * scaleX,
                    y: y * scaleY,
                    width: width * scaleX,
                    height: height * scaleY,
                    confidence: confidence,
                    classId: classId,
                    classLabel: classLabels[classId] ?? "unknown"
                )

                boxes.append(box)
            }
        }

        return boxes
    }

    private func applyNMS(to boxes: [DetectionBox], iouThreshold: Float) -> [DetectionBox] {
        guard !boxes.isEmpty else { return [] }

        // Sort by confidence descending
        let sortedBoxes = boxes.sorted { $0.confidence > $1.confidence }
        var selectedBoxes: [DetectionBox] = []

        for box in sortedBoxes {
            var shouldSelect = true

            for selectedBox in selectedBoxes {
                let iou = box.calculateIoU(with: selectedBox)
                if iou > iouThreshold {
                    shouldSelect = false
                    break
                }
            }

            if shouldSelect {
                selectedBoxes.append(box)
            }
        }

        return selectedBoxes
    }

    private func createErrorResult(
        image: UIImage,
        error: Error,
        startTime: Date
    ) -> ObjectDetectionResult {
        let inferenceTimeMs = Date().timeIntervalSince(startTime) * 1000

        return ObjectDetectionResult(
            detectionBoxes: [],
            inferenceTimeMs: inferenceTimeMs,
            modelIdentifier: inferenceEngine.modelId,
            inputImageSize: image.size,
            confidence: 0,
            isValid: false,
            errorMessage: error.localizedDescription
        )
    }
}
