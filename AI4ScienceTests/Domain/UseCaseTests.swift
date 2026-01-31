//
//  UseCaseTests.swift
//  AI4ScienceTests
//
//  Created for AI4Science UTSA
//

import Testing
import Foundation
@testable import AI4Science

@Suite("Create Project Use Case Tests")
struct CreateProjectUseCaseTests {

    @Test("Successfully creates a project")
    func testCreateProject() async throws {
        let mockRepository = MockProjectRepository()
        let useCase = CreateProjectUseCase(repository: mockRepository)

        let request = CreateProjectRequest(
            name: "New Research Project",
            description: "Testing materials analysis",
            ownerId: UUID()
        )

        let project = try await useCase.execute(request)

        #expect(project.name == "New Research Project")
        #expect(project.status == .draft)
        #expect(mockRepository.savedProjects.count == 1)
    }

    @Test("Validates project name is not empty")
    func testValidatesProjectName() async {
        let mockRepository = MockProjectRepository()
        let useCase = CreateProjectUseCase(repository: mockRepository)

        let request = CreateProjectRequest(
            name: "",
            description: "Description",
            ownerId: UUID()
        )

        await #expect(throws: ValidationError.self) {
            try await useCase.execute(request)
        }
    }

    @Test("Validates project name length")
    func testValidatesProjectNameLength() async {
        let mockRepository = MockProjectRepository()
        let useCase = CreateProjectUseCase(repository: mockRepository)

        let longName = String(repeating: "a", count: 300)
        let request = CreateProjectRequest(
            name: longName,
            description: "Description",
            ownerId: UUID()
        )

        await #expect(throws: ValidationError.self) {
            try await useCase.execute(request)
        }
    }
}

@Suite("Analyze Capture Use Case Tests")
struct AnalyzeCaptureUseCaseTests {

    @Test("Successfully analyzes capture with ML model")
    func testAnalyzeCapture() async throws {
        let mockMLService = MockMLInferenceService()
        let mockRepository = MockAnalysisRepository()
        let useCase = AnalyzeCaptureUseCase(
            mlService: mockMLService,
            repository: mockRepository
        )

        let captureId = UUID()
        let request = AnalyzeCaptureRequest(
            captureId: captureId,
            modelType: .defectDetection,
            options: AnalysisOptions(
                confidenceThreshold: 0.7,
                maxDetections: 50
            )
        )

        let result = try await useCase.execute(request)

        #expect(result.captureId == captureId)
        #expect(result.detections.isEmpty == false)
        #expect(mockRepository.savedResults.count == 1)
    }

    @Test("Respects confidence threshold")
    func testConfidenceThreshold() async throws {
        let mockMLService = MockMLInferenceService()
        mockMLService.mockDetections = [
            MockDetection(confidence: 0.9, label: "crack"),
            MockDetection(confidence: 0.5, label: "void"),
            MockDetection(confidence: 0.3, label: "scratch")
        ]

        let mockRepository = MockAnalysisRepository()
        let useCase = AnalyzeCaptureUseCase(
            mlService: mockMLService,
            repository: mockRepository
        )

        let request = AnalyzeCaptureRequest(
            captureId: UUID(),
            modelType: .defectDetection,
            options: AnalysisOptions(
                confidenceThreshold: 0.6,
                maxDetections: 50
            )
        )

        let result = try await useCase.execute(request)

        // Only detections above 0.6 threshold should be included
        #expect(result.detections.count == 1)
    }

    @Test("Limits max detections")
    func testMaxDetections() async throws {
        let mockMLService = MockMLInferenceService()
        mockMLService.mockDetections = (1...100).map { i in
            MockDetection(confidence: 0.9, label: "defect_\(i)")
        }

        let mockRepository = MockAnalysisRepository()
        let useCase = AnalyzeCaptureUseCase(
            mlService: mockMLService,
            repository: mockRepository
        )

        let request = AnalyzeCaptureRequest(
            captureId: UUID(),
            modelType: .defectDetection,
            options: AnalysisOptions(
                confidenceThreshold: 0.5,
                maxDetections: 20
            )
        )

        let result = try await useCase.execute(request)

        #expect(result.detections.count <= 20)
    }
}

@Suite("Sync Data Use Case Tests")
struct SyncDataUseCaseTests {

    @Test("Syncs pending changes when online")
    func testSyncWhenOnline() async throws {
        let mockSyncService = MockSyncService()
        mockSyncService.isOnline = true

        let useCase = SyncDataUseCase(syncService: mockSyncService)

        let result = try await useCase.execute()

        #expect(result.syncedItemsCount > 0)
        #expect(result.status == .completed)
    }

    @Test("Queues changes when offline")
    func testQueueWhenOffline() async throws {
        let mockSyncService = MockSyncService()
        mockSyncService.isOnline = false

        let useCase = SyncDataUseCase(syncService: mockSyncService)

        let result = try await useCase.execute()

        #expect(result.status == .queued)
        #expect(mockSyncService.queuedOperations > 0)
    }

