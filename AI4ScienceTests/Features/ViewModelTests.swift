//
//  ViewModelTests.swift
//  AI4ScienceTests
//
//  Created for AI4Science UTSA
//

import Testing
import Foundation
@testable import AI4Science

@Suite("Auth View Model Tests")
@MainActor
struct AuthViewModelTests {

    @Test("Login view model initializes with empty state")
    func testInitialState() {
        let viewModel = LoginViewModel()

        #expect(viewModel.email.isEmpty)
        #expect(viewModel.password.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Login validates email format")
    func testEmailValidation() {
        let viewModel = LoginViewModel()

        viewModel.email = "invalid-email"
        let isValid = viewModel.isEmailValid

        #expect(isValid == false)

        viewModel.email = "valid@utsa.edu"
        let isValidNow = viewModel.isEmailValid

        #expect(isValidNow == true)
    }

    @Test("Login validates password length")
    func testPasswordValidation() {
        let viewModel = LoginViewModel()

        viewModel.password = "short"
        let isValid = viewModel.isPasswordValid

        #expect(isValid == false)

        viewModel.password = "longenoughpassword"
        let isValidNow = viewModel.isPasswordValid

        #expect(isValidNow == true)
    }

    @Test("Login enables submit when form is valid")
    func testFormValidation() {
        let viewModel = LoginViewModel()

        viewModel.email = "test@utsa.edu"
        viewModel.password = "validpassword123"

        #expect(viewModel.canSubmit == true)
    }

    @Test("Login performs authentication")
    func testLogin() async {
        let mockAuthService = MockAuthService()
        let viewModel = LoginViewModel(authService: mockAuthService)

        viewModel.email = "test@utsa.edu"
        viewModel.password = "password123"

        await viewModel.login()

        #expect(mockAuthService.loginCalled == true)
        #expect(viewModel.isAuthenticated == true)
    }

    @Test("Login handles authentication failure")
    func testLoginFailure() async {
        let mockAuthService = MockAuthService()
        mockAuthService.shouldFail = true

        let viewModel = LoginViewModel(authService: mockAuthService)

        viewModel.email = "test@utsa.edu"
        viewModel.password = "wrongpassword"

        await viewModel.login()

        #expect(viewModel.isAuthenticated == false)
        #expect(viewModel.errorMessage != nil)
    }
}

@Suite("Projects View Model Tests")
@MainActor
struct ProjectsViewModelTests {

    @Test("Projects view model loads projects")
    func testLoadProjects() async {
        let mockRepository = MockProjectRepository()
        mockRepository.savedProjects = [
            Project(id: UUID(), name: "Project 1", description: "Desc 1",
                   ownerId: UUID(), status: .active, createdAt: Date(), updatedAt: Date()),
            Project(id: UUID(), name: "Project 2", description: "Desc 2",
                   ownerId: UUID(), status: .draft, createdAt: Date(), updatedAt: Date())
        ]

        let viewModel = ProjectsViewModel(repository: mockRepository)
        await viewModel.loadProjects()

        #expect(viewModel.projects.count == 2)
    }

    @Test("Projects view model filters by status")
    func testFilterProjects() async {
        let mockRepository = MockProjectRepository()
        mockRepository.savedProjects = [
            Project(id: UUID(), name: "Active", description: "",
                   ownerId: UUID(), status: .active, createdAt: Date(), updatedAt: Date()),
            Project(id: UUID(), name: "Draft", description: "",
                   ownerId: UUID(), status: .draft, createdAt: Date(), updatedAt: Date()),
            Project(id: UUID(), name: "Active 2", description: "",
                   ownerId: UUID(), status: .active, createdAt: Date(), updatedAt: Date())
        ]

        let viewModel = ProjectsViewModel(repository: mockRepository)
        await viewModel.loadProjects()

        viewModel.filterStatus = .active

        #expect(viewModel.filteredProjects.count == 2)
    }

    @Test("Projects view model searches by name")
    func testSearchProjects() async {
        let mockRepository = MockProjectRepository()
        mockRepository.savedProjects = [
            Project(id: UUID(), name: "Materials Analysis", description: "",
                   ownerId: UUID(), status: .active, createdAt: Date(), updatedAt: Date()),
            Project(id: UUID(), name: "Defect Detection", description: "",
                   ownerId: UUID(), status: .active, createdAt: Date(), updatedAt: Date()),
            Project(id: UUID(), name: "Material Testing", description: "",
                   ownerId: UUID(), status: .active, createdAt: Date(), updatedAt: Date())
        ]

        let viewModel = ProjectsViewModel(repository: mockRepository)
        await viewModel.loadProjects()

        viewModel.searchText = "Material"

        #expect(viewModel.filteredProjects.count == 2)
    }

    @Test("Projects view model deletes project")
    func testDeleteProject() async {
        let mockRepository = MockProjectRepository()
        let projectId = UUID()
        mockRepository.savedProjects = [
            Project(id: projectId, name: "To Delete", description: "",
                   ownerId: UUID(), status: .draft, createdAt: Date(), updatedAt: Date())
        ]

        let viewModel = ProjectsViewModel(repository: mockRepository)
        await viewModel.loadProjects()

        await viewModel.deleteProject(id: projectId)

        #expect(viewModel.projects.isEmpty)
    }
}

@Suite("Capture View Model Tests")
@MainActor
struct CaptureViewModelTests {

