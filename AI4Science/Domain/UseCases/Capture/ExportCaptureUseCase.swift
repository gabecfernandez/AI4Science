import Foundation

/// Use case for exporting captures with metadata
@available(iOS 15.0, *)
public actor ExportCaptureUseCase: Sendable {
    private let captureService: any CaptureServiceProtocol

    public init(captureService: any CaptureServiceProtocol) {
        self.captureService = captureService
    }

    /// Export capture in specified format
    /// - Parameters:
    ///   - captureId: Capture ID to export
    ///   - format: Export format (raw, zip, json)
    /// - Returns: Exported data as bytes
    /// - Throws: CaptureError if export fails
    public func execute(captureId: String, format: CaptureExportFormat) async throws -> Data {
        guard !captureId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw CaptureError.captureNotFound
        }

        do {
            let data = try await captureService.exportCapture(
                captureId: captureId,
                format: format
            )
            return data
        } catch let error as CaptureError {
            throw error
        } catch {
            throw CaptureError.unknownError(error.localizedDescription)
        }
    }

    /// Export capture as raw file
    /// - Parameter captureId: Capture ID to export
    /// - Returns: Raw file data
    /// - Throws: CaptureError if export fails
    public func exportAsRaw(captureId: String) async throws -> Data {
        return try await execute(captureId: captureId, format: .raw)
    }

    /// Export capture with metadata as ZIP
    /// - Parameter captureId: Capture ID to export
    /// - Returns: ZIP archive containing file and metadata
    /// - Throws: CaptureError if export fails
    public func exportAsZIP(captureId: String) async throws -> Data {
        return try await execute(captureId: captureId, format: .zip)
    }

    /// Export capture metadata as JSON
    /// - Parameter captureId: Capture ID to export
    /// - Returns: JSON metadata
    /// - Throws: CaptureError if export fails
    public func exportAsJSON(captureId: String) async throws -> Data {
        return try await execute(captureId: captureId, format: .json)
    }
}
