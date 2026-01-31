import Foundation
import Observation

protocol CameraManagerProtocol: Sendable {
    func setup() async
    func takePhoto() async -> Data
    func startRecording() async
    func stopRecording() async -> URL
    func switchCamera() async
}

@Observable
@MainActor
final class CaptureViewModel {
    var capturedPhotos: [Data] = []
    var capturedVideos: [URL] = []
    var isRecording = false
    var flashMode: FlashMode = .off

    private let cameraManager: any CameraManagerProtocol

    init(cameraManager: any CameraManagerProtocol) {
        self.cameraManager = cameraManager
    }

    func setupCamera() async {
        await cameraManager.setup()
    }

    func capturePhoto() async {
        let photoData = await cameraManager.takePhoto()
        capturedPhotos.append(photoData)
    }

    func startVideoRecording() async {
        isRecording = true
        await cameraManager.startRecording()
    }

    func stopVideoRecording() async {
        let videoURL = await cameraManager.stopRecording()
        capturedVideos.append(videoURL)
        isRecording = false
    }

    func switchCamera() async {
        await cameraManager.switchCamera()
    }

    func toggleFlash() {
        switch flashMode {
        case .off:
            flashMode = .on
        case .on:
            flashMode = .auto
        case .auto:
            flashMode = .off
        }
    }
}
