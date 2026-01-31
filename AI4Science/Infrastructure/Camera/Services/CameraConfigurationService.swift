import AVFoundation
import os.log

/// Service for configuring camera settings (exposure, focus, zoom, etc.)
actor CameraConfigurationService {
    static let shared = CameraConfigurationService()

    private let logger = Logger(subsystem: "com.ai4science.camera", category: "CameraConfigurationService")

    enum ConfigurationError: LocalizedError {
        case deviceNotAvailable
        case lockFailed(String)
        case focusNotSupported
        case exposureNotSupported
        case zoomNotSupported
        case whiteBalanceNotSupported

        var errorDescription: String? {
            switch self {
            case .deviceNotAvailable:
                return "Camera device not available"
            case .lockFailed(let reason):
                return "Failed to lock device for configuration: \(reason)"
            case .focusNotSupported:
                return "Focus mode not supported by device"
            case .exposureNotSupported:
                return "Exposure mode not supported by device"
            case .zoomNotSupported:
                return "Zoom not supported by device"
            case .whiteBalanceNotSupported:
                return "White balance not supported by device"
            }
        }
    }

    nonisolated init() {
        // Empty init for actor
    }

    /// Set focus mode
    func setFocusMode(_ mode: AVCaptureDevice.FocusMode, device: AVCaptureDevice) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try device.lockForConfiguration()
                    defer { device.unlockForConfiguration() }

                    guard device.isFocusModeSupported(mode) else {
                        continuation.resume(throwing: ConfigurationError.focusNotSupported)
                        return
                    }

                    device.focusMode = mode
                    self.logger.info("Focus mode set to: \(mode.description)")
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to set focus mode: \(error.localizedDescription)")
                    continuation.resume(throwing: ConfigurationError.lockFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Set focus point of interest
    func setFocusPointOfInterest(_ point: CGPoint, device: AVCaptureDevice) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try device.lockForConfiguration()
                    defer { device.unlockForConfiguration() }

                    guard device.isFocusPointOfInterestSupported else {
                        continuation.resume(throwing: ConfigurationError.focusNotSupported)
                        return
                    }

                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                    self.logger.info("Focus point of interest set to: \(point)")
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to set focus point: \(error.localizedDescription)")
                    continuation.resume(throwing: ConfigurationError.lockFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Set exposure mode
    func setExposureMode(_ mode: AVCaptureDevice.ExposureMode, device: AVCaptureDevice) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try device.lockForConfiguration()
                    defer { device.unlockForConfiguration() }

                    guard device.isExposureModeSupported(mode) else {
                        continuation.resume(throwing: ConfigurationError.exposureNotSupported)
                        return
                    }

                    device.exposureMode = mode
                    self.logger.info("Exposure mode set to: \(mode.description)")
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to set exposure mode: \(error.localizedDescription)")
                    continuation.resume(throwing: ConfigurationError.lockFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Set exposure point of interest
    func setExposurePointOfInterest(_ point: CGPoint, device: AVCaptureDevice) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try device.lockForConfiguration()
                    defer { device.unlockForConfiguration() }

                    guard device.isExposurePointOfInterestSupported else {
                        continuation.resume(throwing: ConfigurationError.exposureNotSupported)
                        return
                    }

                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                    self.logger.info("Exposure point of interest set to: \(point)")
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to set exposure point: \(error.localizedDescription)")
                    continuation.resume(throwing: ConfigurationError.lockFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Set exposure duration and ISO manually
    func setManualExposure(duration: CMTime, iso: Float, device: AVCaptureDevice) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try device.lockForConfiguration()
                    defer { device.unlockForConfiguration() }

                    guard device.isExposureModeSupported(.custom) else {
                        continuation.resume(throwing: ConfigurationError.exposureNotSupported)
                        return
                    }

                    // Clamp values to supported ranges
                    let minDuration = device.activeFormat.minExposureDuration
                    let maxDuration = device.activeFormat.maxExposureDuration
                    let clampedDuration = CMTimeMaximum(minDuration, CMTimeMinimum(maxDuration, duration))

                    let minISO = device.activeFormat.minISO
                    let maxISO = device.activeFormat.maxISO
                    let clampedISO = max(minISO, min(maxISO, iso))

                    device.exposureMode = .custom
                    device.setExposureModeCustom(duration: clampedDuration, iso: clampedISO) { _ in }

                    self.logger.info("Manual exposure set - Duration: \(clampedDuration.seconds)s, ISO: \(clampedISO)")
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to set manual exposure: \(error.localizedDescription)")
                    continuation.resume(throwing: ConfigurationError.lockFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Set zoom factor
    func setZoomFactor(_ factor: CGFloat, device: AVCaptureDevice) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try device.lockForConfiguration()
                    defer { device.unlockForConfiguration() }

                    let maxZoom = device.activeFormat.videoMaxZoomFactor
                    let minZoom = device.minAvailableVideoZoomFactor
                    let clampedZoom = max(minZoom, min(maxZoom, factor))

                    device.videoZoomFactor = clampedZoom
                    self.logger.info("Zoom factor set to: \(clampedZoom)")
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to set zoom: \(error.localizedDescription)")
                    continuation.resume(throwing: ConfigurationError.lockFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Set white balance mode
    func setWhiteBalanceMode(_ mode: AVCaptureDevice.WhiteBalanceMode, device: AVCaptureDevice) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try device.lockForConfiguration()
                    defer { device.unlockForConfiguration() }

                    guard device.isWhiteBalanceModeSupported(mode) else {
                        continuation.resume(throwing: ConfigurationError.whiteBalanceNotSupported)
                        return
                    }

                    device.whiteBalanceMode = mode
                    self.logger.info("White balance mode set to: \(mode.description)")
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to set white balance mode: \(error.localizedDescription)")
                    continuation.resume(throwing: ConfigurationError.lockFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Set white balance temperature gains
    func setWhiteBalanceGains(_ gains: AVCaptureDevice.WhiteBalanceGains, device: AVCaptureDevice) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try device.lockForConfiguration()
                    defer { device.unlockForConfiguration() }

                    guard device.isWhiteBalanceModeSupported(.locked) else {
                        continuation.resume(throwing: ConfigurationError.whiteBalanceNotSupported)
                        return
                    }

                    // Clamp gains to valid range
                    let maxGain = device.maxWhiteBalanceGain
                    let clampedGains = AVCaptureDevice.WhiteBalanceGains(
                        redGain: min(maxGain, gains.redGain),
                        greenGain: min(maxGain, gains.greenGain),
                        blueGain: min(maxGain, gains.blueGain)
                    )

                    device.whiteBalanceMode = .locked
                    device.setWhiteBalanceModeLocked(with: clampedGains) { _ in }

                    self.logger.info("White balance gains set")
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to set white balance gains: \(error.localizedDescription)")
                    continuation.resume(throwing: ConfigurationError.lockFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Enable or disable torch (flashlight)
    func setTorchMode(_ mode: AVCaptureDevice.TorchMode, device: AVCaptureDevice) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try device.lockForConfiguration()
                    defer { device.unlockForConfiguration() }

                    guard device.isTorchModeSupported(mode) else {
                        self.logger.warning("Torch mode not supported")
                        continuation.resume()
                        return
                    }

                    device.torchMode = mode
                    self.logger.info("Torch mode set to: \(mode.description)")
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to set torch mode: \(error.localizedDescription)")
                    continuation.resume(throwing: ConfigurationError.lockFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Set video stabilization mode
    func setVideoStabilizationMode(_ mode: AVCaptureVideoStabilizationMode, for connection: AVCaptureConnection) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    if connection.isVideoStabilizationSupported {
                        connection.preferredVideoStabilizationMode = mode
                        self.logger.info("Video stabilization mode set to: \(mode.rawValue)")
                    } else {
                        self.logger.warning("Video stabilization not supported")
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: ConfigurationError.lockFailed(error.localizedDescription))
                }
            }
        }
    }

    /// Get camera capabilities
    func getCameraCapabilities(device: AVCaptureDevice) -> CameraCapabilities {
        let format = device.activeFormat

        return CameraCapabilities(
            supportsAutoFocus: device.isFocusModeSupported(.autoFocus),
            supportsManualFocus: device.isFocusModeSupported(.locked),
            supportsFocusPointOfInterest: device.isFocusPointOfInterestSupported,
            supportsAutoExposure: device.isExposureModeSupported(.autoExpose),
            supportsManualExposure: device.isExposureModeSupported(.custom),
            supportsExposurePointOfInterest: device.isExposurePointOfInterestSupported,
            minZoomFactor: device.minAvailableVideoZoomFactor,
            maxZoomFactor: format.videoMaxZoomFactor,
            minISO: format.minISO,
            maxISO: format.maxISO,
            supportsTorch: device.isTorchModeSupported(.on),
            supportsWhiteBalance: device.isWhiteBalanceModeSupported(.locked),
            maxWhiteBalanceGain: device.maxWhiteBalanceGain
        )
    }
}

struct CameraCapabilities {
    let supportsAutoFocus: Bool
    let supportsManualFocus: Bool
    let supportsFocusPointOfInterest: Bool
    let supportsAutoExposure: Bool
    let supportsManualExposure: Bool
    let supportsExposurePointOfInterest: Bool
    let minZoomFactor: CGFloat
    let maxZoomFactor: CGFloat
    let minISO: Float
    let maxISO: Float
    let supportsTorch: Bool
    let supportsWhiteBalance: Bool
    let maxWhiteBalanceGain: Float
}

// MARK: - Helper Extensions

private extension AVCaptureDevice.FocusMode {
    var description: String {
        switch self {
        case .locked:
            return "Locked"
        case .autoFocus:
            return "Auto"
        case .continuousAutoFocus:
            return "Continuous Auto"
        @unknown default:
            return "Unknown"
        }
    }
}

private extension AVCaptureDevice.ExposureMode {
    var description: String {
        switch self {
        case .locked:
            return "Locked"
        case .autoExpose:
            return "Auto"
        case .continuousAutoExposure:
            return "Continuous Auto"
        case .custom:
            return "Custom"
        @unknown default:
            return "Unknown"
        }
    }
}

private extension AVCaptureDevice.WhiteBalanceMode {
    var description: String {
        switch self {
        case .autoWhiteBalance:
            return "Auto"
        case .locked:
            return "Locked"
        case .continuousAutoWhiteBalance:
            return "Continuous Auto"
        @unknown default:
            return "Unknown"
        }
    }
}

private extension AVCaptureDevice.TorchMode {
    var description: String {
        switch self {
        case .off:
            return "Off"
        case .on:
            return "On"
        case .auto:
            return "Auto"
        @unknown default:
            return "Unknown"
        }
    }
}
