import Foundation

/// Use case for executing ML model on captures
@available(iOS 15.0, *)
public actor RunMLAnalysisUseCase: Sendable {
    private let analysisService: any AnalysisServiceProtocol

    public init(analysisService: any AnalysisServiceProtocol) {
        self.analysisService = analysisService
    }

    /// Execute ML analysis on a capture
    /// - Parameters:
    ///   - captureId: Capture ID to analyze
    ///   - modelId: ML model ID to use
    ///   - parameters: Analysis parameters (threshold, options, priority)
    /// - Returns: Analysis result with predictions
    /// - Throws: AnalysisError if analysis fails
    public func execute(
        captureId: String,
        modelId: String,
        parameters: AnalysisParameters
    ) async throws -> MLAnalysisResult {
        guard !captureId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AnalysisError.analysisNotFound
        }

        guard !modelId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AnalysisError.modelNotFound
        }

        do {
            let result = try await analysisService.runMLAnalysis(
                captureId: captureId,
                modelId: modelId,
                parameters: parameters
            )
            return result
        } catch let error as AnalysisError {
            throw error
        } catch {
            throw AnalysisError.unknownError(error.localizedDescription)
        }
    }

    /// Create analysis parameters with defaults
    /// - Parameters:
    ///   - threshold: Confidence threshold (0-1)
    ///   - priority: Processing priority
    /// - Returns: Configured analysis parameters
    public func createParameters(
        threshold: Double? = nil,
        priority: ProcessingPriority = .normal
    ) -> AnalysisParameters {
        return AnalysisParameters(threshold: threshold, priority: priority)
    }

    /// Run analysis with high priority
    /// - Parameters:
    ///   - captureId: Capture ID to analyze
    ///   - modelId: ML model ID to use
    /// - Returns: Analysis result
    /// - Throws: AnalysisError if analysis fails
    public func executeHighPriority(
        captureId: String,
        modelId: String
    ) async throws -> MLAnalysisResult {
        let params = createParameters(priority: .high)
        return try await execute(captureId: captureId, modelId: modelId, parameters: params)
    }
}
