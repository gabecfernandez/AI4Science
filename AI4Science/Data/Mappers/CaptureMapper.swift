import Foundation

/// Mapper for converting between Capture domain models and persistence models
struct CaptureMapper {
    /// Map CaptureEntity to CaptureDTO for API communication
    static func toDTO(_ entity: CaptureEntity) -> CaptureDTO {
        CaptureDTO(
            id: entity.id,
            captureType: entity.captureType,
            capturedAt: entity.capturedAt,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }

    /// Map CaptureDTO to CaptureEntity for persistence
    static func toEntity(_ dto: CaptureDTO) -> CaptureEntity {
        CaptureEntity(
            id: dto.id,
            captureType: dto.captureType,
            fileURL: "",
            mimeType: "",
            capturedAt: dto.capturedAt,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    /// Map domain Capture model to CaptureEntity
    static func toEntity(from capture: Capture) -> CaptureEntity {
        let entity = CaptureEntity(
            id: capture.id,
            captureType: capture.captureType,
            fileURL: capture.fileURL,
            mimeType: capture.mimeType,
            capturedAt: capture.capturedAt,
            createdAt: capture.createdAt,
            updatedAt: capture.updatedAt
        )
        entity.fileSize = capture.fileSize
        entity.deviceInfo = capture.deviceInfo
        entity.cameraSettings = capture.cameraSettings
        entity.processingStatus = capture.processingStatus
        entity.qualityScore = capture.qualityScore
        entity.notes = capture.notes
        entity.isProcessed = capture.isProcessed
        return entity
    }

    /// Map CaptureEntity to domain Capture model
    static func toModel(_ entity: CaptureEntity) -> Capture {
        Capture(
            id: entity.id,
            captureType: entity.captureType,
            fileURL: entity.fileURL,
            mimeType: entity.mimeType,
            fileSize: entity.fileSize,
            deviceInfo: entity.deviceInfo,
            cameraSettings: entity.cameraSettings,
            processingStatus: entity.processingStatus,
            qualityScore: entity.qualityScore,
            notes: entity.notes,
            isProcessed: entity.isProcessed,
            capturedAt: entity.capturedAt,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt
        )
    }

    /// Update CaptureEntity from domain Capture
    static func update(_ entity: CaptureEntity, with capture: Capture) {
        entity.notes = capture.notes
        entity.qualityScore = capture.qualityScore
        entity.processingStatus = capture.processingStatus
        entity.isProcessed = capture.isProcessed
        entity.updatedAt = capture.updatedAt
    }
}

/// Domain Capture model
struct Capture: Codable, Identifiable {
    let id: String
    let captureType: String
    let fileURL: String
    let mimeType: String
    var fileSize: Int64
    var deviceInfo: String?
    var cameraSettings: [String: String]
    var processingStatus: String
    var qualityScore: Double?
    var notes: String?
    var isProcessed: Bool
    var capturedAt: Date
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        captureType: String,
        fileURL: String,
        mimeType: String,
        fileSize: Int64 = 0,
        deviceInfo: String? = nil,
        cameraSettings: [String: String] = [:],
        processingStatus: String = "pending",
        qualityScore: Double? = nil,
        notes: String? = nil,
        isProcessed: Bool = false,
        capturedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.captureType = captureType
        self.fileURL = fileURL
        self.mimeType = mimeType
        self.fileSize = fileSize
        self.deviceInfo = deviceInfo
        self.cameraSettings = cameraSettings
        self.processingStatus = processingStatus
        self.qualityScore = qualityScore
        self.notes = notes
        self.isProcessed = isProcessed
        self.capturedAt = capturedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var isImage: Bool {
        mimeType.hasPrefix("image/")
    }

    var isVideo: Bool {
        mimeType.hasPrefix("video/")
    }

    var isReadyForAnalysis: Bool {
        !fileURL.isEmpty && fileSize > 0
    }

    var isPending: Bool {
        processingStatus == "pending"
    }

    var isCompleted: Bool {
        processingStatus == "completed"
    }

    var isFailed: Bool {
        processingStatus == "failed"
    }

    mutating func markProcessed() {
        isProcessed = true
        processingStatus = "completed"
        updatedAt = Date()
    }

    mutating func setQualityScore(_ score: Double) {
        qualityScore = min(max(score, 0.0), 1.0)
        updatedAt = Date()
    }

    mutating func updateProcessingStatus(_ status: String) {
        processingStatus = status
        updatedAt = Date()
    }
}
