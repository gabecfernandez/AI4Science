import Foundation

public struct GetAnalysisResultsUseCase: Sendable {
    private let analysisRepository: any AnalysisRepositoryProtocol

    public init(analysisRepository: any AnalysisRepositoryProtocol) {
        self.analysisRepository = analysisRepository
    }

    /// Fetches analysis history for a capture
    /// - Parameter captureId: Capture identifier
    /// - Returns: Sorted array of analysis results
    /// - Throws: AnalysisError if fetch fails
    public func execute(captureId: String) async throws -> [AnalysisResult] {
        guard !captureId.isEmpty else {
            throw AnalysisError.validationFailed("Capture ID is required.")
        }

        let results = try await analysisRepository.fetchAnalysisHistory(captureId: captureId)
        return results.sorted { $0.createdAt > $1.createdAt }
    }

    /// Gets a single analysis result
    /// - Parameter id: Analysis result identifier
    /// - Returns: AnalysisResult
    /// - Throws: AnalysisError if fetch fails
    public func getResult(id: String) async throws -> AnalysisResult {
        guard !id.isEmpty else {
            throw AnalysisError.validationFailed("Analysis ID is required.")
        }

        return try await analysisRepository.getAnalysisResult(id: id)
    }

    /// Filters analysis results by confidence threshold
    /// - Parameters:
    ///   - captureId: Capture identifier
    ///   - minConfidence: Minimum confidence threshold
    /// - Returns: Filtered analysis results
    /// - Throws: AnalysisError if fetch fails
    public func execute(
        captureId: String,
        minConfidence: Float
    ) async throws -> [AnalysisResult] {
        guard minConfidence >= 0 && minConfidence <= 1.0 else {
            throw AnalysisError.validationFailed("Confidence must be between 0 and 1.")
        }

        let results = try await execute(captureId: captureId)
        return results.filter { $0.confidence >= minConfidence }
    }

    /// Gets analysis summary statistics
    /// - Parameter captureId: Capture identifier
    /// - Returns: Analysis statistics
    /// - Throws: AnalysisError if calculation fails
    public func getStatistics(captureId: String) async throws -> AnalysisStatistics {
        guard !captureId.isEmpty else {
            throw AnalysisError.validationFailed("Capture ID is required.")
        }

        let results = try await execute(captureId: captureId)

        guard !results.isEmpty else {
            throw AnalysisError.validationFailed("No analysis results found.")
        }

        let totalFindings = results.reduce(0) { $0 + $1.findings.count }
        let avgConfidence = results.reduce(0.0) { $0 + Double($1.confidence) } / Double(results.count)
        let totalProcessingTime = results.reduce(0.0) { $0 + $1.processingTime }
        let avgProcessingTime = totalProcessingTime / Double(results.count)

        let findingsByType = Dictionary(grouping:
            results.flatMap { $0.findings },
            by: { $0.type }
        )
        .mapValues { $0.count }

        return AnalysisStatistics(
            totalAnalyses: results.count,
            totalFindings: totalFindings,
            averageConfidence: Float(avgConfidence),
            totalProcessingTime: totalProcessingTime,
            averageProcessingTime: avgProcessingTime,
            findingsByType: findingsByType,
            latestAnalysisDate: results.first?.createdAt ?? Date()
        )
    }

    /// Compares analysis results across multiple captures
    /// - Parameter captureIds: Array of capture identifiers
    /// - Returns: Comparative analysis results
    /// - Throws: AnalysisError if fetch fails
    public func compare(captureIds: [String]) async throws -> ComparativeAnalysis {
        guard !captureIds.isEmpty else {
            throw AnalysisError.validationFailed("At least one capture ID is required.")
        }

        var allResults: [String: [AnalysisResult]] = [:]

        for captureId in captureIds {
            let results = try await execute(captureId: captureId)
            allResults[captureId] = results
        }

        return ComparativeAnalysis(analysisResultsByCapture: allResults)
    }
}

// MARK: - Supporting Types

public struct AnalysisStatistics: Sendable {
    public let totalAnalyses: Int
    public let totalFindings: Int
    public let averageConfidence: Float
    public let totalProcessingTime: Double
    public let averageProcessingTime: Double
    public let findingsByType: [String: Int]
    public let latestAnalysisDate: Date

    public init(
        totalAnalyses: Int,
        totalFindings: Int,
        averageConfidence: Float,
        totalProcessingTime: Double,
        averageProcessingTime: Double,
        findingsByType: [String: Int],
        latestAnalysisDate: Date
    ) {
        self.totalAnalyses = totalAnalyses
        self.totalFindings = totalFindings
        self.averageConfidence = averageConfidence
        self.totalProcessingTime = totalProcessingTime
        self.averageProcessingTime = averageProcessingTime
        self.findingsByType = findingsByType
        self.latestAnalysisDate = latestAnalysisDate
    }
}

public struct ComparativeAnalysis: Sendable {
    public let analysisResultsByCapture: [String: [AnalysisResult]]

    public var captureCount: Int {
        analysisResultsByCapture.count
    }

    public var totalFindings: Int {
        analysisResultsByCapture.values.reduce(0) { sum, results in
            sum + results.reduce(0) { $0 + $1.findings.count }
        }
    }

    public func averageConfidenceAcrossCaptures() -> Float {
        let allResults = analysisResultsByCapture.values.flatMap { $0 }
        guard !allResults.isEmpty else { return 0 }
        return allResults.reduce(0) { $0 + $1.confidence } / Float(allResults.count)
    }

    public init(analysisResultsByCapture: [String: [AnalysisResult]]) {
        self.analysisResultsByCapture = analysisResultsByCapture
    }
}
