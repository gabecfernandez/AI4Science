import Foundation

/// Use case for recording and processing videos
@available(iOS 15.0, *)
public actor CaptureVideoUseCase: Sendable {
    private let captureService: any CaptureServiceProtocol
    private let maxVideoDuration: TimeInterval = 600 // 10 minutes

    public init(captureService: any CaptureServiceProtocol) {
        self.captureService = captureService
    }

    /// Execute video capture
    /// - Parameters:
    ///   - sampleId: Sample ID to attach video to
    ///   - duration: Video duration in seconds
    ///   - metadata: Capture metadata
    /// - Returns: Captured video
    /// - Throws: CaptureError if capture fails
    public func execute(
        sampleId: String,
        duration: TimeInterval,
        metadata: CaptureMetadata
    ) async throws -> Capture {
        guard !sampleId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw CaptureError.fileNotFound
        }

        try validateDuration(duration)

        do {
            let capture = try await captureService.captureVideo(
                sampleId: sampleId,
                duration: duration,
                metadata: metadata
            )
            return capture
        } catch let error as CaptureError {
            throw error
        } catch {
            throw CaptureError.unknownError(error.localizedDescription)
        }
    }

    /// Create metadata for video capture
    /// - Parameters:
    ///   - deviceModel: Device model string
    ///   - captureDate: Date of capture
    /// - Returns: Configured capture metadata
    func createMetadata(
        deviceModel: String,
        captureDate: Date = Date()
    ) -> CaptureMetadata {
        return CaptureMetadata(
            width: 0,
            height: 0,
            colorSpace: .sRGB,
            captureDate: captureDate,
            deviceModel: deviceModel
        )
    }

    private func validateDuration(_ duration: TimeInterval) throws {
        guard duration > 0 && duration <= maxVideoDuration else {
            throw CaptureError.captureFailure("Video duration must be between 0 and \(maxVideoDuration) seconds")
        }
    }
}
