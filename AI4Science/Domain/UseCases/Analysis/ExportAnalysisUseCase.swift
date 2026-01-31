import Foundation

/// Use case for exporting analysis reports
@available(iOS 15.0, *)
public actor ExportAnalysisUseCase: Sendable {
    private let analysisService: any AnalysisServiceProtocol

    public init(analysisService: any AnalysisServiceProtocol) {
        self.analysisService = analysisService
    }

    /// Export analysis results as report
    /// - Parameters:
    ///   - resultIds: Array of analysis result IDs
    ///   - format: Report format (PDF, HTML, JSON, CSV)
    /// - Returns: Report data as bytes
    /// - Throws: AnalysisError if export fails
    public func execute(
        resultIds: [String],
        format: AnalysisReportFormat
    ) async throws -> Data {
        guard !resultIds.isEmpty else {
            throw AnalysisError.analysisNotFound
        }

        // Validate all result IDs
        for resultId in resultIds {
            guard !resultId.trimmingCharacters(in: .whitespaces).isEmpty else {
                throw AnalysisError.analysisNotFound
            }
        }

        do {
            let data = try await analysisService.exportAnalysisReport(
                resultIds: resultIds,
                format: format
            )
            return data
        } catch let error as AnalysisError {
            throw error
        } catch {
            throw AnalysisError.unknownError(error.localizedDescription)
        }
    }

    /// Export single result as PDF
    /// - Parameter resultId: Result ID to export
    /// - Returns: PDF data
    /// - Throws: AnalysisError if export fails
    public func exportAsPDF(resultId: String) async throws -> Data {
        return try await execute(resultIds: [resultId], format: .pdf)
    }

    /// Export multiple results as HTML
    /// - Parameter resultIds: Result IDs to export
    /// - Returns: HTML data
    /// - Throws: AnalysisError if export fails
    public func exportAsHTML(resultIds: [String]) async throws -> Data {
        return try await execute(resultIds: resultIds, format: .html)
    }

    /// Export results as JSON
    /// - Parameter resultIds: Result IDs to export
    /// - Returns: JSON data
    /// - Throws: AnalysisError if export fails
    public func exportAsJSON(resultIds: [String]) async throws -> Data {
        return try await execute(resultIds: resultIds, format: .json)
    }

    /// Export results as CSV
    /// - Parameter resultIds: Result IDs to export
    /// - Returns: CSV data
    /// - Throws: AnalysisError if export fails
    public func exportAsCSV(resultIds: [String]) async throws -> Data {
        return try await execute(resultIds: resultIds, format: .csv)
    }
}
