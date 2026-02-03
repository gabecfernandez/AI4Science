//
//  AnalysisDashboardViewModel.swift
//  AI4Science
//
//  ViewModel for the analysis dashboard screen
//

import Foundation
import Observation

/// Display model for analysis results (Sendable for safe transfer from repository)
struct AnalysisResultDisplayModel: Identifiable, Sendable {
    let id: String
    let modelName: String
    let modelVersion: String
    let analysisType: String
    let status: String
    let startedAt: Date
    let completedAt: Date?
    let duration: Double?
    let confidenceScore: Double?
    let objectCount: Int
    let isReviewed: Bool
    let reviewNotes: String?
    let captureSampleName: String?
    let captureType: String?

    var statusIcon: String {
        switch status {
        case "completed": return "checkmark.circle.fill"
        case "processing": return "arrow.trianglehead.clockwise"
        case "failed": return "xmark.circle.fill"
        default: return "clock"
        }
    }

    var analysisTypeIcon: String {
        switch analysisType {
        case "defect_detection": return "exclamationmark.triangle.fill"
        case "classification": return "tag.fill"
        case "segmentation": return "square.grid.3x3"
        default: return "wand.and.stars"
        }
    }
}

/// Summary stats for analysis dashboard
struct AnalysisSummaryStats {
    var totalAnalyses: Int = 0
    var completedCount: Int = 0
    var processingCount: Int = 0
    var averageConfidence: Double = 0.0
    var totalObjectsDetected: Int = 0
}

/// Filter options for analysis status
enum AnalysisStatusFilter: String, CaseIterable, Sendable {
    case all = "All"
    case completed = "Completed"
    case processing = "Processing"
    case pending = "Pending"
    case failed = "Failed"

    var status: String? {
        switch self {
        case .all: return nil
        case .completed: return "completed"
        case .processing: return "processing"
        case .pending: return "pending"
        case .failed: return "failed"
        }
    }
}

@Observable
@MainActor
final class AnalysisDashboardViewModel {
    // MARK: - Published Properties

    private(set) var results: [AnalysisResultDisplayModel] = []
    private(set) var filteredResults: [AnalysisResultDisplayModel] = []
    private(set) var summaryStats = AnalysisSummaryStats()
    private(set) var isLoading = false
    private(set) var error: Error?

    var selectedStatus: AnalysisStatusFilter = .all {
        didSet { applyFilters() }
    }

    // MARK: - Private Properties

    private let analysisRepository: AnalysisRepository

    // MARK: - Initialization

    init(analysisRepository: AnalysisRepository) {
        self.analysisRepository = analysisRepository
    }

    // MARK: - Public Methods

    func loadResults() async {
        isLoading = true
        error = nil

        do {
            // Get Sendable display data from repository
            let displayData = try await analysisRepository.getAllAnalysisResultsDisplayData()

            // Map to our local display model with computed properties
            results = displayData.map { data in
                AnalysisResultDisplayModel(
                    id: data.id,
                    modelName: data.modelName,
                    modelVersion: data.modelVersion,
                    analysisType: data.analysisType,
                    status: data.status,
                    startedAt: data.startedAt,
                    completedAt: data.completedAt,
                    duration: data.duration,
                    confidenceScore: data.confidenceScore,
                    objectCount: data.objectCount,
                    isReviewed: data.isReviewed,
                    reviewNotes: data.reviewNotes,
                    captureSampleName: data.captureSampleName,
                    captureType: data.captureType
                )
            }

            calculateSummaryStats()
            applyFilters()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func refresh() async {
        await loadResults()
    }

    // MARK: - Private Methods

    private func calculateSummaryStats() {
        summaryStats.totalAnalyses = results.count
        summaryStats.completedCount = results.filter { $0.status == "completed" }.count
        summaryStats.processingCount = results.filter { $0.status == "processing" }.count

        let completedResults = results.filter { $0.status == "completed" && $0.confidenceScore != nil }
        if !completedResults.isEmpty {
            let totalConfidence = completedResults.compactMap { $0.confidenceScore }.reduce(0, +)
            summaryStats.averageConfidence = totalConfidence / Double(completedResults.count)
        }

        summaryStats.totalObjectsDetected = results.reduce(0) { $0 + $1.objectCount }
    }

    private func applyFilters() {
        var result = results

        // Apply status filter
        if let status = selectedStatus.status {
            result = result.filter { $0.status == status }
        }

        filteredResults = result
    }
}

// MARK: - Convenience Extensions

extension AnalysisDashboardViewModel {
    var isEmpty: Bool {
        results.isEmpty && !isLoading
    }

    var isFilteredEmpty: Bool {
        filteredResults.isEmpty && !results.isEmpty && !isLoading
    }

    var resultCount: Int {
        filteredResults.count
    }
}
