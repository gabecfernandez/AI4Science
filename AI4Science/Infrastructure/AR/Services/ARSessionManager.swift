import ARKit
import os.log

/// Actor managing ARKit session lifecycle and configuration
actor ARSessionManager: NSObject {
    static let shared = ARSessionManager()

    private let logger = Logger(subsystem: "com.ai4science.ar", category: "ARSessionManager")

    private var arSession: ARSession?
    private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "com.ai4science.ar.session", attributes: .concurrent)

    enum ARSessionError: LocalizedError {
        case sessionNotAvailable
        case configurationNotSupported
        case sessionAlreadyRunning
        case sessionNotRunning
        case trackingFailed(String)

        var errorDescription: String? {
            switch self {
            case .sessionNotAvailable:
                return "AR session is not available"
            case .configurationNotSupported:
                return "AR configuration is not supported on this device"
            case .sessionAlreadyRunning:
                return "AR session is already running"
            case .sessionNotRunning:
                return "AR session is not running"
            case .trackingFailed(let reason):
                return "AR tracking failed: \(reason)"
            }
        }
    }

    enum TrackingConfiguration {
        case worldTracking
        case faceTracking
        case imageTracking
        case objectTracking

        @available(iOS 13.0, *)
        var configuration: ARConfiguration {
            switch self {
            case .worldTracking:
                let config = ARWorldTrackingConfiguration()
                config.planeDetection = [.horizontal, .vertical]
                config.environmentTexturing = .automatic
                if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
                    config.frameSemantics.insert(.personSegmentationWithDepth)
                }
                return config

            case .faceTracking:
                let config = ARFaceTrackingConfiguration()
                return config

            case .imageTracking:
                let config = ARImageTrackingConfiguration()
                return config

            case .objectTracking:
                let config = ARObjectTrackingConfiguration()
                return config
            }
        }
    }

    nonisolated override init() {
        super.init()
    }

    /// Check if AR is supported on this device
    nonisolated static func isARSupported() -> Bool {
        return ARWorldTrackingConfiguration.isSupported
    }

    /// Initialize and configure the AR session
    func setupARSession(configuration: TrackingConfiguration = .worldTracking) async throws {
        guard ARWorldTrackingConfiguration.isSupported else {
            throw ARSessionError.configurationNotSupported
        }

        guard arSession == nil else {
            throw ARSessionError.sessionAlreadyRunning
        }

        let session = ARSession()
        let config = configuration.configuration

        session.run(config)
        self.arSession = session

        logger.info("AR session configured with: \(configuration.description)")
    }

    /// Run the AR session
    func runSession() async throws {
        guard let session = arSession else {
            throw ARSessionError.sessionNotAvailable
        }

        guard !isSessionRunning else {
            throw ARSessionError.sessionAlreadyRunning
        }

        let config = (session.configuration ?? ARWorldTrackingConfiguration())
        session.run(config)

        isSessionRunning = true
        logger.info("AR session started")
    }

    /// Pause the AR session
    func pauseSession() async throws {
        guard let session = arSession else {
            throw ARSessionError.sessionNotAvailable
        }

        guard isSessionRunning else {
            throw ARSessionError.sessionNotRunning
        }

        session.pause()
        isSessionRunning = false
        logger.info("AR session paused")
    }

    /// Get the AR session
    func getSession() -> ARSession? {
        return arSession
    }

    /// Check if session is running
    func isRunning() -> Bool {
        return isSessionRunning
    }

    /// Get current frame
    func getCurrentFrame() -> ARFrame? {
        return arSession?.currentFrame
    }

    /// Update session configuration
    func updateConfiguration(_ configuration: TrackingConfiguration) async throws {
        guard let session = arSession else {
            throw ARSessionError.sessionNotAvailable
        }

        let config = configuration.configuration
        session.run(config)

        logger.info("AR configuration updated to: \(configuration.description)")
    }

    /// Enable light estimation
    func enableLightEstimation() throws {
        guard let session = arSession else {
            throw ARSessionError.sessionNotAvailable
        }

        guard var config = session.configuration as? ARWorldTrackingConfiguration else {
            throw ARSessionError.configurationNotSupported
        }

        config.lightEstimationEnabled = true
        session.run(config)

        logger.info("Light estimation enabled")
    }

    /// Enable people occlusion
    @available(iOS 14.0, *)
    func enablePeopleOcclusion() throws {
        guard let session = arSession else {
            throw ARSessionError.sessionNotAvailable
        }

        guard var config = session.configuration as? ARWorldTrackingConfiguration else {
            throw ARSessionError.configurationNotSupported
        }

        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentation) {
            config.frameSemantics.insert(.personSegmentation)
            session.run(config)
            logger.info("People occlusion enabled")
        }
    }

    /// Get tracking state
    func getTrackingState() -> ARCamera.TrackingState? {
        return arSession?.currentFrame?.camera.trackingState
    }

    /// Get available cameras
    func getAvailableCameras() -> [ARCamera]? {
        guard let frame = arSession?.currentFrame else {
            return nil
        }

        return [frame.camera]
    }
}

private extension ARSessionManager.TrackingConfiguration {
    var description: String {
        switch self {
        case .worldTracking:
            return "World Tracking"
        case .faceTracking:
            return "Face Tracking"
        case .imageTracking:
            return "Image Tracking"
        case .objectTracking:
            return "Object Tracking"
        }
    }
}
