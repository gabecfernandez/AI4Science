import Foundation
import AVFoundation
import CoreImage
import os.log

/// Service for extracting and processing video frames
/// Converts video streams to ML-ready frames
actor VideoFrameProcessor {
    static let shared = VideoFrameProcessor()

    private let logger = Logger(subsystem: "com.ai4science.ml", category: "VideoFrameProcessor")
    private let ciContext = CIContext()
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?

    private init() {}

    // MARK: - Video Capture Setup

    /// Setup video capture from camera
    /// - Parameters:
    ///   - preset: Session preset (default .high)
    ///   - position: Camera position (default .back)
    /// - Returns: AsyncStream of CVPixelBuffer frames
    /// - Throws: AVCaptureError if setup fails
    func startVideoCapture(
        preset: AVCaptureSession.Preset = .high,
        position: AVCaptureDevice.Position = .back
    ) async throws -> AsyncStream<CVPixelBuffer> {
        let session = AVCaptureSession()
        session.sessionPreset = preset

        // Configure camera input
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            logger.error("Capture device not found")
            throw AVCaptureError.deviceNotFound
        }

        let input = try AVCaptureDeviceInput(device: captureDevice)
        guard session.canAddInput(input) else {
            throw AVCaptureError.cannotAddInput
        }
        session.addInput(input)

        // Configure video output
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        guard session.canAddOutput(output) else {
            throw AVCaptureError.cannotAddOutput
        }
        session.addOutput(output)

        self.captureSession = session
        self.videoOutput = output

        return createFrameStream(for: output)
    }

    // MARK: - Frame Extraction

    /// Create AsyncStream from AVCaptureVideoDataOutput
    private func createFrameStream(for output: AVCaptureVideoDataOutput) -> AsyncStream<CVPixelBuffer> {
        AsyncStream { continuation in
            let delegate = VideoFrameDelegate { pixelBuffer in
                continuation.yield(pixelBuffer)
            }

            let queue = DispatchQueue(label: "com.ai4science.video.frame")
            output.setSampleBufferDelegate(delegate, queue: queue)

            continuation.onTermination = { _ in
                self.stopVideoCapture()
            }
        }
    }

    // MARK: - Frame Processing

    /// Extract frames at specified intervals
    /// - Parameters:
    ///   - frameStream: Input stream of video frames
    ///   - intervalFrames: Number of frames between samples
    /// - Returns: AsyncStream of sampled frames
    func sampleFrames(
        from frameStream: AsyncStream<CVPixelBuffer>,
        intervalFrames: Int = 15
    ) -> AsyncStream<CVPixelBuffer> {
        AsyncStream { continuation in
            Task {
                var frameCount = 0

                for await frame in frameStream {
                    if frameCount % intervalFrames == 0 {
                        continuation.yield(frame)
                    }
                    frameCount += 1
                }

                continuation.finish()
            }
        }
    }

    /// Rotate frame to match display orientation
    /// - Parameters:
    ///   - pixelBuffer: Input frame
    ///   - rotation: Rotation angle in degrees
    /// - Returns: Rotated CVPixelBuffer
    func rotateFrame(
        _ pixelBuffer: CVPixelBuffer,
        rotation: Float = 90
    ) throws -> CVPixelBuffer {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Create rotation transform
        let radians = rotation * .pi / 180
        let transform = CGAffineTransform(rotationAngle: CGFloat(radians))

        let rotated = ciImage.transformed(by: transform)

        // Create new pixel buffer
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        var rotatedBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            height, // Swapped for 90-degree rotation
            width,
            kCVPixelFormatType_32BGRA,
            nil,
            &rotatedBuffer
        )

        guard status == kCVReturnSuccess, let rotatedBuffer = rotatedBuffer else {
            throw AVCaptureError.processingFailed
        }

        _ = try ciContext.render(rotated, to: rotatedBuffer)

        return rotatedBuffer
    }

    /// Resize frame to target dimensions
    /// - Parameters:
    ///   - pixelBuffer: Input frame
    ///   - size: Target size
    /// - Returns: Resized CVPixelBuffer
    func resizeFrame(
        _ pixelBuffer: CVPixelBuffer,
        to size: CGSize
    ) throws -> CVPixelBuffer {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let scale = CGAffineTransform(
            scaleX: size.width / ciImage.extent.width,
            y: size.height / ciImage.extent.height
        )
        let scaled = ciImage.transformed(by: scale)

        var resizedBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32BGRA,
            nil,
            &resizedBuffer
        )

        guard status == kCVReturnSuccess, let resizedBuffer = resizedBuffer else {
            throw AVCaptureError.processingFailed
        }

        _ = try ciContext.render(scaled, to: resizedBuffer)

        return resizedBuffer
    }

    /// Normalize frame pixel values
    /// - Parameters:
    ///   - pixelBuffer: Input frame
    ///   - mean: Mean values per channel
    ///   - std: Standard deviation per channel
    /// - Returns: Normalized CVPixelBuffer
    func normalizeFrame(
        _ pixelBuffer: CVPixelBuffer,
        mean: [Float] = [0.485, 0.456, 0.406],
        std: [Float] = [0.229, 0.224, 0.225]
    ) throws -> CVPixelBuffer {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readAndWrite)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readAndWrite) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw AVCaptureError.processingFailed
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        let pixelCount = width * height

        for i in 0..<pixelCount {
            let pixelIndex = i * 4
            let b = Float(buffer[pixelIndex]) / 255.0
            let g = Float(buffer[pixelIndex + 1]) / 255.0
            let r = Float(buffer[pixelIndex + 2]) / 255.0

            let normalizedB = (b - mean[0]) / std[0]
            let normalizedG = (g - mean[1]) / std[1]
            let normalizedR = (r - mean[2]) / std[2]

            buffer[pixelIndex] = UInt8(max(0, min(255, normalizedB * 255.0)))
            buffer[pixelIndex + 1] = UInt8(max(0, min(255, normalizedG * 255.0)))
            buffer[pixelIndex + 2] = UInt8(max(0, min(255, normalizedR * 255.0)))
        }

        return pixelBuffer
    }

    // MARK: - Batch Frame Processing

    /// Process multiple frames with transformation
    /// - Parameters:
    ///   - frames: Array of CVPixelBuffer
    ///   - transform: Transformation function
    /// - Returns: Array of transformed frames
    func processFrames(
        _ frames: [CVPixelBuffer],
        transform: (CVPixelBuffer) -> CVPixelBuffer?
    ) async -> [CVPixelBuffer] {
        var results: [CVPixelBuffer] = []

        for frame in frames {
            if let transformed = transform(frame) {
                results.append(transformed)
            }
        }

        return results
    }

    /// Create thumbnail from video frame
    /// - Parameters:
    ///   - pixelBuffer: Input frame
    ///   - size: Thumbnail size
    /// - Returns: UIImage thumbnail
    func createThumbnail(
        from pixelBuffer: CVPixelBuffer,
        size: CGSize
    ) throws -> UIImage {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let scale = CGAffineTransform(
            scaleX: size.width / ciImage.extent.width,
            y: size.height / ciImage.extent.height
        )
        let scaled = ciImage.transformed(by: scale)

        let cgImage = try ciContext.createCGImage(scaled, from: scaled.extent)
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Cleanup

    /// Stop video capture
    nonisolated func stopVideoCapture() {
        Task {
            await stopCapture()
        }
    }

    private func stopCapture() {
        captureSession?.stopRunning()
        captureSession = nil
        videoOutput = nil
        logger.debug("Video capture stopped")
    }
}

// MARK: - Video Frame Delegate

private class VideoFrameDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let onFrameReceived: (CVPixelBuffer) -> Void

    init(onFrameReceived: @escaping (CVPixelBuffer) -> Void) {
        self.onFrameReceived = onFrameReceived
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        onFrameReceived(pixelBuffer)
    }
}

// MARK: - Error Types

enum AVCaptureError: LocalizedError {
    case deviceNotFound
    case cannotAddInput
    case cannotAddOutput
    case processingFailed
    case invalidFrame

    var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Camera device not found"
        case .cannotAddInput:
            return "Cannot add camera input to session"
        case .cannotAddOutput:
            return "Cannot add video output to session"
        case .processingFailed:
            return "Frame processing failed"
        case .invalidFrame:
            return "Invalid video frame"
        }
    }
}
