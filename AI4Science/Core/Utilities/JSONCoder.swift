import Foundation

/// Configured JSON encoder/decoder for the application
public struct JSONCoder: Sendable {
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.dataEncodingStrategy = .base64
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.dataDecodingStrategy = .base64
        return decoder
    }()

    private static let compactEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.dataEncodingStrategy = .base64
        return encoder
    }()

    /// Get configured JSON encoder
    public static var defaultEncoder: JSONEncoder {
        encoder
    }

    /// Get configured JSON decoder
    public static var defaultDecoder: JSONDecoder {
        decoder
    }

    /// Get compact JSON encoder (no formatting)
    public static var compactEncoder: JSONEncoder {
        compactEncoder
    }

    // MARK: - Encoding

    /// Encode object to JSON data
    static func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }

    /// Encode object to compact JSON data
    static func encodeCompact<T: Encodable>(_ value: T) throws -> Data {
        try compactEncoder.encode(value)
    }

    /// Encode object to JSON string
    static func encodeToString<T: Encodable>(_ value: T) throws -> String {
        let data = try encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw AppError.encodingError("Failed to convert data to string")
        }
        return string
    }

    /// Encode object to compact JSON string
    static func encodeToStringCompact<T: Encodable>(_ value: T) throws -> String {
        let data = try encodeCompact(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw AppError.encodingError("Failed to convert data to string")
        }
        return string
    }

    // MARK: - Decoding

    /// Decode object from JSON data
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch let error as DecodingError {
            throw AppError.from(error)
        }
    }

    /// Decode object from JSON string
    static func decodeFromString<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
        guard let data = string.data(using: .utf8) else {
            throw AppError.decodingError("Failed to convert string to data")
        }
        return try decode(type, from: data)
    }

    /// Decode object from file URL
    static func decodeFromFile<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        return try decode(type, from: data)
    }

    /// Decode array of objects from JSON data
    static func decodeArray<T: Decodable>(_ type: T.Type, from data: Data) throws -> [T] {
        do {
            return try decoder.decode([T].self, from: data)
        } catch let error as DecodingError {
            throw AppError.from(error)
        }
    }

    /// Decode dictionary from JSON data
    static func decodeDictionary(from data: Data) throws -> [String: Any] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AppError.decodingError("Invalid JSON structure")
        }
        return json
    }

    // MARK: - Pretty Printing

    /// Pretty print JSON data
    static func prettyPrint(_ data: Data) throws -> String {
        guard let object = try JSONSerialization.jsonObject(with: data) as? NSObject else {
            throw AppError.decodingError("Invalid JSON")
        }
        let prettyData = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
        guard let string = String(data: prettyData, encoding: .utf8) else {
            throw AppError.decodingError("Failed to convert to string")
        }
        return string
    }

    /// Pretty print JSON string
    static func prettyPrintString(_ jsonString: String) throws -> String {
        guard let data = jsonString.data(using: .utf8) else {
            throw AppError.decodingError("Failed to convert string to data")
        }
        return try prettyPrint(data)
    }

    // MARK: - Validation

    /// Validate JSON data
    static func isValidJSON(_ data: Data) -> Bool {
        (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    /// Validate JSON string
    static func isValidJSONString(_ string: String) -> Bool {
        guard let data = string.data(using: .utf8) else {
            return false
        }
        return isValidJSON(data)
    }

    /// Get JSON type
    static func getJSONType(_ data: Data) throws -> String {
        let object = try JSONSerialization.jsonObject(with: data)
        switch object {
        case is [String: Any]:
            return "object"
        case is [Any]:
            return "array"
        case is String:
            return "string"
        case is NSNumber:
            return "number"
        case is NSNull:
            return "null"
        default:
            return "unknown"
        }
    }
}

// MARK: - Convenience Extensions

public extension Encodable {
    /// Convert to JSON data
    func toJSONData() throws -> Data {
        try JSONCoder.encode(self)
    }

    /// Convert to compact JSON data
    func toJSONDataCompact() throws -> Data {
        try JSONCoder.encodeCompact(self)
    }

    /// Convert to JSON string
    func toJSONString() throws -> String {
        try JSONCoder.encodeToString(self)
    }

    /// Convert to compact JSON string
    func toJSONStringCompact() throws -> String {
        try JSONCoder.encodeToStringCompact(self)
    }
}

public extension Decodable {
    /// Create from JSON data
    static func fromJSONData(_ data: Data) throws -> Self {
        try JSONCoder.decode(Self.self, from: data)
    }

    /// Create from JSON string
    static func fromJSONString(_ string: String) throws -> Self {
        try JSONCoder.decodeFromString(Self.self, from: string)
    }

    /// Create from JSON file
    static func fromJSONFile(_ url: URL) throws -> Self {
        try JSONCoder.decodeFromFile(Self.self, from: url)
    }
}
