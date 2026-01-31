import Foundation

/// Mapper for converting between Capture domain model and CaptureEntity persistence model
struct CaptureMapper {

    /// Map Capture domain model to CaptureEntity
    static func toEntity(from capture: Capture) -> CaptureEntity {
        let entity = CaptureEntity(
            id: capture.id.uuidString,
            captureType: capture.type.rawValue,
            fileURL: capture.fileURL.path,
            mimeType: capture.type == .video ? "video/mp4" : "image/heic",
            capturedAt: capture.metadata.captureDate,
            createdAt: capture.createdAt
        )
        entity.fileSize = capture.fileSize
        entity.deviceInfo = capture.metadata.deviceModel
        return entity
    }

    /// Map CaptureEntity to Capture domain model
    static func toModel(from entity: CaptureEntity) -> Capture {
        let captureType = CaptureType(rawValue: entity.captureType) ?? .photo
        let metadata = CaptureMetadata(
            width: 0,
            height: 0,
            colorSpace: .sRGB,
            captureDate: entity.capturedAt,
            deviceModel: entity.deviceInfo ?? ""
        )
        return Capture(
            id: UUID(uuidString: entity.id) ?? UUID(),
            sampleId: UUID(uuidString: entity.sample?.id ?? "") ?? UUID(),
            type: captureType,
            fileURL: URL(fileURLWithPath: entity.fileURL),
            thumbnailURL: nil,
            metadata: metadata,
            fileSize: entity.fileSize,
            createdAt: entity.createdAt,
            createdBy: UUID()
        )
    }
}
