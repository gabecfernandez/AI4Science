import Foundation

/// Use case for fetching captures for a sample
@available(iOS 15.0, *)
public actor FetchCapturesUseCase: Sendable {
    private let captureService: any CaptureServiceProtocol

    public init(captureService: any CaptureServiceProtocol) {
        self.captureService = captureService
    }

    /// Fetch all captures for a sample
    /// - Parameter sampleId: Sample ID
    /// - Returns: Array of captures
    /// - Throws: CaptureError if fetch fails
    public func execute(sampleId: String) async throws -> [Capture] {
        guard !sampleId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw CaptureError.fileNotFound
        }

        do {
            let captures = try await captureService.fetchCaptures(sampleId: sampleId)
            return captures.sorted { $0.createdAt > $1.createdAt }
        } catch let error as CaptureError {
            throw error
        } catch {
            throw CaptureError.unknownError(error.localizedDescription)
        }
    }

    /// Fetch captures by type
    /// - Parameters:
    ///   - sampleId: Sample ID
    ///   - type: Capture type to filter
    /// - Returns: Filtered array of captures
    /// - Throws: CaptureError if fetch fails
    public func fetchByType(sampleId: String, type: CaptureType) async throws -> [Capture] {
        let allCaptures = try await execute(sampleId: sampleId)
        return allCaptures.filter { $0.type == type }
    }

    /// Fetch photo captures only
    /// - Parameter sampleId: Sample ID
    /// - Returns: Photo captures
    /// - Throws: CaptureError if fetch fails
    public func fetchPhotos(sampleId: String) async throws -> [Capture] {
        return try await fetchByType(sampleId: sampleId, type: .photo)
    }

    /// Fetch video captures only
    /// - Parameter sampleId: Sample ID
    /// - Returns: Video captures
    /// - Throws: CaptureError if fetch fails
    public func fetchVideos(sampleId: String) async throws -> [Capture] {
        return try await fetchByType(sampleId: sampleId, type: .video)
    }

    /// Fetch captures by tag
    /// - Parameters:
    ///   - sampleId: Sample ID
    ///   - tag: Tag to filter by
    /// - Returns: Captures with specified tag
    /// - Throws: CaptureError if fetch fails
    public func fetchByTag(sampleId: String, tag: String) async throws -> [Capture] {
        let allCaptures = try await execute(sampleId: sampleId)
        return allCaptures.filter { $0.metadata.tags.contains(tag) }
    }
}
