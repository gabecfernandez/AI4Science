import Foundation
import CoreML
import os.log

/// Service for converting ML model output to domain models
/// Parses and transforms raw model predictions into structured types
actor ResultPostprocessor {
    static let shared = ResultPostprocessor()

    private let logger = Logger(subsystem: "com.ai4science.ml", category: "ResultPostprocessor")
    private let confidenceFilter = ConfidenceFilter.shared

    private init() {}

    // MARK: - Classification Parsing

    /// Parse classification model output
    /// - Parameter output: MLFeatureProvider from model inference
    /// - Returns: Array of Classification results sorted by confidence
    /// - Throws: MLModelError if parsing fails
    func parseClassificationOutput(_ output: MLFeatureProvider) async throws -> [Classification] {
        guard let outputFeature = output.featureValue(for: "classLabels") else {
            throw MLModelError.outputParsingError("Missing classLabels output")
        }

        guard let multiArrayOutput = output.featureValue(for: "classProbs")?.multiArrayValue else {
            throw MLModelError.outputParsingError("Missing classProbs output")
        }

        var classifications: [Classification] = []

        // Parse output array
        for i in 0..<multiArrayOutput.count {
            let confidence = Float(truncating: multiArrayOutput[i])

            // Get class label
            let label: String
            if let classLabels = outputFeature.multiArrayValue {
                if i < classLabels.count {
                    label = "\(classLabels[i])"
                } else {
                    label = "class_\(i)"
                }
            } else {
                label = "class_\(i)"
            }

            let classification = Classification(
                label: label,
                confidence: confidence,
                probability: Float(confidence)
            )
            classifications.append(classification)
        }

        // Sort by confidence descending
        classifications.sort { $0.confidence > $1.confidence }

        logger.debug("Parsed \(classifications.count) classification results")

        return classifications
    }

    // MARK: - Object Detection Parsing

    /// Parse object detection model output
    /// - Parameter output: MLFeatureProvider from model inference
    /// - Returns: Array of ObjectDetection results
    /// - Throws: MLModelError if parsing fails
    func parseObjectDetectionOutput(_ output: MLFeatureProvider) async throws -> [ObjectDetection] {
        var detections: [ObjectDetection] = []

        // Parse boxes
        guard let boxesFeature = output.featureValue(for: "boxes")?.multiArrayValue else {
            throw MLModelError.outputParsingError("Missing boxes output")
        }

        // Parse classes
        guard let classesFeature = output.featureValue(for: "classes")?.multiArrayValue else {
            throw MLModelError.outputParsingError("Missing classes output")
        }

        // Parse confidences
        guard let confidencesFeature = output.featureValue(for: "confidences")?.multiArrayValue else {
            throw MLModelError.outputParsingError("Missing confidences output")
        }

        let boxCount = min(boxesFeature.count / 4, classesFeature.count, confidencesFeature.count)

        for i in 0..<boxCount {
            let x = Float(truncating: boxesFeature[i * 4])
            let y = Float(truncating: boxesFeature[i * 4 + 1])
            let width = Float(truncating: boxesFeature[i * 4 + 2])
            let height = Float(truncating: boxesFeature[i * 4 + 3])

            let classIndex = Int(truncating: classesFeature[i])
            let className = "class_\(classIndex)"

            let confidence = Float(truncating: confidencesFeature[i])

            let boundingBox = BoundingBox(x: x, y: y, width: width, height: height)
            let detection = ObjectDetection(
                className: className,
                confidence: confidence,
                boundingBox: boundingBox,
                identifier: nil
            )
            detections.append(detection)
        }

        logger.debug("Parsed \(detections.count) object detections")

        return detections
    }

    // MARK: - Defect Detection Parsing

    /// Parse defect detection model output
    /// - Parameter output: MLFeatureProvider from model inference
    /// - Returns: Array of DefectPrediction results
    /// - Throws: MLModelError if parsing fails
    func parseDefectDetectionOutput(_ output: MLFeatureProvider) async throws -> [DefectPrediction] {
        var predictions: [DefectPrediction] = []

        // Parse detection results
        guard let detectionFeature = output.featureValue(for: "detections")?.multiArrayValue else {
            throw MLModelError.outputParsingError("Missing detections output")
        }

        let stride = 8 // x, y, w, h, confidence, class, severity, reserved
        let detectionCount = detectionFeature.count / stride

        for i in 0..<detectionCount {
            let baseIndex = i * stride

            let x = Float(truncating: detectionFeature[baseIndex])
            let y = Float(truncating: detectionFeature[baseIndex + 1])
            let width = Float(truncating: detectionFeature[baseIndex + 2])
            let height = Float(truncating: detectionFeature[baseIndex + 3])
            let confidence = Float(truncating: detectionFeature[baseIndex + 4])
            let defectTypeIndex = Int(truncating: detectionFeature[baseIndex + 5])
            let severityIndex = Int(truncating: detectionFeature[baseIndex + 6])

            let defectType = DefectType.allCases[safe: defectTypeIndex]?.rawValue ?? "unknown"
            let severity = DefectSeverity.allCases[safe: severityIndex] ?? .medium

            let boundingBox = BoundingBox(x: x, y: y, width: width, height: height)
            let prediction = DefectPrediction(
                defectType: defectType,
                confidence: confidence,
                boundingBox: boundingBox,
                severity: severity,
                location: nil
            )
            predictions.append(prediction)
        }

        logger.debug("Parsed \(predictions.count) defect predictions")

        return predictions
    }

    // MARK: - Semantic Segmentation Parsing

    /// Parse semantic segmentation output
    /// - Parameters:
    ///   - output: MLFeatureProvider from model inference
    ///   - classCount: Number of classes in segmentation
    /// - Returns: SegmentationResult with class map
    /// - Throws: MLModelError if parsing fails
    func parseSegmentationOutput(
        _ output: MLFeatureProvider,
        classCount: Int
    ) async throws -> SegmentationResult {
        guard let segmentFeature = output.featureValue(for: "segmentation")?.multiArrayValue else {
            throw MLModelError.outputParsingError("Missing segmentation output")
        }

        let width = segmentFeature.shape[2].intValue
        let height = segmentFeature.shape[1].intValue

        var classMap: [[Int]] = Array(repeating: Array(repeating: 0, count: width), count: height)

        for y in 0..<height {
            for x in 0..<width {
                let maxProb: Float = -1
                var predictedClass = 0

                for c in 0..<classCount {
                    let index = c * height * width + y * width + x
                    let prob = Float(truncating: segmentFeature[index])
                    if prob > maxProb {
                        predictedClass = c
                    }
                }

                classMap[y][x] = predictedClass
            }
        }

        return SegmentationResult(classMap: classMap, classCount: classCount)
    }

    // MARK: - Result Filtering

    /// Filter results by confidence threshold
    /// - Parameters:
    ///   - classifications: Array of classifications
    ///   - threshold: Minimum confidence
    /// - Returns: Filtered classifications
    func filterByConfidence(
        _ classifications: [Classification],
        threshold: Float
    ) -> [Classification] {
        classifications.filter { $0.confidence >= threshold }
    }

    /// Filter detections by confidence threshold
    /// - Parameters:
    ///   - detections: Array of object detections
    ///   - threshold: Minimum confidence
    /// - Returns: Filtered detections
    func filterByConfidence(
        _ detections: [ObjectDetection],
        threshold: Float
    ) -> [ObjectDetection] {
        detections.filter { $0.confidence >= threshold }
    }

    // MARK: - Result Aggregation

    /// Aggregate multiple detection results
    /// - Parameter results: Array of ObjectDetectionResult
    /// - Returns: AggregatedDetectionStats
    func aggregateDetections(_ results: [ObjectDetectionResult]) -> AggregatedDetectionStats {
        let allDetections = results.flatMap { $0.detections }
        let classGroups = Dictionary(grouping: allDetections) { $0.className }

        var classStats: [String: ClassDetectionStats] = [:]
        for (className, detections) in classGroups {
            let confidences = detections.map { $0.confidence }
            classStats[className] = ClassDetectionStats(
                count: detections.count,
                averageConfidence: confidences.reduce(0, +) / Float(confidences.count),
                minConfidence: confidences.min() ?? 0,
                maxConfidence: confidences.max() ?? 0
            )
        }

        return AggregatedDetectionStats(
            totalDetections: allDetections.count,
            imageCount: results.count,
            classStats: classStats
        )
    }

    /// Aggregate multiple classification results
    /// - Parameter results: Array of ImageClassificationResult
    /// - Returns: AggregatedClassificationStats
    func aggregateClassifications(_ results: [ImageClassificationResult]) -> AggregatedClassificationStats {
        let topClasses = results.compactMap { $0.topClassification?.label }
        let classCounts = Dictionary(grouping: topClasses, by: { $0 }).mapValues { $0.count }

        return AggregatedClassificationStats(
            totalImages: results.count,
            uniqueClasses: Set(topClasses),
            classDistribution: classCounts
        )
    }
}

// MARK: - Supporting Types

/// Extended result types
struct SegmentationResult: Sendable {
    let classMap: [[Int]]
    let classCount: Int
}

struct AggregatedDetectionStats: Sendable {
    let totalDetections: Int
    let imageCount: Int
    let classStats: [String: ClassDetectionStats]
}

struct ClassDetectionStats: Sendable {
    let count: Int
    let averageConfidence: Float
    let minConfidence: Float
    let maxConfidence: Float
}

struct AggregatedClassificationStats: Sendable {
    let totalImages: Int
    let uniqueClasses: Set<String>
    let classDistribution: [String: Int]
}

// MARK: - Array Safe Indexing Extension

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
