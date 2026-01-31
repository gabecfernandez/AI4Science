import Foundation
import Vision
import CoreML
import os.log

/// Service for comprehensive image analysis using Vision framework
/// Combines multiple vision tasks for complete image understanding
actor ImageAnalyzer {
    static let shared = ImageAnalyzer()

    private let logger = Logger(subsystem: "com.ai4science.vision", category: "ImageAnalyzer")
    private let visionService: VisionService

    private init(visionService: VisionService = .shared) {
        self.visionService = visionService
    }

    // MARK: - Comprehensive Analysis

    /// Perform complete image analysis
    /// - Parameter image: UIImage to analyze
    /// - Returns: ImageAnalysisResult with all findings
    /// - Throws: VisionError if analysis fails
    func analyzeImage(_ image: UIImage) async throws -> ImageAnalysisResult {
        async let faceResults = visionService.detectFaces(in: image)
        async let sceneResults = visionService.classifyScene(in: image)
        async let qualityResults = visionService.analyzeImageQuality(image)
        async let alignmentResults = visionService.detectAlignment(in: image)
        async let documentResults = visionService.detectDocument(in: image)

        let faces = try await faceResults
        let scenes = try await sceneResults
        let quality = try await qualityResults
        let alignment = try await alignmentResults
        let document = try await documentResults

        return ImageAnalysisResult(
            timestamp: Date(),
            imageSize: image.size,
            faces: faces,
            scenes: scenes,
            quality: quality,
            alignment: alignment,
            document: document
        )
    }

    // MARK: - Targeted Analysis

    /// Analyze image for specific content
    /// - Parameters:
    ///   - image: UIImage to analyze
    ///   - focusAreas: Specific areas to analyze
    /// - Returns: Focused analysis results
    /// - Throws: VisionError if analysis fails
    func analyzeWithFocus(_ image: UIImage, focusAreas: [AnalysisFocus]) async throws -> FocusedAnalysisResult {
        var results: [AnalysisFocus: AnalysisData] = [:]

        for focus in focusAreas {
            switch focus {
            case .faces:
                let faces = try await visionService.detectFaces(in: image)
                results[.faces] = .faces(faces)

            case .scene:
                let scenes = try await visionService.classifyScene(in: image)
                results[.scene] = .scene(scenes)

            case .quality:
                let quality = try await visionService.analyzeImageQuality(image)
                results[.quality] = .quality(quality)

            case .alignment:
                let alignment = try await visionService.detectAlignment(in: image)
                results[.alignment] = .alignment(alignment)

            case .document:
                if let document = try await visionService.detectDocument(in: image) {
                    results[.document] = .document(document)
                }
            }
        }

        return FocusedAnalysisResult(
            timestamp: Date(),
            results: results
        )
    }

    // MARK: - Batch Analysis

    /// Analyze multiple images
    /// - Parameter images: Array of UIImage to analyze
    /// - Returns: Array of ImageAnalysisResult
    /// - Throws: VisionError if any analysis fails
    func analyzeImages(_ images: [UIImage]) async throws -> [ImageAnalysisResult] {
        var results: [ImageAnalysisResult] = []

        for image in images {
            let result = try await analyzeImage(image)
            results.append(result)
        }

        return results
    }

    // MARK: - Streaming Analysis

    /// Stream analysis of video frames
    /// - Parameter frameStream: AsyncStream of video frames
    /// - Returns: AsyncStream of analysis results
    func streamAnalysis(
        from frameStream: AsyncStream<CVPixelBuffer>
    ) -> AsyncStream<StreamingAnalysisFrame> {
        AsyncStream { continuation in
            Task {
                for await pixelBuffer in frameStream {
                    do {
                        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                        let size = ciImage.extent.size

                        // Detect faces
                        let faceRequest = VNDetectFaceRectanglesRequest()
                        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
                        try handler.perform([faceRequest])

                        let faces = faceRequest.results as? [VNFaceObservation] ?? []

                        let frame = StreamingAnalysisFrame(
                            pixelBuffer: pixelBuffer,
                            size: size,
                            faceCount: faces.count,
                            confidence: faces.map { Float($0.confidence) }.max() ?? 0,
                            timestamp: Date()
                        )

                        continuation.yield(frame)
                    } catch {
                        logger.error("Frame analysis error: \(error.localizedDescription)")
                    }
                }

                continuation.finish()
            }
        }
    }

    // MARK: - Image Comparison

    /// Compare two images for similarity
    /// - Parameters:
    ///   - image1: First image
    ///   - image2: Second image
    /// - Returns: ImageComparisonResult with similarity metrics
    /// - Throws: VisionError if comparison fails
    func compareImages(_ image1: UIImage, _ image2: UIImage) async throws -> ImageComparisonResult {
        guard let cgImage1 = image1.cgImage, let cgImage2 = image2.cgImage else {
            throw VisionError.invalidImage
        }

        let request1 = VNGenerateImageFeaturePrintRequest()
        let request2 = VNGenerateImageFeaturePrintRequest()

        let handler1 = VNImageRequestHandler(cgImage: cgImage1, options: [:])
        let handler2 = VNImageRequestHandler(cgImage: cgImage2, options: [:])

        try handler1.perform([request1])
        try handler2.perform([request2])

        guard let featurePrint1 = request1.results?.first as? VNFeaturePrintObservation,
              let featurePrint2 = request2.results?.first as? VNFeaturePrintObservation else {
            throw VisionError.processingFailed("Could not extract feature prints")
        }

        var distance: Float = 0
        let success = try featurePrint1.computeDistance(&distance, to: featurePrint2)

        guard success else {
            throw VisionError.processingFailed("Could not compute distance")
        }

        let similarity = 1.0 - (distance / 100.0) // Normalize distance to similarity
        let isSimilar = similarity > 0.7

        return ImageComparisonResult(
            similarity: Float(max(0, min(1, similarity))),
            distance: distance,
            isSimilar: isSimilar,
            timestamp: Date()
        )
    }

    // MARK: - Region of Interest Analysis

    /// Analyze specific region of interest in image
    /// - Parameters:
    ///   - image: UIImage to analyze
    ///   - roi: Region of interest (normalized coordinates)
    /// - Returns: RegionAnalysisResult
    /// - Throws: VisionError if analysis fails
    func analyzeRegion(
        _ image: UIImage,
        roi: BoundingBox
    ) async throws -> RegionAnalysisResult {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let croppedRect = roi.toPixelCoordinates(imageSize: image.size)
        guard let croppedImage = cgImage.cropping(to: croppedRect) else {
            throw VisionError.processingFailed("Could not crop image")
        }

        let faces = try await visionService.detectFaces(in: UIImage(cgImage: croppedImage))
        let scenes = try await visionService.classifyScene(in: UIImage(cgImage: croppedImage))

        return RegionAnalysisResult(
            region: roi,
            detectedFaces: faces,
            sceneClassifications: scenes,
            timestamp: Date()
        )
    }
}

