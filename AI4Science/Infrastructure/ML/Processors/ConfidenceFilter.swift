import Foundation
import os.log

/// Service for filtering predictions by confidence threshold
/// Applies statistical filtering and confidence-based validation
actor ConfidenceFilter {
    static let shared = ConfidenceFilter()

    private let logger = Logger(subsystem: "com.ai4science.ml", category: "ConfidenceFilter")

    private init() {}

    // MARK: - Classification Filtering

    /// Filter classifications by confidence threshold
    /// - Parameters:
    ///   - classifications: Array of classifications
    ///   - threshold: Minimum confidence (0-1)
    /// - Returns: Filtered classifications above threshold
    func filterClassifications(
        _ classifications: [Classification],
        threshold: Float = 0.5
    ) -> [Classification] {
        let filtered = classifications.filter { $0.confidence >= threshold }
        logger.debug("Filtered \(classifications.count) classifications to \(filtered.count) above threshold \(threshold)")
        return filtered
    }

    /// Filter classifications with minimum probability distance
    /// Ensures sufficient gap between top predictions
    /// - Parameters:
    ///   - classifications: Array of classifications
    ///   - minDistance: Minimum confidence gap between top predictions
    /// - Returns: Filtered classifications with sufficient distance
    func filterByProbabilityDistance(
        _ classifications: [Classification],
        minDistance: Float = 0.1
    ) -> [Classification] {
        guard classifications.count > 1 else { return classifications }

        var filtered: [Classification] = []
        var lastConfidence = Float(1.0)

        for classification in classifications {
            let distance = lastConfidence - classification.confidence
            if distance >= minDistance {
                filtered.append(classification)
                lastConfidence = classification.confidence
            }
        }

        logger.debug("Filtered classifications by probability distance: \(filtered.count) results")
        return filtered
    }

    // MARK: - Object Detection Filtering

    /// Filter object detections by confidence
    /// - Parameters:
    ///   - detections: Array of object detections
    ///   - threshold: Minimum confidence
    /// - Returns: Filtered detections above threshold
    func filterDetections(
        _ detections: [ObjectDetection],
        threshold: Float = 0.5
    ) -> [ObjectDetection] {
        let filtered = detections.filter { $0.confidence >= threshold }
        logger.debug("Filtered \(detections.count) detections to \(filtered.count) above threshold \(threshold)")
        return filtered
    }

    /// Filter detections with non-maximum suppression
    /// Removes overlapping bounding boxes based on IoU
    /// - Parameters:
    ///   - detections: Array of object detections
    ///   - iouThreshold: Intersection over Union threshold (0-1)
    /// - Returns: Non-overlapping detections
    func applyNMS(
        _ detections: [ObjectDetection],
        iouThreshold: Float = 0.5
    ) -> [ObjectDetection] {
        guard !detections.isEmpty else { return [] }

        var selected: [ObjectDetection] = []
        var remaining = detections.sorted { $0.confidence > $1.confidence }

        while !remaining.isEmpty {
            let first = remaining.removeFirst()
            selected.append(first)

            remaining.removeAll { detection in
                let iou = calculateIoU(first.boundingBox, detection.boundingBox)
                return iou > iouThreshold
            }
        }

        logger.debug("Applied NMS: \(detections.count) detections → \(selected.count) unique objects")
        return selected
    }

    /// Filter detections by class type
    /// - Parameters:
    ///   - detections: Array of object detections
    ///   - allowedClasses: Set of class names to keep
    /// - Returns: Detections matching specified classes
    func filterByClass(
        _ detections: [ObjectDetection],
        allowedClasses: Set<String>
    ) -> [ObjectDetection] {
        let filtered = detections.filter { allowedClasses.contains($0.className) }
        logger.debug("Filtered detections by class: \(filtered.count) results")
        return filtered
    }

    // MARK: - Defect Detection Filtering

    /// Filter defect predictions by confidence
    /// - Parameters:
    ///   - predictions: Array of defect predictions
    ///   - threshold: Minimum confidence
    /// - Returns: Filtered defect predictions
    func filterDefects(
        _ predictions: [DefectPrediction],
        threshold: Float = 0.5
    ) -> [DefectPrediction] {
        let filtered = predictions.filter { $0.confidence >= threshold }
        logger.debug("Filtered \(predictions.count) defects to \(filtered.count) above threshold \(threshold)")
        return filtered
    }

    /// Filter defects by severity level
    /// - Parameters:
    ///   - predictions: Array of defect predictions
    ///   - minSeverity: Minimum severity level to include
    /// - Returns: Defects meeting severity threshold
    func filterBySeverity(
        _ predictions: [DefectPrediction],
        minSeverity: DefectSeverity = .medium
    ) -> [DefectPrediction] {
        let severityOrder: [DefectSeverity] = [.low, .medium, .high, .critical]
        let minIndex = severityOrder.firstIndex(of: minSeverity) ?? 0

        let filtered = predictions.filter { defect in
            guard let defectIndex = severityOrder.firstIndex(of: defect.severity) else { return false }
            return defectIndex >= minIndex
        }

        logger.debug("Filtered defects by severity: \(filtered.count) results")
        return filtered
    }

    /// Filter defects with clustering
    /// Groups nearby defects to reduce redundant detections
    /// - Parameters:
    ///   - predictions: Array of defect predictions
    ///   - maxDistance: Maximum distance between grouped defects (normalized coordinates)
    /// - Returns: Clustered defect predictions
    func clusterDefects(
        _ predictions: [DefectPrediction],
        maxDistance: Float = 0.1
    ) -> [DefectPrediction] {
        guard !predictions.isEmpty else { return [] }

        var clusters: [[DefectPrediction]] = []
        var remaining = predictions

        while !remaining.isEmpty {
            let first = remaining.removeFirst()
            var cluster = [first]

            remaining.removeAll { defect in
                let distance = calculateCenter(first.boundingBox).distance(to: calculateCenter(defect.boundingBox))
                if distance < maxDistance {
                    cluster.append(defect)
                    return true
                }
                return false
            }

            clusters.append(cluster)
        }

        // Return representative from each cluster (highest confidence)
        let clustered = clusters.compactMap { cluster in
            cluster.max { $0.confidence < $1.confidence }
        }

        logger.debug("Clustered defects: \(predictions.count) → \(clustered.count) clusters")
        return clustered
    }

    // MARK: - Statistical Filtering

    /// Filter results using statistical outlier detection
    /// - Parameters:
    ///   - classifications: Array of classifications
    ///   - standardDeviations: Number of standard deviations for outlier detection
    /// - Returns: Results within statistical bounds
    func filterOutliers(
        _ classifications: [Classification],
        standardDeviations: Float = 2.0
    ) -> [Classification] {
        guard classifications.count > 1 else { return classifications }

        let confidences = classifications.map { Double($0.confidence) }
        let mean = confidences.reduce(0, +) / Double(confidences.count)
        let variance = confidences.map { pow($0 - mean, 2) }.reduce(0, +) / Double(confidences.count)
        let stdDev = sqrt(variance)

        let lowerBound = mean - Double(standardDeviations) * stdDev
        let upperBound = mean + Double(standardDeviations) * stdDev

        let filtered = classifications.filter { classification in
            let confidence = Double(classification.confidence)
            return confidence >= lowerBound && confidence <= upperBound
        }

        logger.debug("Statistical filter (σ=\(standardDeviations)): \(classifications.count) → \(filtered.count) results")
        return filtered
    }

    /// Apply adaptive thresholding based on distribution
    /// - Parameter classifications: Array of classifications
    /// - Returns: Filtered classifications using adaptive threshold
    func filterWithAdaptiveThreshold(
        _ classifications: [Classification]
    ) -> [Classification] {
        guard classifications.count > 1 else { return classifications }

        let confidences = classifications.map { $0.confidence }
        let mean = confidences.reduce(0, +) / Float(confidences.count)
        let variance = confidences.map { pow($0 - mean, 2) }.reduce(0, +) / Float(confidences.count)
        let stdDev = sqrt(variance)

        let adaptiveThreshold = mean - stdDev * 0.5

        let filtered = classifications.filter { $0.confidence >= adaptiveThreshold }

        logger.debug("Adaptive threshold: \(adaptiveThreshold) confidence")
        return filtered
    }

    // MARK: - Batch Filtering

    /// Filter multiple detection results
    /// - Parameters:
    ///   - results: Array of ObjectDetectionResult
    ///   - confidenceThreshold: Minimum confidence
    ///   - iouThreshold: NMS intersection over union threshold
    /// - Returns: Filtered detection results
    func filterDetectionResults(
        _ results: [ObjectDetectionResult],
        confidenceThreshold: Float = 0.5,
        iouThreshold: Float = 0.5
    ) -> [ObjectDetectionResult] {
        return results.map { result in
            let filtered = filterDetections(result.detections, threshold: confidenceThreshold)
            let nmsFiltered = applyNMS(filtered, iouThreshold: iouThreshold)
            return ObjectDetectionResult(
                imageIndex: result.imageIndex,
                image: result.image,
                detections: nmsFiltered,
                timestamp: result.timestamp
            )
        }
    }

    // MARK: - Helper Methods

    /// Calculate Intersection over Union between two bounding boxes
    private func calculateIoU(_ box1: BoundingBox, _ box2: BoundingBox) -> Float {
        let x1 = max(box1.x, box2.x)
        let y1 = max(box1.y, box2.y)
        let x2 = min(box1.x + box1.width, box2.x + box2.width)
        let y2 = min(box1.y + box1.height, box2.y + box2.height)

        guard x2 > x1 && y2 > y1 else { return 0 }

        let intersection = (x2 - x1) * (y2 - y1)
        let area1 = box1.width * box1.height
        let area2 = box2.width * box2.height
        let union = area1 + area2 - intersection

        return intersection / union
    }

    /// Calculate center point of bounding box
    private func calculateCenter(_ box: BoundingBox) -> CGPoint {
        return CGPoint(
            x: CGFloat(box.x + box.width / 2),
            y: CGFloat(box.y + box.height / 2)
        )
    }
}

// MARK: - Distance Calculation Extension

private extension CGPoint {
    func distance(to point: CGPoint) -> Float {
        let dx = x - point.x
        let dy = y - point.y
        return Float(sqrt(dx * dx + dy * dy))
    }
}
