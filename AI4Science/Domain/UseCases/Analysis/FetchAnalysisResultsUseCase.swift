import Foundation

/// Use case for fetching analysis history
@available(iOS 15.0, *)
public actor FetchAnalysisResultsUseCase: Sendable {
    private let analysisService: any AnalysisServiceProtocol

    public init(analysisService: any AnalysisServiceProtocol) {
        self.analysisService = analysisService
    }

    /// Fetch all analysis results for a capture
    /// - Parameter captureId: Capture ID
    /// - Returns: Array of analysis results sorted by date
    /// - Throws: AnalysisError if fetch fails
    public func execute(captureId: String) async throws -> [MLAnalysisResult] {
        guard !captureId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AnalysisError.analysisNotFound
        }

        do {
            let results = try await analysisService.fetchAnalysisResults(captureId: captureId)
            return results.sorted { $0.createdAt > $1.createdAt }
        } catch let error as AnalysisError {
            throw error
        } catch {
            throw AnalysisError.unknownError(error.localizedDescription)
        }
    }

    /// Fetch latest analysis result for a capture
    /// - Parameter captureId: Capture ID
    /// - Returns: Most recent analysis result or nil
    /// - Throws: AnalysisError if fetch fails
    public func fetchLatest(captureId: String) async throws -> MLAnalysisResult? {
        let results = try await execute(captureId: captureId)
        return results.first
    }

    /// Fetch results by model
    /// - Parameters:
    ///   - captureId: Capture ID
    ///   - modelId: Model ID to filter
    /// - Returns: Results from specified model
    /// - Throws: AnalysisError if fetch fails
    public func fetchByModel(captureId: String, modelId: String) async throws -> [MLAnalysisResult] {
        let allResults = try await execute(captureId: captureId)
        return allResults.filter { $0.modelId == modelId }
    }

    /// Fetch results by status
    /// - Parameters:
    ///   - captureId: Capture ID
    ///   - status: Analysis status to filter
    /// - Returns: Results with specified status
    /// - Throws: AnalysisError if fetch fails
    public func fetchByStatus(captureId: String, status: AnalysisStatus) async throws -> [MLAnalysisResult] {
        let allResults = try await execute(captureId: captureId)
        return allResults.filter { $0.status == status }
    }

    /// Fetch completed results only
    /// - Parameter captureId: Capture ID
    /// - Returns: Completed analysis results
    /// - Throws: AnalysisError if fetch fails
    public func fetchCompleted(captureId: String) async throws -> [MLAnalysisResult] {
        return try await fetchByStatus(captureId: captureId, status: .completed)
    }
}