// MARK: - Result Types

struct ImageAnalysisResult: Sendable {
    let timestamp: Date
    let imageSize: CGSize
    let faces: [FaceDetectionResult]
    let scenes: [SceneClassification]
    let quality: ImageQualityMetrics
    let alignment: AlignmentDetection
    let document: DocumentDetection?

    var hasFaces: Bool {
        !faces.isEmpty
    }

    var dominantScene: SceneClassification? {
        scenes.first
    }

    var isHighQuality: Bool {
        quality.overallQuality > 0.7
    }
}

enum AnalysisFocus: String, Sendable {
    case faces
    case scene
    case quality
    case alignment
    case document
}

enum AnalysisData: Sendable {
    case faces([FaceDetectionResult])
    case scene([SceneClassification])
    case quality(ImageQualityMetrics)
    case alignment(AlignmentDetection)
    case document(DocumentDetection)
}

struct FocusedAnalysisResult: Sendable {
    let timestamp: Date
    let results: [AnalysisFocus: AnalysisData]
}

struct StreamingAnalysisFrame: Sendable {
    let pixelBuffer: CVPixelBuffer
    let size: CGSize
    let faceCount: Int
    let confidence: Float
    let timestamp: Date
}

struct ImageComparisonResult: Sendable {
    let similarity: Float
    let distance: Float
    let isSimilar: Bool
    let timestamp: Date

    var similarityPercentage: Float {
        similarity * 100
    }
}

struct RegionAnalysisResult: Sendable {
    let region: BoundingBox
    let detectedFaces: [FaceDetectionResult]
    let sceneClassifications: [SceneClassification]
    let timestamp: Date
}
