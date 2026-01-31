import Foundation

/// Type of media capture
@frozen
public enum CaptureType: String, Codable, Sendable, CaseIterable {
    case photo
    case video
    case burst
}

/// Represents a photo or video capture of a sample
public struct Capture: Identifiable, Codable, Sendable {
    public let id: UUID
    public var sampleID: UUID
    public var type: CaptureType
    public var fileURL: URL
    public var thumbnailURL: URL?
    public var mediaType: String // e.g., "image/jpeg", "video/mp4"
    public var fileSize: Int64
    public var duration: TimeInterval? // for videos
    public var resolution: CGSize?
    public var cameraModel: String?
    public var lensModel: String?
    public var focalLength: Double?
    public var exposureTime: Double?
    public var iso: Int?
    public var focusMode: String?
    public var whiteBalance: String?
    public var geoLocation: GeoLocation?
    public var isProcessed: Bool
    public var processingProgress: Double
    public var metadata: [String: String]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        sampleID: UUID,
        type: CaptureType,
        fileURL: URL,
        thumbnailURL: URL? = nil,
        mediaType: String,
        fileSize: Int64,
        duration: TimeInterval? = nil,
        resolution: CGSize? = nil,
        cameraModel: String? = nil,
        lensModel: String? = nil,
        focalLength: Double? = nil,
        exposureTime: Double? = nil,
        iso: Int? = nil,
        focusMode: String? = nil,
        whiteBalance: String? = nil,
        geoLocation: GeoLocation? = nil,
        isProcessed: Bool = false,
        processingProgress: Double = 0,
        metadata: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.sampleID = sampleID
        self.type = type
        self.fileURL = fileURL
        self.thumbnailURL = thumbnailURL
        self.mediaType = mediaType
        self.fileSize = fileSize
        self.duration = duration
        self.resolution = resolution
        self.cameraModel = cameraModel
        self.lensModel = lensModel
        self.focalLength = focalLength
        self.exposureTime = exposureTime
        self.iso = iso
        self.focusMode = focusMode
        self.whiteBalance = whiteBalance
        self.geoLocation = geoLocation
        self.isProcessed = isProcessed
        self.processingProgress = processingProgress
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isVideo: Bool {
        type == .video
    }
}

/// Geographic location data
public struct GeoLocation: Codable, Sendable {
    public var latitude: Double
    public var longitude: Double
    public var altitude: Double?
    public var accuracy: Double?

    public init(latitude: Double, longitude: Double, altitude: Double? = nil, accuracy: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.accuracy = accuracy
    }
}

// MARK: - Equatable
extension Capture: Equatable {
    public static func == (lhs: Capture, rhs: Capture) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Capture: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension GeoLocation: Equatable, Hashable {}
