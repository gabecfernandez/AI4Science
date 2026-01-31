import Foundation

/// Use case for deleting captures with file cleanup
@available(iOS 15.0, *)
public actor DeleteCaptureUseCase: Sendable {
    private let captureService: any CaptureServiceProtocol

    public init(captureService: any CaptureServiceProtocol) {
        self.captureService = captureService
    }

    /// Execute capture deletion
    /// - Parameter captureId: Capture ID to delete
    /// - Throws: CaptureError if deletion fails
    public func execute(captureId: String) async throws {
        guard !captureId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw CaptureError.captureNotFound
        }

        do {
            try await captureService.deleteCapture(captureId: captureId)
        } catch let error as CaptureError {
            throw error
        } catch {
            throw CaptureError.unknownError(error.localizedDescription)
        }
    }

    /// Delete multiple captures
    /// - Parameter captureIds: Array of capture IDs to delete
    /// - Throws: CaptureError if deletion fails
    public func deleteMultiple(captureIds: [String]) async throws {
        for captureId in captureIds {
            try await execute(captureId: captureId)
        }
    }
}
