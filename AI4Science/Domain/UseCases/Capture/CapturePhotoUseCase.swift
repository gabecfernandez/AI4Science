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
    ///   - metadata: Capture service metadata (device info, location, notes, etc.)
    /// - Returns: Captured photo as domain model
    /// - Throws: CaptureError if capture fails
    public func execute(sampleId: String, metadata: CaptureServiceMetadata) async throws -> Capture {
        guard !sampleId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw CaptureError.fileNotFound
        }

        do {
            let response = try await captureService.capturePhoto(
                sampleId: sampleId,
                metadata: metadata
            )
            return response.toDomainCapture()
        } catch let error as CaptureError {
            throw error
        } catch {
            throw CaptureError.unknownError(error.localizedDescription)
        }
    }

    /// Create metadata for photo capture
    /// - Parameters:
    ///   - deviceInfo: Device information
    ///   - notes: Optional notes about the capture
    ///   - tags: Optional tags for categorization
    /// - Returns: Configured capture service metadata
    public func createMetadata(
        deviceInfo: String,
        notes: String? = nil,
        tags: [String] = []
    ) -> CaptureServiceMetadata {
        return CaptureServiceMetadata(
            deviceInfo: deviceInfo,
            notes: notes,
            tags: tags
        )
    }
}
