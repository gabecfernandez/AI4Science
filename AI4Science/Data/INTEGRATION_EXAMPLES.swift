import Foundation
import SwiftData

/// INTEGRATION EXAMPLES
/// Real-world usage patterns for the AI4Science Data Layer

// MARK: - Setup & Initialization

/// Initialize the data layer in your app
class DataLayerManager {
    static let shared = DataLayerManager()

    let modelContainer: ModelContainer
    let userRepository: UserRepository
    let projectRepository: ProjectRepository
    let sampleRepository: SampleRepository
    let captureRepository: CaptureRepository
    let analysisRepository: AnalysisRepository
    let syncQueueRepository: SyncQueueRepository

    init() {
        do {
            // Create the model container
            self.modelContainer = try ModelContainer.makeAI4ScienceContainer()

            // Create repositories
            let context = ModelContext(modelContainer)
            self.userRepository = UserRepository(modelContext: context)
            self.projectRepository = ProjectRepository(modelContext: context)
            self.sampleRepository = SampleRepository(modelContext: context)
            self.captureRepository = CaptureRepository(modelContext: context)
            self.analysisRepository = AnalysisRepository(modelContext: context)
            self.syncQueueRepository = SyncQueueRepository(modelContext: context)
        } catch {
            fatalError("Failed to initialize data layer: \(error)")
        }
    }
}

// MARK: - User Management Example

actor UserManagementExample {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    /// Example: Create a new user
    func createNewUser() async throws {
        let newUser = UserEntity(
            id: UUID().uuidString,
            email: "researcher@ai4science.com",
            fullName: "Dr. Jane Smith",
            institution: "Stanford University"
        )

        try await userRepository.createUser(newUser)
    }

    /// Example: Get current user and update profile
    func updateUserProfile() async throws {
        guard let user = try await userRepository.getUser(id: "user123") else {
            throw RepositoryError.notFound
        }

        user.updateInfo(
            fullName: "Dr. Jane Smith",
            institution: "MIT",
            profileImageURL: "https://example.com/profile.jpg"
        )

        try await userRepository.updateUser(user)
    }

    /// Example: Fetch user by email
    func fetchUserByEmail(_ email: String) async throws {
        let user = try await userRepository.getUserByEmail(email)
        // Use user...
    }
}

// MARK: - Project Management Example

actor ProjectManagementExample {
    private let projectRepository: ProjectRepository
    private let userRepository: UserRepository

    init(
        projectRepository: ProjectRepository,
        userRepository: UserRepository
    ) {
        self.projectRepository = projectRepository
        self.userRepository = userRepository
    }

    /// Example: Create project with owner
    func createResearchProject() async throws {
        guard let owner = try await userRepository.getUser(id: "user123") else {
            throw RepositoryError.notFound
        }

        let project = ProjectEntity(
            id: UUID().uuidString,
            name: "Tissue Sample Analysis",
            description: "Analysis of cancer tissue samples",
            owner: owner,
            projectType: "histology"
        )

        try await projectRepository.createProject(project)
    }

    /// Example: Archive old projects
    func archiveOldProjects() async throws {
        let allProjects = try await projectRepository.getAllProjects()

        for project in allProjects {
            let sixMonthsAgo = Calendar.current.date(
                byAdding: .month,
                value: -6,
                to: Date()
            )!

            if project.updatedAt < sixMonthsAgo {
                try await projectRepository.archiveProject(id: project.id)
            }
        }
    }

    /// Example: Search projects
    func findMicroscopyProjects() async throws {
        let results = try await projectRepository.searchProjects(
            query: "microscopy"
        )

        for project in results {
            print("Found: \(project.name)")
        }
    }

    /// Example: Add collaborator
    func shareProjectWithCollaborator() async throws {
        guard let project = try await projectRepository.getProject(id: "proj123") else {
            throw RepositoryError.notFound
        }

        project.addCollaborator("colleague@ai4science.com")
        try await projectRepository.updateProject(project)
    }
}

// MARK: - Sample & Capture Management Example

