import Foundation

// MARK: - CaptureType

@frozen
public enum CaptureType: String, Codable, Sendable, CaseIterable {
    case photo
    case video
    case burst
}

// MARK: - ColorSpace

public enum ColorSpace: String, Codable, Sendable {
    case sRGB
    case displayP3
    case adobeRGB
}

// MARK: - CaptureMetadata

public struct CaptureMetadata: Codable, Sendable {
    public let width: Int
    public let height: Int
    public let colorSpace: ColorSpace
    public let captureDate: Date
    public let deviceModel: String

    // EXIF
    public var exposureTime: Double?
    public var iso: Int?
    public var focalLength: Double?
    public var aperture: Double?
    public var flashFired: Bool?

    // Video
    public var duration: TimeInterval?
    public var frameRate: Int?

    // GPS
    public var latitude: Double?
    public var longitude: Double?

    public nonisolated init(
        width: Int,
        height: Int,
        colorSpace: ColorSpace,
        captureDate: Date,
        deviceModel: String,
        exposureTime: Double? = nil,
        iso: Int? = nil,
        focalLength: Double? = nil,
        aperture: Double? = nil,
        flashFired: Bool? = nil,
        duration: TimeInterval? = nil,
        frameRate: Int? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.width = width
        self.height = height
        self.colorSpace = colorSpace
        self.captureDate = captureDate
        self.deviceModel = deviceModel
        self.exposureTime = exposureTime
        self.iso = iso
        self.focalLength = focalLength
        self.aperture = aperture
        self.flashFired = flashFired
        self.duration = duration
        self.frameRate = frameRate
        self.latitude = latitude
        self.longitude = longitude
    }

    public var aspectRatio: Double {
        guard height > 0 else { return 0 }
        return Double(width) / Double(height)
    }

    public var hasLocation: Bool {
        latitude != nil && longitude != nil
    }
}

// MARK: - Capture

public struct Capture: Identifiable, Codable, Sendable {
    public let id: UUID
    public let sampleId: UUID
    public let type: CaptureType
    public let fileURL: URL
    public var thumbnailURL: URL?
    public let metadata: CaptureMetadata
    public var fileSize: Int64
    public let createdAt: Date
    public let createdBy: UUID

    public init(
        id: UUID = UUID(),
        sampleId: UUID,
        type: CaptureType,
        fileURL: URL,
        thumbnailURL: URL? = nil,
        metadata: CaptureMetadata,
        fileSize: Int64 = 0,
        createdAt: Date = Date(),
        createdBy: UUID
    ) {
        self.id = id
        self.sampleId = sampleId
        self.type = type
        self.fileURL = fileURL
        self.thumbnailURL = thumbnailURL
        self.metadata = metadata
        self.fileSize = fileSize
        self.createdAt = createdAt
        self.createdBy = createdBy
    }

    public var formattedFileSize: String {
        if fileSize < 1024 {
            return "\(fileSize) B"
        } else if fileSize < 1024 * 1024 {
            return String(format: "%.1f KB", Double(fileSize) / 1024)
        } else {
            return String(format: "%.1f MB", Double(fileSize) / (1024 * 1024))
        }
    }
}

extension Capture: Equatable {
    public static func == (lhs: Capture, rhs: Capture) -> Bool {
        lhs.id == rhs.id
    }
}

extension Capture: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
