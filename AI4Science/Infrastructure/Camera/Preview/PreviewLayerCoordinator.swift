import AVFoundation
import UIKit
import os.log

/// Coordinator for managing preview layer updates and interactions
actor PreviewLayerCoordinator {
    static let shared = PreviewLayerCoordinator()

    private let logger = Logger(subsystem: "com.ai4science.camera", category: "PreviewLayerCoordinator")

    private weak var previewLayer: AVCaptureVideoPreviewLayer?
    private weak var containerView: UIView?

    enum CoordinationError: LocalizedError {
        case invalidLayer
        case invalidContainer

        var errorDescription: String? {
            switch self {
            case .invalidLayer:
                return "Preview layer is not set"
            case .invalidContainer:
                return "Container view is not set"
            }
        }
    }

    nonisolated init() {
        // Empty init for actor
    }

    /// Set the preview layer
    func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = layer
        logger.info("Preview layer set")
    }

    /// Set the container view
    func setContainerView(_ view: UIView) {
        self.containerView = view
        logger.info("Container view set")
    }

    /// Update preview layer frame
    func updatePreviewLayerFrame(_ frame: CGRect) throws {
        guard let previewLayer = previewLayer else {
            throw CoordinationError.invalidLayer
        }

        previewLayer.frame = frame
        logger.debug("Preview layer frame updated: \(frame)")
    }

    /// Set video gravity for preview
    func setVideoGravity(_ gravity: AVLayerVideoGravity) throws {
        guard let previewLayer = previewLayer else {
            throw CoordinationError.invalidLayer
        }

        previewLayer.videoGravity = gravity
        logger.info("Video gravity set to: \(gravity.rawValue)")
    }

    /// Convert point from screen coordinates to preview layer coordinates
    func convertPointToPreviewLayer(_ point: CGPoint) throws -> CGPoint {
        guard let previewLayer = previewLayer else {
            throw CoordinationError.invalidLayer
        }

        guard let connection = previewLayer.connection else {
            throw CoordinationError.invalidLayer
        }

        let videoOrientation = getVideoOrientation(from: connection)

        var convertedPoint = point

        // Adjust for video orientation
        let bounds = previewLayer.bounds

        if connection.isVideoMirrored {
            convertedPoint.x = bounds.width - convertedPoint.x
        }

        switch videoOrientation {
        case .portrait:
            break
        case .portraitUpsideDown:
            convertedPoint = CGPoint(
                x: bounds.width - convertedPoint.x,
                y: bounds.height - convertedPoint.y
            )
        case .landscapeRight:
            let temp = convertedPoint.x
            convertedPoint.x = convertedPoint.y
            convertedPoint.y = bounds.width - temp
        case .landscapeLeft:
            let temp = convertedPoint.x
            convertedPoint.x = bounds.height - convertedPoint.y
            convertedPoint.y = temp
        @unknown default:
            break
        }

        return convertedPoint
    }

    /// Convert point from preview layer to screen coordinates
    func convertPointFromPreviewLayer(_ point: CGPoint) throws -> CGPoint {
        guard let previewLayer = previewLayer else {
            throw CoordinationError.invalidLayer
        }

        guard let connection = previewLayer.connection else {
            throw CoordinationError.invalidLayer
        }

        let videoOrientation = getVideoOrientation(from: connection)
        var convertedPoint = point

        let bounds = previewLayer.bounds

        switch videoOrientation {
        case .portrait:
            break
        case .portraitUpsideDown:
            convertedPoint = CGPoint(
                x: bounds.width - convertedPoint.x,
                y: bounds.height - convertedPoint.y
            )
        case .landscapeRight:
            let temp = convertedPoint.x
            convertedPoint.x = bounds.height - convertedPoint.y
            convertedPoint.y = temp
        case .landscapeLeft:
            let temp = convertedPoint.x
            convertedPoint.x = convertedPoint.y
            convertedPoint.y = bounds.width - temp
        @unknown default:
            break
        }

        if connection.isVideoMirrored {
            convertedPoint.x = bounds.width - convertedPoint.x
        }

        return convertedPoint
    }

    /// Get the current video orientation
    func getVideoOrientation() throws -> AVCaptureVideoOrientation {
        guard let previewLayer = previewLayer else {
            throw CoordinationError.invalidLayer
        }

        guard let connection = previewLayer.connection else {
            throw CoordinationError.invalidLayer
        }

        return getVideoOrientation(from: connection)
    }

    /// Update preview layer orientation
    func updateOrientation(_ orientation: UIInterfaceOrientation) throws {
        guard let previewLayer = previewLayer else {
            throw CoordinationError.invalidLayer
        }

        guard let connection = previewLayer.connection else {
            throw CoordinationError.invalidLayer
        }

        let videoOrientation: AVCaptureVideoOrientation

        switch orientation {
        case .portrait:
            videoOrientation = .portrait
        case .portraitUpsideDown:
            videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            videoOrientation = .landscapeLeft
        case .landscapeRight:
            videoOrientation = .landscapeRight
        default:
            videoOrientation = .portrait
        }

        if connection.isVideoOrientationSupported {
            connection.videoOrientation = videoOrientation
            logger.info("Orientation updated to: \(videoOrientation.description)")
        }
    }

    /// Get zoom scale information
    func getZoomInfo(for device: AVCaptureDevice) -> ZoomInfo {
        let minZoom = device.minAvailableVideoZoomFactor
        let maxZoom = device.activeFormat.videoMaxZoomFactor
        let currentZoom = device.videoZoomFactor

        return ZoomInfo(
            minZoom: minZoom,
            maxZoom: maxZoom,
            currentZoom: currentZoom
        )
    }

    /// Get focus/exposure point for tap location
    func getFocusPoint(for tapPoint: CGPoint, in bounds: CGRect) -> CGPoint {
        let normalizedPoint = CGPoint(
            x: tapPoint.x / bounds.width,
            y: tapPoint.y / bounds.height
        )

        logger.debug("Normalized focus point: \(normalizedPoint)")
        return normalizedPoint
    }

    // MARK: - Private Methods

    private func getVideoOrientation(from connection: AVCaptureConnection) -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
}

struct ZoomInfo {
    let minZoom: CGFloat
    let maxZoom: CGFloat
    let currentZoom: CGFloat

    var zoomRange: ClosedRange<CGFloat> {
        minZoom...maxZoom
    }
}

private extension AVCaptureVideoOrientation {
    var description: String {
        switch self {
        case .portrait:
            return "Portrait"
        case .portraitUpsideDown:
            return "Portrait Upside Down"
        case .landscapeRight:
            return "Landscape Right"
        case .landscapeLeft:
            return "Landscape Left"
        @unknown default:
            return "Unknown"
        }
    }
}
