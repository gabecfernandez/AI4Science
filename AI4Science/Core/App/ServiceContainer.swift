//
//  ServiceContainer.swift
//  AI4Science
//
//  Dependency injection container for services
//

import Foundation
import SwiftData
import Observation

/// Central container for all application services
@Observable
@MainActor
final class ServiceContainer {
    // MARK: - Repositories
    let userRepository: UserRepository
    let projectRepository: ProjectRepository
    let sampleRepository: SampleRepository
    let captureRepository: CaptureRepository
    let annotationRepository: AnnotationRepository
    let analysisRepository: AnalysisRepository

    // MARK: - Services
    let authService: AuthenticationService
    let mlService: MLService
    let cameraService: CameraServiceImpl
    let mediaService: MediaService
    let syncService: SyncService
    let exportService: DataExportService

    // MARK: - Initialization

    init(modelContainer: ModelContainer) {
        // Initialize repositories using @ModelActor pattern (requires modelContainer)
        self.userRepository = UserRepository(modelContainer: modelContainer)
        self.projectRepository = ProjectRepository(modelContainer: modelContainer)
        self.sampleRepository = SampleRepository(modelContainer: modelContainer)
        self.captureRepository = CaptureRepository(modelContainer: modelContainer)
        self.annotationRepository = AnnotationRepository(modelContainer: modelContainer)
        self.analysisRepository = AnalysisRepository(modelContainer: modelContainer)

        // Initialize services
        self.authService = AuthenticationService(userRepository: userRepository)
        self.mlService = MLService()
        self.cameraService = CameraServiceImpl()
        self.mediaService = MediaService()
        self.syncService = SyncService(
            projectRepository: projectRepository,
            captureRepository: captureRepository,
            annotationRepository: annotationRepository
        )
        self.exportService = DataExportService(
            projectRepository: projectRepository,
            captureRepository: captureRepository,
            annotationRepository: annotationRepository
        )

        AppLogger.info("ServiceContainer initialized")
    }
}

// MARK: - ML Service

final class MLService: @unchecked Sendable {
    private var loadedModels: Set<String> = []

    func preloadModels() async {
        loadedModels.insert("defectDetection")
        AppLogger.info("ML models preloaded")
    }

    func runInference(on imageURL: URL, modelType: String) async throws -> [DetectionOutput] {
        []
    }

    func unloadModels() async {
        loadedModels.removeAll()
    }
}

// MARK: - Camera Service Implementation

final class CameraServiceImpl: @unchecked Sendable {
    func startSession() async throws {}
    func stopSession() async {}

    func capturePhoto() async throws -> CaptureOutput {
        CaptureOutput(url: URL(fileURLWithPath: "/tmp/photo.heic"), type: .photo)
    }

    func startRecording() async throws {}

    func stopRecording() async throws -> CaptureOutput {
        CaptureOutput(url: URL(fileURLWithPath: "/tmp/video.mov"), type: .video)
    }
}

struct CaptureOutput: Sendable {
    let url: URL
    let type: CaptureType
}

// MARK: - Media Service

final class MediaService: @unchecked Sendable {
    func save(_ data: Data, type: MediaTypeEnum) async throws -> URL {
        let fileName = "\(UUID().uuidString).\(type.fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url)
        return url
    }

    func load(from url: URL) async throws -> Data {
        try Data(contentsOf: url)
    }

    func delete(at url: URL) async throws {
        try FileManager.default.removeItem(at: url)
    }

    func generateThumbnail(for url: URL) async throws -> URL {
        url
    }
}

enum MediaTypeEnum: String, Sendable {
    case photo
    case video
    case thumbnail

    var fileExtension: String {
        switch self {
        case .photo: return "heic"
        case .video: return "mov"
        case .thumbnail: return "jpg"
        }
    }
}

// MARK: - Sync Service

final class SyncService: @unchecked Sendable {
    private let projectRepository: ProjectRepository
    private let captureRepository: CaptureRepository
    private let annotationRepository: AnnotationRepository

    init(
        projectRepository: ProjectRepository,
        captureRepository: CaptureRepository,
        annotationRepository: AnnotationRepository
    ) {
        self.projectRepository = projectRepository
        self.captureRepository = captureRepository
        self.annotationRepository = annotationRepository
    }

    func configure() async {}

    func sync() async throws -> SyncOutputResult {
        SyncOutputResult(status: .completed, syncedItemsCount: 0, conflicts: [])
    }

    func queueOperation(_ operation: SyncOp) async {}
}

struct SyncOutputResult: Sendable {
    let status: SyncOutputStatus
    let syncedItemsCount: Int
    let conflicts: [SyncConflictItem]
}

enum SyncOutputStatus: Sendable {
    case completed
    case completedWithConflicts
    case failed
    case queued
}

struct SyncConflictItem: Sendable {
    let entityId: UUID
    let entityType: String
}

struct SyncOp: Sendable {
    let id: UUID
    let entityType: String
    let entityId: UUID
    let operation: String
}

// MARK: - Export Service

final class DataExportService: @unchecked Sendable {
    private let projectRepository: ProjectRepository
    private let captureRepository: CaptureRepository
    private let annotationRepository: AnnotationRepository

    init(
        projectRepository: ProjectRepository,
        captureRepository: CaptureRepository,
        annotationRepository: AnnotationRepository
    ) {
        self.projectRepository = projectRepository
        self.captureRepository = captureRepository
        self.annotationRepository = annotationRepository
    }

    func exportProject(_ projectId: UUID, format: ExportFormatType) async throws -> URL {
        URL(fileURLWithPath: "/tmp/export.zip")
    }

    func exportCaptures(_ captureIds: [UUID], format: ExportFormatType) async throws -> URL {
        URL(fileURLWithPath: "/tmp/captures.zip")
    }
}

enum ExportFormatType: String, Sendable, CaseIterable {
    case json
    case csv
    case zip
    case pdf
}
