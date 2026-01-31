import AVFoundation
import Photos
import os.log

/// Service for capturing high-quality photos with optional RAW support
actor PhotoCaptureService: NSObject {
    static let shared = PhotoCaptureService()

    private let logger = Logger(subsystem: "com.ai4science.camera", category: "PhotoCaptureService")

    private var photoOutput: AVCapturePhotoOutput?
    private var captureCompletionHandler: ((Result<CapturedPhoto, Error>) -> Void)?
    private var captureDelegate: PhotoCaptureDelegate?

    enum PhotoCaptureError: LocalizedError {
        case outputNotConfigured
        case captureAlreadyInProgress
        case photoDataUnavailable
        case invalidImage

        var errorDescription: String? {
            switch self {
            case .outputNotConfigured:
                return "Photo output is not configured"
            case .captureAlreadyInProgress:
                return "A capture is already in progress"
            case .photoDataUnavailable:
                return "Photo data is unavailable"
            case .invalidImage:
                return "Failed to create image from photo data"
            }
        }
    }

    struct CapturedPhoto {
        let image: Data
        let metadata: [String: Any]
        let rawData: Data?
        let timestamp: Date

        var cgImage: CGImage? {
            UIImage(data: image)?.cgImage
        }
    }

    nonisolated override init() {
        super.init()
    }

    /// Configure the photo output for the capture session
    func configurePhotoOutput(for session: AVCaptureSession) async throws {
        let output = AVCapturePhotoOutput()

        // Configure for high quality
        output.maxPhotoQualityPrioritization = .quality

        if session.canAddOutput(output) {
            session.addOutput(output)
            self.photoOutput = output
            logger.info("Photo output configured")
        } else {
            throw PhotoCaptureError.outputNotConfigured
        }
    }

    /// Capture a photo with optional RAW support
    func capturePhoto(
        enableRaw: Bool = false,
        flashMode: AVCaptureDevice.FlashMode = .auto
    ) async throws -> CapturedPhoto {
        guard let photoOutput = photoOutput else {
            throw PhotoCaptureError.outputNotConfigured
        }

        guard captureCompletionHandler == nil else {
            throw PhotoCaptureError.captureAlreadyInProgress
        }

        let settings = createPhotoSettings(enableRaw: enableRaw, flashMode: flashMode)

        return try await withCheckedThrowingContinuation { continuation in
            captureCompletionHandler = { result in
                continuation.resume(with: result)
            }

            let delegate = PhotoCaptureDelegate(
                settings: settings,
                completion: { [weak self] result in
                    self?.captureCompletionHandler = nil
                    self?.captureCompletionHandler?(result)
                }
            )

            self.captureDelegate = delegate
            photoOutput.capturePhoto(with: settings, delegate: delegate)

            logger.info("Photo capture initiated with RAW support: \(enableRaw)")
        }
    }

    /// Capture multiple photos in burst mode
    func captureBurstPhotos(
        count: Int,
        interval: TimeInterval = 0.1
    ) async throws -> [CapturedPhoto] {
        var photos: [CapturedPhoto] = []

        for _ in 0..<count {
            do {
                let photo = try await capturePhoto()
                photos.append(photo)

                if interval > 0 {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                }
            } catch {
                logger.error("Failed to capture burst photo: \(error.localizedDescription)")
                throw error
            }
        }

        return photos
    }

    // MARK: - Private Methods

    private func createPhotoSettings(
        enableRaw: Bool,
        flashMode: AVCaptureDevice.FlashMode
    ) -> AVCapturePhotoSettings {
        var settings = AVCapturePhotoSettings()

        // Configure flash
        settings.flashMode = flashMode

        // Configure RAW if available
        if enableRaw, let rawFormat = settings.availableRawPhotoPixelFormatTypes.first {
            let rawSettings = AVCaptureRawPhotoProcessingSettings(
                availableFormats: [rawFormat]
            )
            settings.rawPhotoProcessingSettings = rawSettings
        }

        // Configure HEIF format for efficiency
        if settings.availablePhotoCodecTypes.contains(.heif) {
            settings.photoCodecType = .heif
        } else if settings.availablePhotoCodecTypes.contains(.jpeg) {
            settings.photoCodecType = .jpeg
        }

        // Enable auto stabilization
        settings.isAutoStillImageStabilizationEnabled =
            photoOutput?.isAutoStillImageStabilizationSupported ?? false

        // Set max resolution
        if let maxDimensions = photoOutput?.maxPhotoDimensions.first {
            settings.maxPhotoDimensions = maxDimensions
        }

        return settings
    }
}

// MARK: - PhotoCaptureDelegate

private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let settings: AVCapturePhotoSettings
    let completion: (Result<PhotoCaptureService.CapturedPhoto, Error>) -> Void

    private var photoData: Data?
    private var rawData: Data?
    private var metadata: [String: Any] = [:]
    private let logger = Logger(subsystem: "com.ai4science.camera", category: "PhotoCaptureDelegate")

    init(
        settings: AVCapturePhotoSettings,
        completion: @escaping (Result<PhotoCaptureService.CapturedPhoto, Error>) -> Void
    ) {
        self.settings = settings
        self.completion = completion
    }

    // MARK: - AVCapturePhotoCaptureDelegate

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            logger.error("Photo capture error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        // Extract photo data
        if let imageData = photo.fileDataRepresentation() {
            photoData = imageData
            logger.info("Photo data captured, size: \(imageData.count) bytes")
        }

        // Extract metadata
        if let metadata = photo.metadata {
            self.metadata = metadata
        }

        // Extract RAW data if available
        if let rawData = photo.rawPhoto?.fileDataRepresentation() {
            self.rawData = rawData
            logger.info("RAW photo data captured, size: \(rawData.count) bytes")
        }
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: Error?
    ) {
        if let error = error {
            logger.error("Capture finalization error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        guard let photoData = photoData else {
            completion(.failure(PhotoCaptureService.PhotoCaptureError.photoDataUnavailable))
            return
        }

        let capturedPhoto = PhotoCaptureService.CapturedPhoto(
            image: photoData,
            metadata: metadata,
            rawData: rawData,
            timestamp: Date()
        )

        completion(.success(capturedPhoto))
        logger.info("Photo capture completed successfully")
    }
}
