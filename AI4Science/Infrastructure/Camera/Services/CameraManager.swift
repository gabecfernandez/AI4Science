import AVFoundation
import os.log

/// Actor managing AVCaptureSession lifecycle and camera device management
actor CameraManager {
    static let shared = CameraManager()

    private let logger = Logger(subsystem: "com.ai4science.camera", category: "CameraManager")

    private var captureSession: AVCaptureSession?
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var isSessionRunning = false
    private var setupError: Error?

    private let sessionQueue = DispatchQueue(
        label: "com.ai4science.camera.session",
        attributes: .concurrent
    )

    enum CameraManagerError: LocalizedError {
        case sessionNotAvailable
        case deviceNotAvailable
        case inputSetupFailed(String)
        case sessionAlreadyRunning
        case sessionNotRunning

        var errorDescription: String? {
            switch self {
            case .sessionNotAvailable:
                return "AVCaptureSession is not available"
            case .deviceNotAvailable:
                return "No camera device available"
            case .inputSetupFailed(let reason):
                return "Failed to setup camera input: \(reason)"
            case .sessionAlreadyRunning:
                return "Capture session is already running"
            case .sessionNotRunning:
                return "Capture session is not running"
            }
        }
    }

    nonisolated init() {
        // Empty init for actor
    }

    /// Initialize and configure the capture session
    func setupCaptureSession() async throws {
        guard captureSession == nil else {
            throw CameraManagerError.sessionAlreadyRunning
        }

        let session = AVCaptureSession()
        session.beginConfiguration()

        defer {
            session.commitConfiguration()
        }

        // Configure session for high quality
        if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }

        // Setup video input
        try setupVideoInput(for: session)

        // Setup audio input
        try setupAudioInput(for: session)

        self.captureSession = session
        logger.info("Capture session configured successfully")
    }

    /// Start the capture session
    func startSession() async throws {
        guard let session = captureSession else {
            throw CameraManagerError.sessionNotAvailable
        }

        guard !isSessionRunning else {
            throw CameraManagerError.sessionAlreadyRunning
        }

        sessionQueue.async { [weak session] in
            session?.startRunning()
        }

        isSessionRunning = true
        logger.info("Capture session started")
    }

    /// Stop the capture session
    func stopSession() async throws {
        guard let session = captureSession else {
            throw CameraManagerError.sessionNotAvailable
        }

        guard isSessionRunning else {
            throw CameraManagerError.sessionNotRunning
        }

        sessionQueue.async { [weak session] in
            session?.stopRunning()
        }

        isSessionRunning = false
        logger.info("Capture session stopped")
    }

    /// Get the current capture session
    func getSession() -> AVCaptureSession? {
        return captureSession
    }

    /// Check if session is currently running
    func isRunning() -> Bool {
        return isSessionRunning
    }

    /// Get available cameras
    func getAvailableCameras() -> [AVCaptureDevice] {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInUltraWideCamera],
            mediaType: .video,
            position: .back
        )
        return discoverySession.devices
    }

    /// Switch to a different camera device
    func switchCamera(to device: AVCaptureDevice) async throws {
        guard let session = captureSession else {
            throw CameraManagerError.sessionNotAvailable
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        // Remove current video input
        if let currentInput = videoInput {
            session.removeInput(currentInput)
        }

        // Add new input
        let newInput = try AVCaptureDeviceInput(device: device)
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            videoInput = newInput
            logger.info("Switched to camera: \(device.localizedName)")
        } else {
            throw CameraManagerError.inputSetupFailed("Cannot add new video input")
        }
    }

    // MARK: - Private Methods

    private func setupVideoInput(for session: AVCaptureSession) throws {
        guard let videoDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            throw CameraManagerError.deviceNotAvailable
        }

        let videoInput = try AVCaptureDeviceInput(device: videoDevice)

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
            self.videoInput = videoInput
        } else {
            throw CameraManagerError.inputSetupFailed("Cannot add video input")
        }
    }

    private func setupAudioInput(for session: AVCaptureSession) throws {
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            logger.warning("Audio device not available")
            return
        }

        let audioInput = try AVCaptureDeviceInput(device: audioDevice)

        if session.canAddInput(audioInput) {
            session.addInput(audioInput)
            self.audioInput = audioInput
        } else {
            logger.warning("Cannot add audio input")
        }
    }
}
