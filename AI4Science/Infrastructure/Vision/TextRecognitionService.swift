import Foundation
import Vision
import os.log

/// Service for OCR and text recognition using Vision framework
/// Extracts and recognizes text from images
actor TextRecognitionService {
    static let shared = TextRecognitionService()

    private let logger = Logger(subsystem: "com.ai4science.vision", category: "TextRecognitionService")

    private init() {}

    // MARK: - Text Recognition

    /// Recognize text in image
    /// - Parameter image: UIImage to analyze
    /// - Returns: Array of recognized TextObservation
    /// - Throws: VisionError if recognition fails
    func recognizeText(in image: UIImage) async throws -> [TextObservation] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["en"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return []
        }

        var results: [TextObservation] = []

        for observation in observations {
            if let topCandidate = observation.topCandidates(1).first {
                results.append(TextObservation(
                    text: topCandidate.string,
                    confidence: Float(observation.confidence),
                    boundingBox: BoundingBox(
                        x: Float(observation.boundingBox.minX),
                        y: Float(observation.boundingBox.minY),
                        width: Float(observation.boundingBox.width),
                        height: Float(observation.boundingBox.height)
                    ),
                    topCandidates: observation.topCandidates(3).map { $0.string }
                ))
            }
        }

        logger.debug("Recognized \(results.count) text elements")
        return results
    }

    /// Extract structured text from image
    /// - Parameter image: UIImage to analyze
    /// - Returns: StructuredText with hierarchy
    /// - Throws: VisionError if extraction fails
    func extractStructuredText(in image: UIImage) async throws -> StructuredText {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["en"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return StructuredText(lines: [], confidence: 0)
        }

        var lines: [TextLine] = []
        var totalConfidence: Float = 0

        for observation in observations {
            if let topCandidate = observation.topCandidates(1).first {
                var bounds = observation.boundingBox

                let line = TextLine(
                    text: topCandidate.string,
                    confidence: Float(observation.confidence),
                    boundingBox: BoundingBox(
                        x: Float(bounds.minX),
                        y: Float(bounds.minY),
                        width: Float(bounds.width),
                        height: Float(bounds.height)
                    ),
                    language: "en"
                )
                lines.append(line)
                totalConfidence += Float(observation.confidence)
            }
        }

        let averageConfidence = observations.isEmpty ? 0 : totalConfidence / Float(observations.count)

        return StructuredText(
            lines: lines,
            confidence: averageConfidence
        )
    }

    /// Recognize text in specific region
    /// - Parameters:
    ///   - image: UIImage to analyze
    ///   - region: Region of interest (normalized coordinates)
    /// - Returns: Array of recognized TextObservation in region
    /// - Throws: VisionError if recognition fails
    func recognizeText(
        in image: UIImage,
        region: BoundingBox
    ) async throws -> [TextObservation] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let regionRect = region.toPixelCoordinates(imageSize: image.size)
        guard let croppedImage = cgImage.cropping(to: regionRect) else {
            throw VisionError.processingFailed("Could not crop image")
        }

        return try await recognizeText(in: UIImage(cgImage: croppedImage))
    }

    /// Find specific text in image
    /// - Parameters:
    ///   - image: UIImage to search
    ///   - searchText: Text to find
    ///   - fuzzyMatch: Enable fuzzy matching
    /// - Returns: Array of matching TextObservation
    /// - Throws: VisionError if search fails
    func findText(
        _ searchText: String,
        in image: UIImage,
        fuzzyMatch: Bool = false
    ) async throws -> [TextObservation] {
        let allText = try await recognizeText(in: image)

        return allText.filter { observation in
            if fuzzyMatch {
                return observation.text.localizedCaseInsensitiveContains(searchText)
            } else {
                return observation.text.lowercased() == searchText.lowercased()
            }
        }
    }

    // MARK: - Document Processing

    /// Extract text from document-like content
    /// - Parameter image: UIImage of document
    /// - Returns: DocumentText with formatted content
    /// - Throws: VisionError if extraction fails
    func extractDocumentText(from image: UIImage) async throws -> DocumentText {
        let structured = try await extractStructuredText(in: image)

        // Group lines into paragraphs (simple heuristic)
        var paragraphs: [String] = []
        var currentParagraph = ""

        for line in structured.lines {
            if currentParagraph.isEmpty {
                currentParagraph = line.text
            } else {
                currentParagraph += " " + line.text
            }

            // End paragraph on low confidence or empty line
            if line.confidence < 0.5 || line.text.isEmpty {
                if !currentParagraph.isEmpty {
                    paragraphs.append(currentParagraph)
                    currentParagraph = ""
                }
            }
        }

        if !currentParagraph.isEmpty {
            paragraphs.append(currentParagraph)
        }

        // Extract full text
        let fullText = paragraphs.joined(separator: "\n\n")

        return DocumentText(
            fullText: fullText,
            paragraphs: paragraphs,
            lines: structured.lines,
            averageConfidence: structured.confidence,
            estimatedLanguage: "English"
        )
    }

    // MARK: - Label/Sample Recognition

    /// Recognize sample label or specimen information
    /// - Parameter image: UIImage of sample label
    /// - Returns: SampleLabel with extracted information
    /// - Throws: VisionError if recognition fails
    func recognizeSampleLabel(from image: UIImage) async throws -> SampleLabel {
        let text = try await recognizeText(in: image)

        // Extract common label patterns
        var sampleID: String?
        var date: String?
        var location: String?
        var additionalInfo: [String] = []

        for observation in text {
            let content = observation.text

            // Simple pattern matching
            if content.count < 20 && observation.confidence > 0.8 {
                if content.range(of: "\\d{4}-\\d{2}-\\d{2}", options: .regularExpression) != nil {
                    date = content
                } else if content.range(of: "^[A-Z0-9]{3,10}$", options: .regularExpression) != nil {
                    sampleID = content
                } else if content.count > 5 && content.count < 30 {
                    additionalInfo.append(content)
                }
            }
        }

        return SampleLabel(
            sampleID: sampleID,
            date: date,
            location: location,
            allText: text.map { $0.text }.joined(separator: " "),
            additionalInfo: additionalInfo,
            confidence: text.map { $0.confidence }.average() ?? 0
        )
    }

    // MARK: - Batch Text Recognition

    /// Recognize text in multiple images
    /// - Parameter images: Array of UIImage to recognize
    /// - Returns: Array of recognized text results
    /// - Throws: VisionError if any recognition fails
    func recognizeText(in images: [UIImage]) async throws -> [TextRecognitionResult] {
        var results: [TextRecognitionResult] = []

        for (index, image) in images.enumerated() {
            let text = try await recognizeText(in: image)
            let result = TextRecognitionResult(
                imageIndex: index,
                recognizedElements: text,
                timestamp: Date()
            )
            results.append(result)
        }

        return results
    }

    // MARK: - Streaming Text Recognition

    /// Stream text recognition from video frames
    /// - Parameter frameStream: AsyncStream of video frames
    /// - Returns: AsyncStream of recognition results
    func streamTextRecognition(
        from frameStream: AsyncStream<CVPixelBuffer>
    ) -> AsyncStream<TextRecognitionFrame> {
        AsyncStream { continuation in
            Task {
                for await pixelBuffer in frameStream {
                    do {
                        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                        let request = VNRecognizeTextRequest()
                        request.recognitionLanguages = ["en"]

                        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
                        try handler.perform([request])

                        let observations = request.results as? [VNRecognizedTextObservation] ?? []
                        let textElements = observations.compactMap { observation in
                            observation.topCandidates(1).first?.string
                        }

                        let frame = TextRecognitionFrame(
                            pixelBuffer: pixelBuffer,
                            recognizedText: textElements,
                            timestamp: Date()
                        )

                        continuation.yield(frame)
                    } catch {
                        logger.error("Text recognition error: \(error.localizedDescription)")
                    }
                }

                continuation.finish()
            }
        }
    }
}

