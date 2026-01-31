import Foundation

/// Domain-level capture service protocol
@available(iOS 15.0, *)
public protocol CaptureServiceProtocol: Sendable {
    /// Capture and process photo
    func capturePhoto(sampleId: String, metadata: CaptureMetadata) async throws -> Capture

    /// Record and process video
    func captureVideo(sampleId: String, duration: TimeInterval, metadata: CaptureMetadata) async throws -> Capture

    /// Fetch captures for sample
    func fetchCaptures(sampleId: String) async throws -> [Capture]

    /// Fetch specific capture
    func fetchCapture(captureId: String) async throws -> Capture

    /// Delete capture and associated files
    func deleteCapture(captureId: String) async throws

    /// Export capture with metadata
    func exportCapture(captureId: String, format: CaptureExportFormat) async throws -> Data

    /// Update capture metadata
    func updateCapture(_ request: UpdateCaptureRequest) async throws -> Capture
}

/// Capture location
public struct CaptureLocation: Sendable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double?

    public init(latitude: Double, longitude: Double, altitude: Double? = nil) {
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

/// Update capture request
public struct UpdateCaptureRequest: Sendable {
    public let captureId: String
    public let metadata: CaptureMetadata?

    public init(captureId: String, metadata: CaptureMetadata? = nil) {
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
        }
    }
}
