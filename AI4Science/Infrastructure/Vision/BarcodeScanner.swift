import Foundation
import Vision
import AVFoundation
import os.log

/// Service for scanning barcodes and QR codes
/// Detects and decodes barcode formats from images
actor BarcodeScanner {
    static let shared = BarcodeScanner()

    private let logger = Logger(subsystem: "com.ai4science.vision", category: "BarcodeScanner")

    private init() {}

    // MARK: - Barcode Detection

    /// Detect barcodes in image
    /// - Parameter image: UIImage to scan
    /// - Returns: Array of detected barcodes
    /// - Throws: VisionError if detection fails
    func detectBarcodes(in image: UIImage) async throws -> [BarcodeResult] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNDetectBarcodesRequest()
        request.symbologies = supportedSymbologies()

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results as? [VNBarcodeObservation] else {
            return []
        }

        var results: [BarcodeResult] = []

        for observation in observations {
            let result = BarcodeResult(
                payload: observation.payloadStringValue ?? "",
                symbology: observation.symbology.rawValue,
                confidence: Float(observation.confidence),
                boundingBox: BoundingBox(
                    x: Float(observation.boundingBox.minX),
                    y: Float(observation.boundingBox.minY),
                    width: Float(observation.boundingBox.width),
                    height: Float(observation.boundingBox.height)
                ),
                corners: observation.topLeft, observation.topRight, observation.bottomLeft, observation.bottomRight
            )
            results.append(result)
        }

        logger.debug("Detected \(results.count) barcodes")
        return results
    }

    /// Detect QR codes specifically
    /// - Parameter image: UIImage to scan
    /// - Returns: Array of detected QR codes
    /// - Throws: VisionError if detection fails
    func detectQRCodes(in image: UIImage) async throws -> [QRCodeResult] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNDetectBarcodesRequest()
        request.symbologies = [.QR]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results as? [VNBarcodeObservation] else {
            return []
        }

        var results: [QRCodeResult] = []

        for observation in observations {
            if observation.symbology == .QR {
                let result = QRCodeResult(
                    payload: observation.payloadStringValue ?? "",
                    confidence: Float(observation.confidence),
                    boundingBox: BoundingBox(
                        x: Float(observation.boundingBox.minX),
                        y: Float(observation.boundingBox.minY),
                        width: Float(observation.boundingBox.width),
                        height: Float(observation.boundingBox.height)
                    ),
                    url: extractURL(observation.payloadStringValue ?? ""),
                    contactInfo: extractContactInfo(observation.payloadStringValue ?? "")
                )
                results.append(result)
            }
        }

        logger.debug("Detected \(results.count) QR codes")
        return results
    }

    // MARK: - Specific Barcode Types

    /// Detect UPC/EAN barcodes
    /// - Parameter image: UIImage to scan
    /// - Returns: Array of UPC/EAN results
    /// - Throws: VisionError if detection fails
    func detectUPCCodes(in image: UIImage) async throws -> [UPCResult] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNDetectBarcodesRequest()
        request.symbologies = [.EAN8, .EAN13, .UPCE, .UPCA]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results as? [VNBarcodeObservation] else {
            return []
        }

        var results: [UPCResult] = []

        for observation in observations {
            if let payload = observation.payloadStringValue, payload.count >= 8 {
                let result = UPCResult(
                    code: payload,
                    type: observation.symbology.rawValue,
                    confidence: Float(observation.confidence),
                    boundingBox: BoundingBox(
                        x: Float(observation.boundingBox.minX),
                        y: Float(observation.boundingBox.minY),
                        width: Float(observation.boundingBox.width),
                        height: Float(observation.boundingBox.height)
                    ),
                    isValid: validateUPCCode(payload)
                )
                results.append(result)
            }
        }

        return results
    }

    // MARK: - Code 128 Barcodes

    /// Detect Code128 barcodes (common in industrial/lab settings)
    /// - Parameter image: UIImage to scan
    /// - Returns: Array of Code128 results
    /// - Throws: VisionError if detection fails
    func detectCode128(in image: UIImage) async throws -> [Code128Result] {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        let request = VNDetectBarcodesRequest()
        request.symbologies = [.code128]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results as? [VNBarcodeObservation] else {
            return []
        }

        return observations.compactMap { observation in
            guard let payload = observation.payloadStringValue else { return nil }
            return Code128Result(
                code: payload,
                confidence: Float(observation.confidence),
                boundingBox: BoundingBox(
                    x: Float(observation.boundingBox.minX),
                    y: Float(observation.boundingBox.minY),
                    width: Float(observation.boundingBox.width),
                    height: Float(observation.boundingBox.height)
                )
            )
        }
    }

    // MARK: - Streaming Barcode Detection

    /// Stream barcode detection from video frames
    /// - Parameter frameStream: AsyncStream of video frames
    /// - Returns: AsyncStream of barcode detection results
    func streamBarcodeDetection(
        from frameStream: AsyncStream<CVPixelBuffer>
    ) -> AsyncStream<BarcodeScanFrame> {
        AsyncStream { continuation in
            Task {
                for await pixelBuffer in frameStream {
                    do {
                        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                        let request = VNDetectBarcodesRequest()
                        request.symbologies = supportedSymbologies()

                        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
                        try handler.perform([request])

                        let observations = request.results as? [VNBarcodeObservation] ?? []
                        let barcodes = observations.compactMap { observation in
                            observation.payloadStringValue
                        }

                        let frame = BarcodeScanFrame(
                            pixelBuffer: pixelBuffer,
                            detectedBarcodes: barcodes,
                            barcodeCount: barcodes.count,
                            timestamp: Date()
                        )

                        continuation.yield(frame)
                    } catch {
                        logger.error("Barcode scanning error: \(error.localizedDescription)")
                    }
                }

                continuation.finish()
            }
        }
    }

    // MARK: - Batch Scanning

    /// Scan multiple images for barcodes
    /// - Parameter images: Array of UIImage to scan
    /// - Returns: Array of scan results
    /// - Throws: VisionError if any scan fails
    func scanImages(_ images: [UIImage]) async throws -> [BarcodeScanResult] {
        var results: [BarcodeScanResult] = []

        for (index, image) in images.enumerated() {
            let barcodes = try await detectBarcodes(in: image)
            let result = BarcodeScanResult(
                imageIndex: index,
                barcodes: barcodes,
                timestamp: Date()
            )
            results.append(result)
        }

        return results
    }

    // MARK: - Validation

    /// Validate UPC code checksum
    /// - Parameter code: UPC code string
    /// - Returns: true if checksum is valid
    private func validateUPCCode(_ code: String) -> Bool {
        let cleanCode = code.filter { $0.isNumber }
        guard (cleanCode.count == 12 || cleanCode.count == 13) else { return false }

        var sum = 0
        for (index, char) in cleanCode.dropLast().enumerated() {
            if let digit = Int(String(char)) {
                let multiplier = (index % 2 == 0) ? 3 : 1
                sum += digit * multiplier
            }
        }

        let checkDigit = (10 - (sum % 10)) % 10
        let lastDigit = Int(String(cleanCode.last ?? "0")) ?? 0

        return checkDigit == lastDigit
    }

    // MARK: - Helper Methods

    private func supportedSymbologies() -> [VNBarcodeSymbology] {
        return [
            .QR,
            .code128,
            .EAN8,
            .EAN13,
            .UPCE,
            .UPCA,
            .code39,
            .code39Checksum,
            .pdf417
        ]
    }

    private func extractURL(_ payload: String) -> URL? {
        return URL(string: payload)
    }

    private func extractContactInfo(_ payload: String) -> QRContactInfo? {
        // Simple VCARD parsing
        guard payload.starts(with: "BEGIN:VCARD") else { return nil }

        var name: String?
        var phone: String?
        var email: String?

        for line in payload.split(separator: "\n") {
            if line.starts(with: "FN:") {
                name = String(line.dropFirst(3))
            } else if line.starts(with: "TEL:") {
                phone = String(line.dropFirst(4))
            } else if line.starts(with: "EMAIL:") {
                email = String(line.dropFirst(6))
            }
        }

        return QRContactInfo(name: name, phone: phone, email: email)
    }
}

