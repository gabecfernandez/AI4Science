//
//  CameraServiceTests.swift
//  AI4ScienceTests
//
//  Created for AI4Science UTSA
//

import Testing
import Foundation
import AVFoundation
@testable import AI4Science

@Suite("Camera Manager Tests")
struct CameraManagerTests {

    @Test("Camera manager initializes with default settings")
    func testDefaultInitialization() async {
        let manager = await CameraManager()

        let isRunning = await manager.isSessionRunning
        #expect(isRunning == false)
    }

    @Test("Camera manager requests permissions")
    func testPermissionRequest() async {
        let mockPermissionService = MockCameraPermissionService()
        let manager = await CameraManager(permissionService: mockPermissionService)

        let granted = await manager.requestPermission()

        #expect(mockPermissionService.permissionRequested == true)
        #expect(granted == true)
    }

    @Test("Camera manager switches between cameras")
    func testCameraSwitch() async throws {
        let manager = await CameraManager()

        let initialPosition = await manager.currentCameraPosition
        try await manager.switchCamera()
        let newPosition = await manager.currentCameraPosition

        #expect(initialPosition != newPosition)
    }

    @Test("Camera manager configures capture settings")
    func testCaptureSettings() async throws {
        let manager = await CameraManager()

        let settings = CaptureSettings(
            photoQuality: .high,
            flashMode: .auto,
            hdrEnabled: true,
            rawCaptureEnabled: false
        )

        try await manager.configure(settings)

        let currentSettings = await manager.currentSettings
        #expect(currentSettings.photoQuality == .high)
        #expect(currentSettings.hdrEnabled == true)
    }
}

@Suite("Photo Capture Service Tests")
struct PhotoCaptureServiceTests {

    @Test("Photo capture service takes photo")
    func testPhotoCapture() async throws {
        let mockCaptureDelegate = MockPhotoCaptureDelegate()
        let service = PhotoCaptureService(delegate: mockCaptureDelegate)

        let settings = PhotoCaptureSettings(
            flashMode: .off,
            qualityPrioritization: .balanced
        )

        try await service.capturePhoto(with: settings)

        #expect(mockCaptureDelegate.photoCaptured == true)
    }

    @Test("Photo capture handles RAW format")
    func testRAWCapture() async throws {
        let mockCaptureDelegate = MockPhotoCaptureDelegate()
        let service = PhotoCaptureService(delegate: mockCaptureDelegate)

        let settings = PhotoCaptureSettings(
            flashMode: .off,
            rawEnabled: true,
            qualityPrioritization: .quality
        )

        try await service.capturePhoto(with: settings)

        #expect(mockCaptureDelegate.rawDataReceived == true)
    }

    @Test("Photo capture supports burst mode")
    func testBurstCapture() async throws {
        let mockCaptureDelegate = MockPhotoCaptureDelegate()
        let service = PhotoCaptureService(delegate: mockCaptureDelegate)

        let photos = try await service.captureBurst(count: 5)

        #expect(photos.count == 5)
    }
}

@Suite("Video Capture Service Tests")
struct VideoCaptureServiceTests {

    @Test("Video capture service starts recording")
    func testStartRecording() async throws {
        let service = VideoCaptureService()

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_video.mov")

        try await service.startRecording(to: outputURL)

        let isRecording = await service.isRecording
        #expect(isRecording == true)
    }

    @Test("Video capture service stops recording")
    func testStopRecording() async throws {
        let service = VideoCaptureService()

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_video.mov")

        try await service.startRecording(to: outputURL)
        let result = try await service.stopRecording()

        #expect(result.fileURL == outputURL)
        #expect(result.duration > 0)
    }

    @Test("Video capture respects quality settings")
    func testVideoQuality() async throws {
        let service = VideoCaptureService()

        let settings = VideoRecordingSettings(
            quality: .hd1080p,
            frameRate: 60,
            stabilizationMode: .cinematic
        )

        try await service.configure(settings)

        let currentSettings = await service.currentSettings
        #expect(currentSettings.quality == .hd1080p)
        #expect(currentSettings.frameRate == 60)
    }

    @Test("Video capture supports pause and resume")
    func testPauseResume() async throws {
        let service = VideoCaptureService()

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_video.mov")

        try await service.startRecording(to: outputURL)
        await service.pauseRecording()

        let isPaused = await service.isPaused
        #expect(isPaused == true)

        await service.resumeRecording()

        let isPausedAfterResume = await service.isPaused
        #expect(isPausedAfterResume == false)
    }
}

@Suite("Camera Configuration Service Tests")
struct CameraConfigurationServiceTests {

    @Test("Configuration service sets focus point")
    func testFocusPoint() async throws {
        let service = CameraConfigurationService()

        let focusPoint = CGPoint(x: 0.5, y: 0.5)
        try await service.setFocusPoint(focusPoint)

        let currentFocus = await service.currentFocusPoint
        #expect(currentFocus == focusPoint)
    }

    @Test("Configuration service sets exposure")
    func testExposure() async throws {
        let service = CameraConfigurationService()

        try await service.setExposureCompensation(1.5)

        let exposure = await service.currentExposureCompensation
        #expect(exposure == 1.5)
    }

    @Test("Configuration service sets zoom level")
    func testZoom() async throws {
        let service = CameraConfigurationService()

        try await service.setZoomFactor(2.0)

        let zoom = await service.currentZoomFactor
        #expect(zoom == 2.0)
    }

    @Test("Configuration service validates zoom range")
    func testZoomRange() async throws {
        let service = CameraConfigurationService()

        // Should clamp to valid range
        try await service.setZoomFactor(100.0)

        let zoom = await service.currentZoomFactor
        let maxZoom = await service.maxZoomFactor
        #expect(zoom <= maxZoom)
    }

    @Test("Configuration service toggles torch")
    func testTorch() async throws {
        let service = CameraConfigurationService()

        try await service.setTorchMode(.on)

        let torchMode = await service.currentTorchMode
        #expect(torchMode == .on)
    }
}

// MARK: - Mock Objects

final class MockCameraPermissionService: @unchecked Sendable {
    var permissionRequested = false
    var grantPermission = true

    func requestPermission() async -> Bool {
        permissionRequested = true
        return grantPermission
    }
}

final class MockPhotoCaptureDelegate: @unchecked Sendable {
    var photoCaptured = false
    var rawDataReceived = false
    var capturedPhotos: [Data] = []

    func didCapturePhoto(_ data: Data) {
        photoCaptured = true
        capturedPhotos.append(data)
    }

    func didCaptureRAW(_ data: Data) {
        rawDataReceived = true
    }
}

// MARK: - Test Helpers

struct CaptureSettings: Sendable {
    let photoQuality: PhotoQuality
    let flashMode: FlashMode
    let hdrEnabled: Bool
    let rawCaptureEnabled: Bool
}

enum PhotoQuality: Sendable {
    case low, medium, high, maximum
}

enum FlashMode: Sendable {
    case off, on, auto
}

struct PhotoCaptureSettings: Sendable {
    let flashMode: FlashMode
    var rawEnabled: Bool = false
    let qualityPrioritization: QualityPrioritization
}

enum QualityPrioritization: Sendable {
    case speed, balanced, quality
}

struct VideoRecordingSettings: Sendable {
    let quality: VideoQuality
    let frameRate: Int
    let stabilizationMode: StabilizationMode
}

enum VideoQuality: Sendable {
    case hd720p, hd1080p, uhd4k
}

enum StabilizationMode: Sendable {
    case off, standard, cinematic
}

struct VideoRecordingResult: Sendable {
    let fileURL: URL
    let duration: TimeInterval
}
