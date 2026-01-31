import AVFoundation
import os.log

/// Service for video recording with configurable quality settings
actor VideoCaptureService: NSObject {
    static let shared = VideoCaptureService()

    private let logger = Logger(subsystem: "com.ai4science.camera", category: "VideoCaptureService")

    private var videoOutput: AVCaptureMovieFileOutput?
    private var recordingDelegate: VideoRecordingDelegate?
    private var isRecording = false
    private var currentRecordingURL: URL?

    enum VideoQuality {
        case low
        case medium
        case high
        case maximum

        var preset: AVCaptureSession.Preset {
            switch self {
            case .low:
                return .vga640x480
            case .medium:
                return .hd1280x720
            case .high:
                return .hd1920x1080
            case .maximum:
                return .hd4K3840x2160
            }
        }

        var bitrate: Int {
            switch self {
            case .low:
                return 1_000_000      // 1 Mbps
            case .medium:
                return 4_000_000      // 4 Mbps
            case .high:
                return 10_000_000     // 10 Mbps
            case .maximum:
                return 25_000_000     // 25 Mbps
            }
        }
    }

    enum VideoCaptureError: LocalizedError {
        case outputNotConfigured
        case recordingAlreadyInProgress
        case recordingNotInProgress
        case invalidOutputURL
        case recordingFailed(String)

        var errorDescription: String? {
            switch self {
            case .outputNotConfigured:
                return "Video output is not configured"
            case .recordingAlreadyInProgress:
                return "Video recording is already in progress"
            case .recordingNotInProgress:
                return "No video recording in progress"
            case .invalidOutputURL:
                return "Invalid output URL"
            case .recordingFailed(let reason):
                return "Recording failed: \(reason)"
            }
        }
    }

    struct RecordedVideo {
        let fileURL: URL
        let duration: CMTime
        let fileSize: Int64
        let timestamp: Date
    }

    nonisolated override init() {
        super.init()
    }

    /// Configure the video output for the capture session
    func configureVideoOutput(for session: AVCaptureSession) async throws {
        let output = AVCaptureMovieFileOutput()

        // Configure max duration (30 minutes)
        output.maxRecordedDuration = CMTime(seconds: 30 * 60, preferredTimescale: 1)

        // Configure max file size (5GB)
        output.maxRecordedFileSize = 5 * 1024 * 1024 * 1024

        if session.canAddOutput(output) {
            session.addOutput(output)
            self.videoOutput = output
            logger.info("Video output configured")
        } else {
            throw VideoCaptureError.outputNotConfigured
        }
    }

    /// Start video recording with specified quality
    func startRecording(
        quality: VideoQuality = .high,
        outputURL: URL
    ) async throws {
        guard let videoOutput = videoOutput else {
            throw VideoCaptureError.outputNotConfigured
        }

        guard !isRecording else {
            throw VideoCaptureError.recordingAlreadyInProgress
        }

        // Validate output URL
        let directory = outputURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let delegate = VideoRecordingDelegate(quality: quality) { [weak self] result in
            self?.handleRecordingCompletion(result)
        }

        self.recordingDelegate = delegate
        self.currentRecordingURL = outputURL
        self.isRecording = true

        videoOutput.startRecording(to: outputURL, recordingDelegate: delegate)

        logger.info("Video recording started with \(quality) quality")
    }

    /// Stop the current video recording
    func stopRecording() async throws -> RecordedVideo {
        guard let videoOutput = videoOutput else {
            throw VideoCaptureError.outputNotConfigured
        }

        guard isRecording else {
            throw VideoCaptureError.recordingNotInProgress
        }

        return try await withCheckedThrowingContinuation { continuation in
            let delegate = VideoRecordingDelegate(quality: .high) { [weak self] result in
                self?.isRecording = false
                continuation.resume(with: result.map { $0 })
            }

            self.recordingDelegate = delegate
            videoOutput.stopRecording()
        }
    }

    /// Pause the current video recording
    func pauseRecording() throws {
        guard let videoOutput = videoOutput else {
            throw VideoCaptureError.outputNotConfigured
        }

        guard isRecording else {
            throw VideoCaptureError.recordingNotInProgress
        }

        videoOutput.pauseRecording()
        logger.info("Video recording paused")
    }

    /// Resume the paused video recording
    func resumeRecording() throws {
        guard let videoOutput = videoOutput else {
            throw VideoCaptureError.outputNotConfigured
        }

        guard isRecording else {
            throw VideoCaptureError.recordingNotInProgress
        }

        videoOutput.resumeRecording()
        logger.info("Video recording resumed")
    }

    /// Check if currently recording
    func isCurrentlyRecording() -> Bool {
        return isRecording
    }

    /// Get the current recording duration
    func getCurrentRecordingDuration() -> CMTime? {
        return videoOutput?.recordedDuration
    }

    // MARK: - Private Methods

    private func handleRecordingCompletion(_ result: Result<RecordedVideo, Error>) {
        isRecording = false

        switch result {
        case .success(let video):
            logger.info("Video recording completed, file size: \(video.fileSize) bytes")
        case .failure(let error):
            logger.error("Video recording failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - VideoRecordingDelegate

private class VideoRecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    let quality: VideoCaptureService.VideoQuality
    let completion: (Result<VideoCaptureService.RecordedVideo, Error>) -> Void

    private let logger = Logger(subsystem: "com.ai4science.camera", category: "VideoRecordingDelegate")
    private let startTime = Date()

    init(
        quality: VideoCaptureService.VideoQuality,
        completion: @escaping (Result<VideoCaptureService.RecordedVideo, Error>) -> Void
    ) {
        self.quality = quality
        self.completion = completion
    }

    // MARK: - AVCaptureFileOutputRecordingDelegate

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        defer {
            logger.info("Video recording delegate completed")
        }

        if let error = error {
            logger.error("Recording error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        // Get file information
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: outputFileURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0

            // Get video duration
            let asset = AVAsset(url: outputFileURL)
            let duration = asset.duration

            let recordedVideo = VideoCaptureService.RecordedVideo(
                fileURL: outputFileURL,
                duration: duration,
                fileSize: fileSize,
                timestamp: startTime
            )

            completion(.success(recordedVideo))
            logger.info("Video recording finalized, duration: \(duration.seconds)s, size: \(fileSize) bytes")
        } catch {
            logger.error("Failed to get file information: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didPauseRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        logger.info("Recording paused")
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didResumeRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        logger.info("Recording resumed")
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        logger.info("Recording started")
    }
}
