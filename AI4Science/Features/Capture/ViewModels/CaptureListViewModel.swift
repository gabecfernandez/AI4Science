//
//  CaptureListViewModel.swift
//  AI4Science
//
//  ViewModel for the capture list screen
//

import Foundation
import Observation

/// Display model for captures (Sendable for safe transfer from repository)
struct CaptureDisplayModel: Identifiable, Sendable {
    let id: String
    let captureType: String
    let fileURL: String
    let capturedAt: Date
    let processingStatus: String
    let qualityScore: Double?
    let notes: String?
    let sampleName: String?
    let deviceInfo: String?
    let isProcessed: Bool

    var captureTypeIcon: String {
        switch captureType {
        case "microscopy": return "microscope"
        case "video": return "video.fill"
        case "scan": return "scanner"
        default: return "camera.fill"
        }
    }

    var statusColor: String {
        switch processingStatus {
        case "completed": return "success"
        case "processing": return "warning"
        case "failed": return "error"
        default: return "secondary"
        }
    }
}

/// Filter options for capture type
enum CaptureTypeFilter: String, CaseIterable, Sendable {
    case all = "All"
    case photo = "Photo"
    case video = "Video"
    case microscopy = "Microscopy"
    case scan = "Scan"

    var captureType: String? {
        switch self {
        case .all: return nil
        case .photo: return "photo"
        case .video: return "video"
        case .microscopy: return "microscopy"
        case .scan: return "scan"
        }
    }
}

/// Filter options for processing status
enum CaptureStatusFilter: String, CaseIterable, Sendable {
    case all = "All"
    case pending = "Pending"
    case processing = "Processing"
    case completed = "Completed"

    var status: String? {
        switch self {
        case .all: return nil
        case .pending: return "pending"
        case .processing: return "processing"
        case .completed: return "completed"
        }
    }
}

@Observable
@MainActor
final class CaptureListViewModel {
    // MARK: - Published Properties

    private(set) var captures: [CaptureDisplayModel] = []
    private(set) var filteredCaptures: [CaptureDisplayModel] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    var searchText = "" {
        didSet { applyFilters() }
    }

    var selectedType: CaptureTypeFilter = .all {
        didSet { applyFilters() }
    }

    var selectedStatus: CaptureStatusFilter = .all {
        didSet { applyFilters() }
    }

    // MARK: - Private Properties

    private let captureRepository: CaptureRepository

    // MARK: - Initialization

    init(captureRepository: CaptureRepository) {
        self.captureRepository = captureRepository
    }

    // MARK: - Public Methods

    func loadCaptures() async {
        isLoading = true
        error = nil

        do {
            // Get Sendable display data from repository
            let displayData = try await captureRepository.getAllCapturesDisplayData()

            // Map to our local display model with computed properties
            captures = displayData.map { data in
                CaptureDisplayModel(
                    id: data.id,
                    captureType: data.captureType,
                    fileURL: data.fileURL,
                    capturedAt: data.capturedAt,
                    processingStatus: data.processingStatus,
                    qualityScore: data.qualityScore,
                    notes: data.notes,
                    sampleName: data.sampleName,
                    deviceInfo: data.deviceInfo,
                    isProcessed: data.isProcessed
                )
            }

            applyFilters()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func refresh() async {
        await loadCaptures()
    }

    func deleteCapture(_ id: String) async {
        isLoading = true
        error = nil

        do {
            try await captureRepository.deleteCapture(id: id)
            captures.removeAll { $0.id == id }
            applyFilters()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Private Methods

    private func applyFilters() {
        var result = captures

        // Apply type filter
        if let type = selectedType.captureType {
            result = result.filter { $0.captureType == type }
        }

        // Apply status filter
        if let status = selectedStatus.status {
            result = result.filter { $0.processingStatus == status }
        }

        // Apply search filter
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            result = result.filter { capture in
                capture.sampleName?.localizedCaseInsensitiveContains(trimmedSearch) == true ||
                capture.notes?.localizedCaseInsensitiveContains(trimmedSearch) == true ||
                capture.captureType.localizedCaseInsensitiveContains(trimmedSearch)
            }
        }

        filteredCaptures = result
    }
}

// MARK: - Convenience Extensions

extension CaptureListViewModel {
    var isEmpty: Bool {
        captures.isEmpty && !isLoading
    }

    var isFilteredEmpty: Bool {
        filteredCaptures.isEmpty && !captures.isEmpty && !isLoading
    }

    var captureCount: Int {
        filteredCaptures.count
    }

    var totalCaptureCount: Int {
        captures.count
    }
}
