import Foundation

/// View-specific sample model for display purposes
/// Used by sample list and detail views for UI presentation
struct SampleDisplayItem: Identifiable, Hashable {
    let id: String
    let name: String
    let type: String
    let date: Date
    let imageCount: Int
    let hasAnalysis: Bool
    let analysisStatus: AnalysisStatus

    enum AnalysisStatus: String {
        case pending = "Pending"
        case processing = "Processing"
        case completed = "Completed"
        case error = "Error"
    }
}

// MARK: - Stub ViewModels for Samples Feature
// These are placeholder implementations to allow the project to build

/// ViewModel for sample list operations
@Observable
@MainActor
final class SampleListViewModel {
    var samples: [SampleDisplayItem] = []
    var isLoading = false
    var error: Error?

    func loadSamples(for projectID: String) async {
        isLoading = true
        defer { isLoading = false }

        // Stub: Load sample data
        // TODO: Implement actual data loading from repository
        samples = []
    }

    func refresh() async {
        // Stub: Refresh samples
    }
}

/// ViewModel for sample detail operations
@Observable
@MainActor
final class SampleDetailViewModel {
    var sampleDetails: SampleDisplayItem?
    var isLoading = false
    var error: Error?

    func loadSampleDetails(for sampleID: String) async {
        isLoading = true

        // Stub: Load sample details
        // TODO: Implement actual data loading from repository

        isLoading = false
    }
}