// MARK: - Result Types

struct BarcodeResult: Sendable {
    let payload: String
    let symbology: String
    let confidence: Float
    let boundingBox: BoundingBox
    let corners: (CGPoint, CGPoint, CGPoint, CGPoint)
}

struct QRCodeResult: Sendable {
    let payload: String
    let confidence: Float
    let boundingBox: BoundingBox
    let url: URL?
    let contactInfo: QRContactInfo?
}

struct QRContactInfo: Sendable {
    let name: String?
    let phone: String?
    let email: String?
}

struct UPCResult: Sendable {
    let code: String
    let type: String
    let confidence: Float
    let boundingBox: BoundingBox
    let isValid: Bool
}

struct Code128Result: Sendable {
    let code: String
    let confidence: Float
    let boundingBox: BoundingBox
}

struct BarcodeScanFrame: Sendable {
    let pixelBuffer: CVPixelBuffer
    let detectedBarcodes: [String]
    let barcodeCount: Int
    let timestamp: Date
}

struct BarcodeScanResult: Sendable {
    let imageIndex: Int
    let barcodes: [BarcodeResult]
    let timestamp: Date

    var barcodeCount: Int {
        barcodes.count
    }

    var allPayloads: [String] {
        barcodes.map { $0.payload }
    }
}