    @Test("Capture view model initializes camera")
    func testCameraInitialization() async {
        let mockCameraManager = MockCameraManager()
        let viewModel = CaptureViewModel(cameraManager: mockCameraManager)

        await viewModel.setupCamera()

        #expect(mockCameraManager.setupCalled == true)
    }

    @Test("Capture view model takes photo")
    func testTakePhoto() async {
        let mockCameraManager = MockCameraManager()
        let viewModel = CaptureViewModel(cameraManager: mockCameraManager)

        await viewModel.capturePhoto()

        #expect(mockCameraManager.photoTaken == true)
        #expect(viewModel.capturedPhotos.count == 1)
    }

    @Test("Capture view model starts video recording")
    func testStartRecording() async {
        let mockCameraManager = MockCameraManager()
        let viewModel = CaptureViewModel(cameraManager: mockCameraManager)

        await viewModel.startVideoRecording()

        #expect(viewModel.isRecording == true)
        #expect(mockCameraManager.recordingStarted == true)
    }

    @Test("Capture view model stops video recording")
    func testStopRecording() async {
        let mockCameraManager = MockCameraManager()
        let viewModel = CaptureViewModel(cameraManager: mockCameraManager)

        await viewModel.startVideoRecording()
        await viewModel.stopVideoRecording()

        #expect(viewModel.isRecording == false)
        #expect(viewModel.capturedVideos.count == 1)
    }

    @Test("Capture view model switches camera")
    func testSwitchCamera() async {
        let mockCameraManager = MockCameraManager()
        let viewModel = CaptureViewModel(cameraManager: mockCameraManager)

        await viewModel.switchCamera()

        #expect(mockCameraManager.cameraSwitched == true)
    }

    @Test("Capture view model toggles flash")
    func testToggleFlash() async {
        let mockCameraManager = MockCameraManager()
        let viewModel = CaptureViewModel(cameraManager: mockCameraManager)

        viewModel.flashMode = .off
        viewModel.toggleFlash()

        #expect(viewModel.flashMode == .on)

        viewModel.toggleFlash()

        #expect(viewModel.flashMode == .auto)
    }
}

@Suite("Analysis View Model Tests")
@MainActor
struct AnalysisViewModelTests {

    @Test("Analysis view model runs ML analysis")
    func testRunAnalysis() async {
        let mockMLService = MockMLService()
        let viewModel = AnalysisViewModel(mlService: mockMLService)

        let captureId = UUID()
        await viewModel.analyzeCapture(captureId)

        #expect(mockMLService.analysisCalled == true)
        #expect(viewModel.analysisResults != nil)
    }

    @Test("Analysis view model shows loading state")
    func testLoadingState() async {
        let mockMLService = MockMLService()
        mockMLService.delay = 1.0 // Add delay to observe loading state

        let viewModel = AnalysisViewModel(mlService: mockMLService)

        let task = Task {
            await viewModel.analyzeCapture(UUID())
        }

        // Give time for the task to start
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.isAnalyzing == true)

        await task.value

        #expect(viewModel.isAnalyzing == false)
    }

    @Test("Analysis view model filters detections by confidence")
    func testFilterByConfidence() async {
        let mockMLService = MockMLService()
        mockMLService.mockResults = [
            Detection(id: UUID(), label: "crack", confidence: 0.95,
                     boundingBox: .zero),
            Detection(id: UUID(), label: "void", confidence: 0.6,
                     boundingBox: .zero),
            Detection(id: UUID(), label: "scratch", confidence: 0.4,
                     boundingBox: .zero)
        ]

        let viewModel = AnalysisViewModel(mlService: mockMLService)
        await viewModel.analyzeCapture(UUID())

        viewModel.confidenceThreshold = 0.7

        #expect(viewModel.filteredDetections.count == 1)
    }

    @Test("Analysis view model exports results")
    func testExportResults() async {
        let mockMLService = MockMLService()
        let viewModel = AnalysisViewModel(mlService: mockMLService)

        await viewModel.analyzeCapture(UUID())
        let exportURL = try? await viewModel.exportResults(format: .json)

        #expect(exportURL != nil)
    }
}

// MARK: - Mock Objects

final class MockAuthService: @unchecked Sendable {
    var loginCalled = false
    var shouldFail = false

    func login(email: String, password: String) async throws -> User {
        loginCalled = true
        if shouldFail {
            throw AuthError.invalidCredentials
        }
        return User(
            id: UUID(),
            email: email,
            displayName: "Test User",
            role: .researcher,
            labAffiliation: nil
        )
    }
}

enum AuthError: Error {
    case invalidCredentials
}

final class MockCameraManager: @unchecked Sendable {
    var setupCalled = false
    var photoTaken = false
    var recordingStarted = false
    var cameraSwitched = false

    func setup() async {
        setupCalled = true
    }

    func takePhoto() async -> Data {
        photoTaken = true
        return Data()
    }

    func startRecording() async {
        recordingStarted = true
    }

    func stopRecording() async -> URL {
        return URL(fileURLWithPath: "/test/video.mov")
    }

    func switchCamera() async {
        cameraSwitched = true
    }
}

final class MockMLService: @unchecked Sendable {
    var analysisCalled = false
    var delay: TimeInterval = 0
    var mockResults: [Detection] = [
        Detection(id: UUID(), label: "defect", confidence: 0.9, boundingBox: .zero)
    ]

    func analyze(captureId: UUID) async -> [Detection] {
        analysisCalled = true
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        return mockResults
    }
}

struct Detection: Identifiable, Sendable {
    let id: UUID
    let label: String
    let confidence: Double
    let boundingBox: CGRect
}
