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
    ///   - parameters: Service analysis parameters (threshold, options, priority)
    /// - Returns: Analysis result with predictions
    /// - Throws: ServiceAnalysisError if analysis fails
    public func execute(
        captureId: String,
        modelId: String,
        parameters: ServiceAnalysisParameters
    ) async throws -> MLAnalysisResult {
        guard !captureId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ServiceAnalysisError.analysisNotFound
        }

        guard !modelId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ServiceAnalysisError.modelNotFound
        }

        do {
            let result = try await analysisService.runMLAnalysis(
                captureId: captureId,
                modelId: modelId,
                parameters: parameters
            )
            return result
        } catch let error as ServiceAnalysisError {
            throw error
        } catch {
            throw ServiceAnalysisError.unknownError(error.localizedDescription)
        }
    }

    /// Create analysis parameters with defaults
    /// - Parameters:
    ///   - threshold: Confidence threshold (0-1)
    ///   - priority: Processing priority
    /// - Returns: Configured service analysis parameters
    public func createParameters(
        threshold: Double? = nil,
        priority: ProcessingPriority = .normal
    ) -> ServiceAnalysisParameters {
        return ServiceAnalysisParameters(threshold: threshold, options: [:], priority: priority)
    }

    /// Run analysis with high priority
    /// - Parameters:
    ///   - captureId: Capture ID to analyze
    ///   - modelId: ML model ID to use
    /// - Returns: Analysis result
    /// - Throws: ServiceAnalysisError if analysis fails
    public func executeHighPriority(
        captureId: String,
        modelId: String
    ) async throws -> MLAnalysisResult {
        let params = createParameters(priority: .high)
        return try await execute(captureId: captureId, modelId: modelId, parameters: params)
    }
}
