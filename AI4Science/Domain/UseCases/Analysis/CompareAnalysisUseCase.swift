import Foundation

/// Use case for comparing multiple analysis results
@available(iOS 15.0, *)
public actor CompareAnalysisUseCase: Sendable {
    private let analysisService: any AnalysisServiceProtocol

    public init(analysisService: any AnalysisServiceProtocol) {
        self.analysisService = analysisService
    }

    /// Compare multiple analysis results
    /// - Parameter resultIds: Array of result IDs to compare (minimum 2)
    /// - Returns: Comparison result with similarities and differences
    /// - Throws: AnalysisError if comparison fails
    public func execute(resultIds: [String]) async throws -> ComparisonResult {
        guard resultIds.count >= 2 else {
            throw AnalysisError.analysisNotFound
        }

        // Validate all result IDs
        for resultId in resultIds {
            guard !resultId.trimmingCharacters(in: .whitespaces).isEmpty else {
                throw AnalysisError.analysisNotFound
            }
        }

        do {
            let comparison = try await analysisService.compareResults(resultIds: resultIds)
            return comparison
        } catch let error as AnalysisError {
            throw error
        } catch {
            throw AnalysisError.unknownError(error.localizedDescription)
        }
    }

    /// Compare two results
    /// - Parameters:
    ///   - resultId1: First result ID
    ///   - resultId2: Second result ID
    /// - Returns: Comparison result
    /// - Throws: AnalysisError if comparison fails
    public func comparePair(resultId1: String, resultId2: String) async throws -> ComparisonResult {
        return try await execute(resultIds: [resultId1, resultId2])
    }

    /// Get similarity percentage
    /// - Parameter comparison: Comparison result
    /// - Returns: Similarity as percentage (0-100)
    public func getSimilarityPercentage(comparison: ComparisonResult) -> Double {
        return comparison.similarity * 100
    }

    /// Check if results are very similar
    /// - Parameters:
    ///   - comparison: Comparison result
    ///   - threshold: Similarity threshold (0-1)
    /// - Returns: True if similarity meets threshold
    public func areSimilar(comparison: ComparisonResult, threshold: Double = 0.8) -> Bool {
        return comparison.similarity >= threshold
    }
}