actor SampleCaptureExample {
    private let sampleRepository: SampleRepository
    private let captureRepository: CaptureRepository
    private let projectRepository: ProjectRepository

    init(
        sampleRepository: SampleRepository,
        captureRepository: CaptureRepository,
        projectRepository: ProjectRepository
    ) {
        self.sampleRepository = sampleRepository
        self.captureRepository = captureRepository
        self.projectRepository = projectRepository
    }

    /// Example: Create sample and associate captures
    func createSampleWithCaptures() async throws {
        guard let project = try await projectRepository.getProject(id: "proj123") else {
            throw RepositoryError.notFound
        }

        // Create sample
        let sample = SampleEntity(
            id: UUID().uuidString,
            name: "Tissue Sample #1",
            description: "Biopsy from patient A",
            project: project,
            sampleType: "tissue",
            source: "Patient A - Biopsy",
            collectionDate: Date()
        )

        try await sampleRepository.createSample(sample)

        // Create captures for the sample
        let capture = CaptureEntity(
            id: UUID().uuidString,
            sample: sample,
            captureType: "microscopy_image",
            fileURL: "/documents/samples/\(sample.id)/capture_001.tiff",
            mimeType: "image/tiff",
            capturedAt: Date()
        )

        capture.fileSize = 5_242_880 // 5 MB
        capture.addCameraSetting(key: "magnification", value: "40x")
        capture.addCameraSetting(key: "wavelength", value: "532nm")

        try await captureRepository.createCapture(capture)
    }

    /// Example: Get all samples for project with their captures
    func loadProjectSamples(projectID: String) async throws {
        let samples = try await sampleRepository.getSamplesByProject(
            projectID: projectID
        )

        for sample in samples {
            let captures = try await captureRepository.getCapturesBySample(
                sampleID: sample.id
            )
            print("Sample: \(sample.name) has \(captures.count) captures")
        }
    }

    /// Example: Flag sample for review
    func flagSampleForReview() async throws {
        try await sampleRepository.flagSample(id: "sample123")
    }
}

// MARK: - Analysis & ML Model Example

actor AnalysisExample {
    private let analysisRepository: AnalysisRepository
    private let captureRepository: CaptureRepository
    private let mlModelRepository: MLModelRepository

    init(
        analysisRepository: AnalysisRepository,
        captureRepository: CaptureRepository,
        mlModelRepository: MLModelRepository
    ) {
        self.analysisRepository = analysisRepository
        self.captureRepository = captureRepository
        self.mlModelRepository = mlModelRepository
    }

    /// Example: Run analysis on capture
    func analyzeCapture(captureID: String, modelID: String) async throws {
        guard let capture = try await captureRepository.getCapture(id: captureID) else {
            throw RepositoryError.notFound
        }

        guard let model = try await mlModelRepository.getModel(id: modelID) else {
            throw RepositoryError.notFound
        }

        // Create analysis result
        let result = AnalysisResultEntity(
            id: UUID().uuidString,
            capture: capture,
            modelID: model.id,
            modelName: model.name,
            modelVersion: model.version,
            analysisType: "cell_segmentation",
            resultData: "{}"
        )

        result.markInProgress()
        try await analysisRepository.createAnalysisResult(result)

        // Simulate analysis
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Update with results
        result.markCompleted(
            resultData: #"{"cells": 42, "avg_size": 150}"#,
            confidenceScore: 0.95,
            objectCount: 42
        )

        try await analysisRepository.updateAnalysisResult(result)
    }

    /// Example: Get analysis history
    func getAnalysisHistory(captureID: String) async throws {
        let results = try await analysisRepository.getAnalysisResultsByCapture(
            captureID: captureID
        )

        for result in results {
            print("Analysis: \(result.modelName) - \(result.status)")
            if let confidence = result.confidenceScore {
                print("Confidence: \(confidence * 100)%")
            }
        }
    }

    /// Example: Download and configure ML model
    func downloadModel(modelID: String) async throws {
        try await mlModelRepository.updateDownloadStatus(
            modelID: modelID,
            status: "downloading",
            progress: 0.0
        )

        // Simulate download with progress updates
        for progress in stride(from: 0.1, through: 1.0, by: 0.1) {
            try await Task.sleep(nanoseconds: 500_000_000)
            try await mlModelRepository.updateDownloadStatus(
                modelID: modelID,
                status: "downloading",
                progress: progress
            )
        }

        try await mlModelRepository.markModelDownloadComplete(
            modelID: modelID,
            localPath: "/models/\(modelID)/model.mlmodel"
        )
    }
}

// MARK: - Offline Sync Example