// MARK: - Result Types

struct TextObservation: Sendable {
    let text: String
    let confidence: Float
    let boundingBox: BoundingBox
    let topCandidates: [String]
}

struct TextLine: Sendable {
    let text: String
    let confidence: Float
    let boundingBox: BoundingBox
    let language: String
}

struct StructuredText: Sendable {
    let lines: [TextLine]
    let confidence: Float

    var fullText: String {
        lines.map { $0.text }.joined(separator: " ")
    }
}

struct DocumentText: Sendable {
    let fullText: String
    let paragraphs: [String]
    let lines: [TextLine]
    let averageConfidence: Float
    let estimatedLanguage: String
}

struct SampleLabel: Sendable {
    let sampleID: String?
    let date: String?
    let location: String?
    let allText: String
    let additionalInfo: [String]
    let confidence: Float
}

struct TextRecognitionResult: Sendable {
    let imageIndex: Int
    let recognizedElements: [TextObservation]
    let timestamp: Date

    var fullText: String {
        recognizedElements.map { $0.text }.joined(separator: " ")
    }

    var averageConfidence: Float {
        guard !recognizedElements.isEmpty else { return 0 }
        return recognizedElements.map { $0.confidence }.reduce(0, +) / Float(recognizedElements.count)
    }
}

struct TextRecognitionFrame: Sendable {
    let pixelBuffer: CVPixelBuffer
    let recognizedText: [String]
    let timestamp: Date
}

// MARK: - Helper Extensions

private extension Array where Element == Float {
    func average() -> Float? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Float(count)
    }
}
