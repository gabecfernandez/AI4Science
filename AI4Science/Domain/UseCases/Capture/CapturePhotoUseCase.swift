import Foundation

/// Use case for capturing and processing photos
@available(iOS 15.0, *)
public actor CapturePhotoUseCase: Sendable {
    private let captureService: any CaptureServiceProtocol

    public init(captureService: any CaptureServiceProtocol) {
        self.captureService = captureService
    }

    /// Execute photo capture
    /// - Parameters:
    ///   - sampleId: Sample ID to attach photo to
    ///   - metadata: Capture metadata (device info, location, notes, etc.)
    /// - Returns: Captured photo
    /// - Throws: CaptureError if capture fails
    public func execute(sampleId: String, metadata: CaptureMetadata) async throws -> Capture {
        guard !sampleId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw CaptureError.fileNotFound
        }

        do {
            let capture = try await captureService.capturePhoto(
                sampleId: sampleId,
                metadata: metadata
            )
            return capture
        } catch let error as CaptureError {
            throw error
        } catch {
            throw CaptureError.unknownError(error.localizedDescription)
        }
    }

    /// Create metadata for photo capture
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
}
