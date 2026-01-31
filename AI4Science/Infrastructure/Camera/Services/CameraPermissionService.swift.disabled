import AVFoundation
import os.log

/// Service for managing camera and microphone permissions
actor CameraPermissionService {
    static let shared = CameraPermissionService()

    private let logger = Logger(subsystem: "com.ai4science.camera", category: "CameraPermissionService")

    enum PermissionStatus {
        case notDetermined
        case restricted
        case denied
        case authorized

        var description: String {
            switch self {
            case .notDetermined:
                return "Not Determined"
            case .restricted:
                return "Restricted"
            case .denied:
                return "Denied"
            case .authorized:
                return "Authorized"
            }
        }
    }

    enum PermissionError: LocalizedError {
        case cameraPermissionDenied
        case microphonePermissionDenied
        case restrictedByPolicy

        var errorDescription: String? {
            switch self {
            case .cameraPermissionDenied:
                return "Camera access is denied. Please enable camera access in Settings."
            case .microphonePermissionDenied:
                return "Microphone access is denied. Please enable microphone access in Settings."
            case .restrictedByPolicy:
                return "Camera access is restricted by device policy."
            }
        }
    }

    nonisolated init() {
        // Empty init for actor
    }

    /// Request camera permission
    func requestCameraPermission() async -> Bool {
        let status = getCameraPermissionStatus()

        switch status {
        case .authorized:
            return true
        case .denied:
            logger.warning("Camera permission denied")
            return false
        case .restricted:
            logger.warning("Camera access restricted")
            return false
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            logger.info("Camera permission requested, granted: \(granted)")
            return granted
        }
    }

    /// Request microphone permission
    func requestMicrophonePermission() async -> Bool {
        let status = getMicrophonePermissionStatus()

        switch status {
        case .authorized:
            return true
        case .denied:
            logger.warning("Microphone permission denied")
            return false
        case .restricted:
            logger.warning("Microphone access restricted")
            return false
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            logger.info("Microphone permission requested, granted: \(granted)")
            return granted
        }
    }

    /// Get camera permission status
    func getCameraPermissionStatus() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }

    /// Get microphone permission status
    func getMicrophonePermissionStatus() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }

    /// Request both camera and microphone permissions
    func requestBothPermissions() async -> (camera: Bool, microphone: Bool) {
        async let cameraGranted = requestCameraPermission()
        async let micGranted = requestMicrophonePermission()

        let (cam, mic) = await (cameraGranted, micGranted)
        logger.info("Permission request completed - Camera: \(cam), Microphone: \(mic)")

        return (camera: cam, microphone: mic)
    }

    /// Check if camera permission is granted
    func isCameraAuthorized() -> Bool {
        return getCameraPermissionStatus() == .authorized
    }

    /// Check if microphone permission is granted
    func isMicrophoneAuthorized() -> Bool {
        return getMicrophonePermissionStatus() == .authorized
    }

    /// Log current permission status
    func logPermissionStatus() {
        logger.info("Camera permission: \(self.getCameraPermissionStatus().description)")
        logger.info("Microphone permission: \(self.getMicrophonePermissionStatus().description)")
    }
}
