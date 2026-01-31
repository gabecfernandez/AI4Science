import Foundation

/// Minimal repository protocol for saving captures
public protocol SaveCaptureRepositoryProtocol: Sendable {
    func saveCapture(projectId: String, type: CaptureType, data: Data, metadata: CaptureMetadata) async throws -> Capture
}

public struct SaveCaptureUseCase: Sendable {
    private let captureRepository: any SaveCaptureRepositoryProtocol

    public init(captureRepository: any SaveCaptureRepositoryProtocol) {
        self.captureRepository = captureRepository
    }

    /// Saves a capture to local storage
    /// - Parameters:
    ///   - projectId: Associated project identifier
    ///   - type: Type of capture (photo, video, scan)
    ///   - data: Binary data of the capture
    ///   - metadata: Capture metadata
    /// - Returns: Saved Capture object
    /// - Throws: CaptureError if save fails
    public func execute(
        projectId: String,
        type: CaptureType,
        data: Data,
        metadata: CaptureMetadata
    ) async throws -> Capture {
        // Validate inputs
        guard !projectId.isEmpty else {
            throw CaptureError.captureFailure("Project ID is required.")
        }

        guard !data.isEmpty else {
            throw CaptureError.captureFailure("Capture data is empty.")
        }

        // Save through repository
        let capture = try await captureRepository.saveCapture(
            projectId: projectId,
            type: type,
            data: data,
            metadata: metadata
        )

        return capture
    }

    /// Saves multiple captures in batch
    /// - Parameters:
    ///   - projectId: Associated project identifier
    ///   - captures: Array of capture data to save
    /// - Returns: BatchSaveResult with success and failure info
    /// - Throws: CaptureError if batch operation fails
    public func executeBatch(
        projectId: String,
        captures: [BatchCaptureData]
    ) async throws -> BatchSaveResult {
        guard !projectId.isEmpty else {
            throw CaptureError.captureFailure("Project ID is required.")
        }

        guard !captures.isEmpty else {
            throw CaptureError.captureFailure("At least one capture is required.")
        }

        var successCount = 0
        var failedCaptures: [BatchCaptureData] = []
        var savedCaptures: [Capture] = []

        for captureData in captures {
            do {
                let capture = try await execute(
                    projectId: projectId,
                    type: captureData.type,
                    data: captureData.data,
                    metadata: captureData.metadata
                )
                successCount += 1
                savedCaptures.append(capture)
            } catch {
                failedCaptures.append(captureData)
            }
        }

        return BatchSaveResult(
            successCount: successCount,
            failureCount: failedCaptures.count,
            savedCaptures: savedCaptures,
            failedCaptures: failedCaptures
        )
    }
}

// MARK: - Supporting Types

public struct BatchCaptureData: Sendable {
    public let type: CaptureType
    public let data: Data
    public let metadata: CaptureMetadata

    public init(
        type: CaptureType,
        data: Data,
        metadata: CaptureMetadata
    ) {
        self.type = type
        self.data = data
        self.metadata = metadata
    }
}

public struct BatchSaveResult: Sendable {
    public let successCount: Int
    public let failureCount: Int
    public let savedCaptures: [Capture]
    public let failedCaptures: [BatchCaptureData]

    public var isSuccessful: Bool {
        failureCount == 0
    }

    public var partialSuccess: Bool {
        successCount > 0 && failureCount > 0
    }

    public init(
        successCount: Int,
        failureCount: Int,
        savedCaptures: [Capture],
        failedCaptures: [BatchCaptureData]
    ) {
        self.successCount = successCount
        self.failureCount = failureCount
        self.savedCaptures = savedCaptures
        self.failedCaptures = failedCaptures
    }
}
