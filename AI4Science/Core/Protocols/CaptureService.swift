import Foundation
import AVFoundation

/// Camera position for capture
@frozen
public enum CameraPosition: String, Sendable, Codable, Hashable {
    case front
    case back
}

/// Photo flash mode
@frozen
public enum FlashMode: String, Sendable, Codable, Hashable {
    case off
    case on
    case auto
}

/// Video quality setting
@frozen
public enum VideoQuality: String, Sendable, Codable, Hashable {
    case low
    case medium
    case high
}

/// Protocol for camera capture operations
public protocol CaptureService: Sendable {
    /// Check if camera is available
    /// - Returns: True if camera is available
    func isCameraAvailable() async throws -> Bool

    /// Request camera permission
    /// - Returns: True if permission granted
    func requestCameraPermission() async throws -> Bool

    /// Check current camera permission status
    /// - Returns: Permission status
    func getCameraPermissionStatus() async throws -> AVAuthorizationStatus

    /// Check if microphone is available
    /// - Returns: True if microphone is available
    func isMicrophoneAvailable() async throws -> Bool

    /// Request microphone permission
    /// - Returns: True if permission granted
    func requestMicrophonePermission() async throws -> Bool

    /// Capture a photo
    /// - Parameters:
    ///   - cameraPosition: Which camera to use
    ///   - flashMode: Flash mode to use
    /// - Returns: Photo data and metadata
    func capturePhoto(
        cameraPosition: CameraPosition,
        flashMode: FlashMode
    ) async throws -> (data: Data, metadata: [String: String])

    /// Start video recording
    /// - Parameters:
    ///   - cameraPosition: Which camera to use
    ///   - quality: Video quality setting
    /// - Returns: Recording session ID
    func startVideoRecording(
        cameraPosition: CameraPosition,
        quality: VideoQuality
    ) async throws -> UUID

    /// Stop video recording
    /// - Parameter sessionId: The recording session ID
    /// - Returns: Video data and metadata
    func stopVideoRecording(sessionId: UUID) async throws -> (data: Data, metadata: [String: String])

    /// Get available cameras
    /// - Returns: Array of available camera positions
    func getAvailableCameras() async throws -> [CameraPosition]

    /// Get torch availability
    /// - Returns: True if torch is available
    func isTorchAvailable() async throws -> Bool

    /// Enable/disable torch
    /// - Parameter enabled: Whether to enable torch
    func setTorchEnabled(_ enabled: Bool) async throws
}
