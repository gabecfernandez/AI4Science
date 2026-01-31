import Foundation
import CoreGraphics
import Observation

@Observable
@MainActor
final class AnalysisViewModel {
    /// Detection results. Each element is a struct with id, label, confidence, boundingBox.
    var analysisResults: [Any]?
    var isAnalyzing = false
    var confidenceThreshold: Double = 0.5

    private let _analyze: @Sendable (UUID) async -> [Any]

    /// Initializer that accepts any ML service with an `analyze(captureId:)` method.
    /// The closure is captured at init time via the generic constraint.
    init<S: MLAnalysisService>(mlService: S) {
        self._analyze = { captureId in
            await mlService.analyze(captureId: captureId) as [Any]
        }
    }

    var filteredDetections: [Any] {
        guard let results = analysisResults else { return [] }
        return results.filter { confidence(of: $0) >= confidenceThreshold }
    }

    func analyzeCapture(_ captureId: UUID) async {
        isAnalyzing = true
        let results = await _analyze(captureId)
        analysisResults = results
        isAnalyzing = false
    }

    func exportResults(format: ExportFormat) async throws -> URL? {
        guard analysisResults != nil else { return nil }
        let directory = FileManager.default.temporaryDirectory
        let filename = "analysis_export.\(format.rawValue)"
        let url = directory.appendingPathComponent(filename)
        let data = "{\"results\": []}".data(using: .utf8) ?? Data()
        try data.write(to: url)
        return url
    }
}

// MARK: - ML Analysis Service Protocol

protocol MLAnalysisService: Sendable {
    associatedtype DetectionResult
    func analyze(captureId: UUID) async -> [DetectionResult]
}

// MARK: - Helpers

private func confidence(of item: Any) -> Double {
    let mirror = Mirror(reflecting: item)
    for child in mirror.children where child.label == "confidence" {
        if let value = child.value as? Double {
            return value
        }
    }
    return 0
}
