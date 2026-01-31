import Foundation

/// Domain-level capture service protocol
@available(iOS 15.0, *)
public protocol CaptureServiceProtocol: Sendable {
    /// Capture and process photo
    func capturePhoto(sampleId: String, metadata: CaptureServiceMetadata) async throws -> CaptureServiceResponse

    /// Record and process video
    func captureVideo(sampleId: String, duration: TimeInterval, metadata: CaptureServiceMetadata) async throws -> CaptureServiceResponse

    /// Fetch captures for sample
    func fetchCaptures(sampleId: String) async throws -> [CaptureServiceResponse]

    /// Fetch specific capture
    func fetchCapture(captureId: String) async throws -> CaptureServiceResponse

    /// Delete capture and associated files
    func deleteCapture(captureId: String) async throws

    /// Export capture with metadata
    func exportCapture(captureId: String, format: CaptureExportFormat) async throws -> Data

    /// Update capture metadata
    func updateCapture(_ request: CaptureUpdateRequest) async throws -> CaptureServiceResponse
}

/// Capture service response model (distinct from domain Capture)
public struct CaptureServiceResponse: Sendable {
    public let id: String
    public let sampleId: String
    public let projectId: String
    public let type: CaptureServiceType
    public let fileUrl: String
    public let thumbnailUrl: String?
    public let createdAt: Date
    public let updatedAt: Date
    public let metadata: CaptureServiceMetadata
    public let processingStatus: ProcessingStatus
    public let analysisResults: [CaptureAnalysisResult]

    public init(
        id: String,
        sampleId: String,
        projectId: String,
        type: CaptureServiceType,
        fileUrl: String,
        thumbnailUrl: String?,
        createdAt: Date,
        updatedAt: Date,
        metadata: CaptureServiceMetadata,
        processingStatus: ProcessingStatus,
        analysisResults: [CaptureAnalysisResult]
    ) {
        self.id = id
        self.sampleId = sampleId
        self.projectId = projectId
        self.type = type
        self.fileUrl = fileUrl
        self.thumbnailUrl = thumbnailUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
        self.processingStatus = processingStatus
        self.analysisResults = analysisResults
    }
}

/// Capture service type (distinct from domain CaptureType)
public enum CaptureServiceType: String, Sendable {
    case photo
    case video
    case scan
    case microscopy
}

/// Capture service metadata (distinct from domain CaptureMetadata)
public struct CaptureServiceMetadata: Sendable {
    public let deviceInfo: String
    public let location: CaptureLocation?
    public let lighting: LightingCondition?
    public let scale: Double?
    public let notes: String?
    public let tags: [String]
    public let customFields: [String: String]

    public nonisolated init(
        deviceInfo: String,
        location: CaptureLocation? = nil,
        lighting: LightingCondition? = nil,
        scale: Double? = nil,
        notes: String? = nil,
        tags: [String] = [],
        customFields: [String: String] = [:]
    ) {
        self.deviceInfo = deviceInfo
        self.location = location
        self.lighting = lighting
        self.scale = scale
        self.notes = notes
        self.tags = tags
        self.customFields = customFields
    }
}

/// Capture location
public struct CaptureLocation: Sendable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double?

    public nonisolated init(latitude: Double, longitude: Double, altitude: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
    }
}

/// Lighting condition
public enum LightingCondition: String, Sendable {
    case natural
    case artificial
    case mixed
    case led
    case fluorescent
}

/// Processing status
public enum ProcessingStatus: String, Sendable {
    case pending
    case processing
    case completed
    case failed
    case cancelled
}

/// Capture service analysis result (distinct from domain AnalysisResult)
public struct CaptureAnalysisResult: Sendable {
    public let id: String
    public let modelName: String
    public let timestamp: Date
    public let data: [String: AnyCodable]

    public init(id: String, modelName: String, timestamp: Date, data: [String: AnyCodable]) {
        self.id = id
        self.modelName = modelName
        self.timestamp = timestamp
        self.data = data
    }
}

/// Type-erased Codable value
public enum AnyCodable: Codable, Sendable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([AnyCodable])
    case object([String: AnyCodable])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([AnyCodable].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodable"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}

/// Update capture request (distinct from any conflicting types)
public struct CaptureUpdateRequest: Sendable {
    public let captureId: String
    public let metadata: CaptureServiceMetadata?

    public init(captureId: String, metadata: CaptureServiceMetadata? = nil) {
        self.captureId = captureId
        self.metadata = metadata
    }
}

/// Capture export format
public enum CaptureExportFormat: String, Sendable {
    case raw
    case zip
    case json
}

/// Capture errors
public enum CaptureError: LocalizedError, Sendable {
    case captureNotFound
    case captureFailure(String)
    case processingFailed(String)
    case fileNotFound
    case accessDenied
    case networkError(String)
    case unknownError(String)
    case validationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .captureNotFound:
            return "Capture not found"
        case .captureFailure(let message):
            return "Capture failed: \(message)"
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        case .fileNotFound:
            return "File not found"
        case .accessDenied:
            return "You do not have permission to access this capture"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknownError(let message):
            return "Error: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        }
    }
}

// MARK: - Conversion to Domain Model

extension CaptureServiceType {
    /// Convert to domain CaptureType
    public nonisolated func toDomainType() -> CaptureType {
        switch self {
        case .photo:
            return .photo
        case .video:
            return .video
        case .scan, .microscopy:
            return .photo // Map to photo as fallback
        }
    }
}

extension CaptureServiceResponse {
    /// Convert service response to domain Capture model
    public nonisolated func toDomainCapture() -> Capture {
        let captureType = type.toDomainType()

        // Build GeoLocation if available
        var geoLocation: GeoLocation?
        if let location = metadata.location {
            geoLocation = GeoLocation(
                latitude: location.latitude,
                longitude: location.longitude,
                altitude: location.altitude
            )
        }

        // Determine processing status
        let isProcessed = processingStatus == .completed
        let progress: Double
        switch processingStatus {
        case .pending:
            progress = 0.0
        case .processing:
            progress = 0.5
        case .completed:
            progress = 1.0
        case .failed, .cancelled:
            progress = 0.0
        }

        return Capture(
            id: UUID(uuidString: id) ?? UUID(),
            sampleID: UUID(uuidString: sampleId) ?? UUID(),
            type: captureType,
            fileURL: URL(fileURLWithPath: fileUrl),
            thumbnailURL: thumbnailUrl.flatMap { URL(string: $0) },
            mediaType: captureType == .video ? "video/mp4" : "image/jpeg",
            fileSize: 0, // Not available in service response
            duration: nil,
            resolution: nil,
            cameraModel: nil,
            lensModel: nil,
            focalLength: nil,
            exposureTime: nil,
            iso: nil,
            focusMode: nil,
            whiteBalance: nil,
            geoLocation: geoLocation,
            isProcessed: isProcessed,
            processingProgress: progress,
            metadata: metadata.customFields,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension Array where Element == CaptureServiceResponse {
    /// Convert array of service responses to domain Captures
    public nonisolated func toDomainCaptures() -> [Capture] {
        map { $0.toDomainCapture() }
    }
}
