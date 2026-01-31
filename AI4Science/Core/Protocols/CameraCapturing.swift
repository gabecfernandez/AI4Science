import Foundation
import AVFoundation

/// Protocol for camera capture operations
public protocol CameraCapturing: Sendable {
    /// Request camera permissions
    func requestPermission() async -> Bool

    /// Check if camera is available
    func isCameraAvailable() async -> Bool

    /// Start camera preview
    func startPreview() async throws

    /// Stop camera preview
    func stopPreview() async throws

    /// Capture a single photo
    func capturePhoto() async throws -> CaptureData

    /// Start video recording
    func startVideoRecording() async throws

    /// Stop video recording
    func stopVideoRecording() async throws -> CaptureData

    /// Get available camera devices
    func getAvailableCameras() async -> [CameraDevice]

    /// Switch to specific camera
    func switchCamera(to device: CameraDevice) async throws

    /// Get camera capabilities
    func getCameraCapabilities() async -> CameraCapabilities

    /// Set focus mode
    func setFocusMode(_ mode: FocusMode) async throws

    /// Set exposure
    func setExposure(_ exposure: Double) async throws

    /// Set white balance
    func setWhiteBalance(_ mode: WhiteBalanceMode) async throws

    /// Zoom camera
    func setZoom(_ factor: CGFloat) async throws
}

/// Captured image/video data
public struct CaptureData: Sendable {
    public let mediaType: CaptureType
    public let data: Data
    public let metadata: CaptureMetadata

    public init(mediaType: CaptureType, data: Data, metadata: CaptureMetadata) {
        self.mediaType = mediaType
        self.data = data
        self.metadata = metadata
    }
}

/// Camera device
public struct CameraDevice: Identifiable, Sendable {
    public let id: String
    public var position: AVCaptureDevice.Position
    public var name: String

    public init(id: String, position: AVCaptureDevice.Position, name: String) {
        self.id = id
        self.position = position
        self.name = name
    }
}

/// Camera capabilities
public struct CameraCapabilities: Sendable {
    public var hasFlash: Bool
    public var hasAutoFocus: Bool
    public var maxZoom: CGFloat
    public var supportedWhiteBalanceModes: [WhiteBalanceMode]
    public var supportedFocusModes: [FocusMode]

    public init(
        hasFlash: Bool,
        hasAutoFocus: Bool,
        maxZoom: CGFloat,
        supportedWhiteBalanceModes: [WhiteBalanceMode],
        supportedFocusModes: [FocusMode]
    ) {
        self.hasFlash = hasFlash
        self.hasAutoFocus = hasAutoFocus
        self.maxZoom = maxZoom
        self.supportedWhiteBalanceModes = supportedWhiteBalanceModes
        self.supportedFocusModes = supportedFocusModes
    }
}

/// Focus mode
@frozen
public enum FocusMode: String, Codable, Sendable, CaseIterable {
    case autoFocus
    case continuousAutoFocus
    case locked
    case macro
}

/// White balance mode
@frozen
public enum WhiteBalanceMode: String, Codable, Sendable, CaseIterable {
    case autoWhiteBalance
    case daylight
    case cloudy
    case tungsten
    case fluorescent
    case twilight
}