actor OfflineSyncExample {
    private let syncQueueRepository: SyncQueueRepository
    private let projectRepository: ProjectRepository

    init(
        syncQueueRepository: SyncQueueRepository,
        projectRepository: ProjectRepository
    ) {
        self.syncQueueRepository = syncQueueRepository
        self.projectRepository = projectRepository
    }

    /// Example: Queue operation for offline sync
    func queueOfflineProjectCreation(name: String) async throws {
        let operationData = """
        {
            "name": "\(name)",
            "description": "Created offline",
            "projectType": "general"
        }
        """

        let queueEntry = SyncQueueEntity(
            id: UUID().uuidString,
            operationType: "create",
            entityType: "project",
            entityID: UUID().uuidString,
            operationData: operationData
        )

        queueEntry.priority = 8 // High priority
        try await syncQueueRepository.addToQueue(queueEntry)
    }

    /// Example: Process sync queue
    func processSyncQueue() async throws {
        let pendingEntries = try await syncQueueRepository.getPendingQueue()

        for entry in pendingEntries {
            do {
                entry.markInProgress()
                try await syncQueueRepository.updateQueueEntry(entry)

                // Simulate API call
                try await Task.sleep(nanoseconds: 1_000_000_000)

                entry.markSynced()
                try await syncQueueRepository.updateQueueEntry(entry)
            } catch {
                entry.markFailedWithRetry(errorMessage: error.localizedDescription)
                try await syncQueueRepository.updateQueueEntry(entry)

                // Wait before retry using exponential backoff
                try await Task.sleep(nanoseconds: UInt64(entry.retryWaitTime * 1_000_000_000))
            }
        }
    }

    /// Example: Get failed sync entries for manual review
    func getFailedSyncEntries() async throws {
        let failed = try await syncQueueRepository.getFailedEntries()

        for entry in failed {
            print("Failed: \(entry.operationType) on \(entry.entityType)")
            print("Error: \(entry.errorMessage ?? "Unknown")")
            print("Retries: \(entry.retryCount)/\(entry.maxRetries)")
        }
    }
}

// MARK: - Mapper Usage Example

actor MapperExample {
    /// Example: Convert between layers
    func demonstrateMapping() {
        // Create a domain model
        var userDomain = User(
            id: "user123",
            email: "user@example.com",
            fullName: "John Doe"
        )

        // Map to entity for persistence
        let userEntity = UserMapper.toEntity(from: userDomain)

        // Map entity to DTO for API
        let userDTO = UserMapper.toDTO(userEntity)

        // Update domain model
        userDomain.institution = "Stanford"

        // Update entity from domain
        UserMapper.update(userEntity, with: userDomain)

        // Map back to domain
        let updatedDomain = UserMapper.toModel(userEntity)
    }
}

// MARK: - Comprehensive Workflow Example

actor CompleteWorkflow {
    private let dataLayerManager = DataLayerManager.shared

    /// Example: Complete workflow from project creation to analysis
    func completeResearchWorkflow() async throws {
        // 1. Create user
        let user = UserEntity(
            id: UUID().uuidString,
            email: "researcher@ai4science.com",
            fullName: "Dr. Smith"
        )
        try await dataLayerManager.userRepository.createUser(user)

        // 2. Create project
        let project = ProjectEntity(
            id: UUID().uuidString,
            name: "Cancer Research",
            description: "Tissue analysis project",
            owner: user,
            projectType: "histology"
        )
        try await dataLayerManager.projectRepository.createProject(project)

        // 3. Create samples
        let sample = SampleEntity(
            id: UUID().uuidString,
            name: "Sample 1",
            description: "Tumor sample",
            project: project,
            sampleType: "tissue"
        )
        try await dataLayerManager.sampleRepository.createSample(sample)

        // 4. Add captures
        let capture = CaptureEntity(
            id: UUID().uuidString,
            sample: sample,
            captureType: "microscopy_image",
            fileURL: "/data/capture_001.tiff",
            mimeType: "image/tiff"
        )
        capture.fileSize = 5_242_880
        try await dataLayerManager.captureRepository.createCapture(capture)

        // 5. Run analysis
        let result = AnalysisResultEntity(
            id: UUID().uuidString,
            capture: capture,
            modelID: "model123",
            modelName: "Cell Detector",
            modelVersion: "1.0",
            analysisType: "cell_segmentation",
            resultData: "{\"cells\": 42}"
        )
        result.markCompleted(resultData: "{\"cells\": 42}", objectCount: 42)
        try await dataLayerManager.analysisRepository.createAnalysisResult(result)

        print("Workflow complete!")
    }
}