    @Test("Handles sync conflicts")
    func testHandleSyncConflicts() async throws {
        let mockSyncService = MockSyncService()
        mockSyncService.isOnline = true
        mockSyncService.simulateConflict = true

        let useCase = SyncDataUseCase(syncService: mockSyncService)

        let result = try await useCase.execute()

        #expect(result.conflicts.isEmpty == false)
        #expect(result.status == .completedWithConflicts)
    }
}

@Suite("Export Data Use Case Tests")
struct ExportDataUseCaseTests {

    @Test("Exports project data to JSON")
    func testExportToJSON() async throws {
        let mockProjectRepo = MockProjectRepository()
        let mockCaptureRepo = MockCaptureRepository()
        let useCase = ExportDataUseCase(
            projectRepository: mockProjectRepo,
            captureRepository: mockCaptureRepo
        )

        let projectId = UUID()
        mockProjectRepo.savedProjects.append(
            Project(
                id: projectId,
                name: "Export Test",
                description: "Test export",
                ownerId: UUID(),
                status: .completed,
                createdAt: Date(),
                updatedAt: Date()
            )
        )

        let request = ExportDataRequest(
            projectId: projectId,
            format: .json,
            includeMedia: false
        )

        let result = try await useCase.execute(request)

        #expect(result.fileURL.pathExtension == "json")
        #expect(result.fileSize > 0)
    }

    @Test("Exports with media files")
    func testExportWithMedia() async throws {
        let mockProjectRepo = MockProjectRepository()
        let mockCaptureRepo = MockCaptureRepository()
        let useCase = ExportDataUseCase(
            projectRepository: mockProjectRepo,
            captureRepository: mockCaptureRepo
        )

        let projectId = UUID()
        mockProjectRepo.savedProjects.append(
            Project(
                id: projectId,
                name: "Media Export Test",
                description: "Test export with media",
                ownerId: UUID(),
                status: .completed,
                createdAt: Date(),
                updatedAt: Date()
            )
        )

        let request = ExportDataRequest(
            projectId: projectId,
            format: .zip,
            includeMedia: true
        )

        let result = try await useCase.execute(request)

        #expect(result.fileURL.pathExtension == "zip")
        #expect(result.includedMediaCount > 0)
    }
}

// MARK: - Mock Objects

final class MockProjectRepository: ProjectRepositoryProtocol, @unchecked Sendable {
    var savedProjects: [Project] = []

    func save(_ project: Project) async throws {
        if let index = savedProjects.firstIndex(where: { $0.id == project.id }) {
            savedProjects[index] = project
        } else {
            savedProjects.append(project)
        }
    }

    func findById(_ id: UUID) async throws -> Project? {
        savedProjects.first { $0.id == id }
    }

    func findByOwner(_ ownerId: UUID) async throws -> [Project] {
        savedProjects.filter { $0.ownerId == ownerId }
    }

    func findByStatus(_ status: ProjectStatus) async throws -> [Project] {
        savedProjects.filter { $0.status == status }
    }

    func delete(_ id: UUID) async throws {
        savedProjects.removeAll { $0.id == id }
    }
}

final class MockAnalysisRepository: @unchecked Sendable {
    var savedResults: [AnalysisResult] = []

    func save(_ result: AnalysisResult) async throws {
        savedResults.append(result)
    }
}

final class MockMLInferenceService: @unchecked Sendable {
    var mockDetections: [MockDetection] = [
        MockDetection(confidence: 0.95, label: "crack"),
        MockDetection(confidence: 0.87, label: "void")
    ]

    func runInference(on imageURL: URL, modelType: MLModelType) async throws -> [Detection] {
        mockDetections.map { mock in
            Detection(
                id: UUID(),
                label: mock.label,
                confidence: mock.confidence,
                boundingBox: CGRect(x: 100, y: 100, width: 50, height: 50)
            )
        }
    }
}

struct MockDetection {
    let confidence: Double
    let label: String
}

final class MockSyncService: @unchecked Sendable {
    var isOnline = true
    var simulateConflict = false
    var queuedOperations = 0

    func sync() async throws -> SyncResult {
        if !isOnline {
            queuedOperations += 1
            return SyncResult(status: .queued, syncedItemsCount: 0, conflicts: [])
        }

        if simulateConflict {
            return SyncResult(
                status: .completedWithConflicts,
                syncedItemsCount: 5,
                conflicts: [SyncConflict(entityId: UUID(), entityType: "Project")]
            )
        }

        return SyncResult(status: .completed, syncedItemsCount: 10, conflicts: [])
    }
}

final class MockCaptureRepository: @unchecked Sendable {
    var captures: [Capture] = []

    func findByProject(_ projectId: UUID) async throws -> [Capture] {
        captures
    }
}
