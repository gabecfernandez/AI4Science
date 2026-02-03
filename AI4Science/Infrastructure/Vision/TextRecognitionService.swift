import Foundation
import CoreGraphics
import os.log

// MARK: - Stub Implementation for Initial Build

/// Text recognition service (stubbed)
actor TextRecognitionService {
    static let shared = TextRecognitionService()
    private let logger = Logger(subsystem: "com.ai4science.vision", category: "TextRecognition")

    private init() {
        logger.info("TextRecognitionService initialized (stub)")
    }

    func recognizeText(from imageData: Data) async throws -> TextRecognitionResult {
        logger.warning("recognizeText() called on stub")
        return TextRecognitionResult(text: "", blocks: [], confidence: 0)
    }

    func extractText(from imageData: Data) async throws -> String {
        return ""
    }
}

struct TextRecognitionResult: Sendable {
    let text: String
    let blocks: [TextBlock]
    let confidence: Float
}

struct TextBlock: Sendable, Identifiable {
    let id: UUID
    let text: String
    let boundingBox: CGRect
    let confidence: Float

    init(id: UUID = UUID(), text: String, boundingBox: CGRect = .zero, confidence: Float = 1.0) {
        self.id = id
        self.text = text
        self.boundingBox = boundingBox
        self.confidence = confidence
    }
}
