import Foundation

/// Use case for batch analyzing multiple captures
@available(iOS 15.0, *)
public actor BatchAnalysisUseCase: Sendable {
    private let analysisService: any AnalysisServiceProtocol

    public init(analysisService: any AnalysisServiceProtocol) {
        self.analysisService = analysisService
    }

    /// Analyze multiple captures in batch
    /// - Parameters:
    ///   - captureIds: Array of capture IDs to analyze
    ///   - modelId: ML model ID to use
    ///   - parameters: Analysis parameters
    /// - Returns: Array of analysis results
    /// - Throws: AnalysisError if batch analysis fails
    public func execute(
        captureIds: [String],
        modelId: String,
        parameters: AnalysisParameters
    ) async throws -> [MLAnalysisResult] {
        guard !captureIds.isEmpty else {
            throw AnalysisError.analysisNotFound
        }

        guard !modelId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AnalysisError.modelNotFound
        }

        // Validate all capture IDs
        for captureId in captureIds {
            guard !captureId.trimmingCharacters(in: .whitespaces).isEmpty else {
                throw AnalysisError.analysisNotFound
            }
        }

        do {
            let results = try await analysisService.batchAnalysis(
                captureIds: captureIds,
                modelId: modelId,
                parameters: parameters
            )
            return results
        } catch let error as AnalysisError {
            throw error
        } catch {
            throw AnalysisError.unknownError(error.localizedDescription)
        }
    }

    /// Get batch analysis statistics
    /// - Parameter results: Array of analysis results
    /// - Returns: Batch statistics
    public func calculateStatistics(results: [MLAnalysisResult]) -> BatchStatistics {
        guard !results.isEmpty else {
            return BatchStatistics(
                totalAnalyzed: 0,
                successCount: 0,
                failureCount: 0,
                averageConfidence: 0,
                averageExecutionTime: 0
            )
        }

        let successCount = results.filter { $0.status == .completed }.count
        let failureCount = results.filter { $0.status == .failed }.count
        let avgConfidence = results.map { $0.confidence }.reduce(0, +) / Double(results.count)
        let avgTime = results.map { $0.executionTime }.reduce(0, +) / Double(results.count)

        return BatchStatistics(
            totalAnalyzed: results.count,
            successCount: successCount,
            failureCount: failureCount,
            averageConfidence: avgConfidence,
            averageExecutionTime: avgTime
        )
    }
}

/// Batch analysis statistics
public struct BatchStatistics: Sendable {
    public let totalAnalyzed: Int
    public let successCount: Int
    public let failureCount: Int
    public let averageConfidence: Double
    public let averageExecutionTime: TimeInterval

    public init(
        totalAnalyzed: Int,
        successCount: Int,
        failureCount: Int,
        averageConfidence: Double,
        averageExecutionTime: TimeInterval
    ) {
        self.totalAnalyzed = totalAnalyzed
        self.successCount = successCount
        self.failureCount = failureCount
        self.averageConfidence = averageConfidence
        self.averageExecutionTime = averageExecutionTime
    }
}
