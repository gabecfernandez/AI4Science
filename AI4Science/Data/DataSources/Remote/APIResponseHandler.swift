import Foundation

/// Handler for parsing API responses
actor APIResponseHandler {
    // MARK: - Properties

    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Initialization

    init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    // MARK: - Public Methods

    /// Decode response data
    /// - Parameters:
    ///   - data: Response data
    ///   - type: Expected response type
    /// - Returns: Decoded object
    func decode<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch let DecodingError.dataCorrupted(context) {
            AppLogger.error("Data corrupted: \(context.debugDescription)")
            throw APIError.decodingError
        } catch let DecodingError.keyNotFound(key, context) {
            AppLogger.error("Key not found: \(key), \(context.debugDescription)")
            throw APIError.decodingError
        } catch let DecodingError.typeMismatch(type, context) {
            AppLogger.error("Type mismatch: \(type), \(context.debugDescription)")
            throw APIError.decodingError
        } catch let DecodingError.valueNotFound(type, context) {
            AppLogger.error("Value not found: \(type), \(context.debugDescription)")
            throw APIError.decodingError
        } catch {
            AppLogger.error("Decoding failed: \(error.localizedDescription)")
            throw APIError.decodingError
        }
    }

    /// Encode object to data
    /// - Parameter object: Object to encode
    /// - Returns: Encoded data
    func encode<T: Encodable>(_ object: T) throws -> Data {
        do {
            return try encoder.encode(object)
        } catch {
            AppLogger.error("Encoding failed: \(error.localizedDescription)")
            throw APIError.encodingError
        }
    }

    /// Parse generic API response
    /// - Parameters:
    ///   - data: Response data
    ///   - response: URLResponse
    /// - Returns: Parsed response
    func parseResponse(_ data: Data, response: URLResponse) throws -> APIResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try parseSuccessResponse(data)
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 503:
            throw APIError.serverUnavailable
        case 500...599:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    /// Get JSON from response
    /// - Parameter data: Response data
    /// - Returns: JSON dictionary
    func getJSON(_ data: Data) throws -> [String: Any] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        return json
    }

    /// Get JSON array from response
    /// - Parameter data: Response data
    /// - Returns: JSON array
    func getJSONArray(_ data: Data) throws -> [[String: Any]] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw APIError.invalidResponse
        }
        return json
    }

    /// Create pagination info from headers
    /// - Parameter response: HTTP response
    /// - Returns: Pagination info
    func extractPaginationInfo(from response: HTTPURLResponse) -> PaginationInfo {
        var pageInfo = PaginationInfo()

        if let linkHeader = response.value(forHTTPHeaderField: "Link") {
            parseLinkHeader(linkHeader, into: &pageInfo)
        }

        if let pageHeader = response.value(forHTTPHeaderField: "X-Page") {
            pageInfo.currentPage = Int(pageHeader)
        }

        if let perPageHeader = response.value(forHTTPHeaderField: "X-Per-Page") {
            pageInfo.itemsPerPage = Int(perPageHeader)
        }

        if let totalHeader = response.value(forHTTPHeaderField: "X-Total") {
            pageInfo.totalItems = Int(totalHeader)
        }

        return pageInfo
    }

    // MARK: - Private Methods

    private func parseSuccessResponse(_ data: Data) throws -> APIResponse {
        let json = try getJSON(data)

        let statusCode: Int
        if let code = json["code"] as? Int {
            statusCode = code
        } else if let code = json["status"] as? Int {
            statusCode = code
        } else {
            statusCode = 200
        }

        let message = (json["message"] as? String) ?? (json["msg"] as? String) ?? "Success"
        let result = json["data"] ?? json["result"]

        return APIResponse(
            statusCode: statusCode,
            message: message,
            data: result,
            timestamp: Date()
        )
    }

    private func parseLinkHeader(_ header: String, into pageInfo: inout PaginationInfo) {
        let links = header.split(separator: ",")

        for link in links {
            let parts = link.split(separator: ";")
            if parts.count >= 2 {
                let urlPart = String(parts[0]).trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
                let relPart = String(parts[1]).trimmingCharacters(in: .whitespaces)

                if relPart.contains("next") {
                    pageInfo.nextURL = urlPart
                } else if relPart.contains("prev") {
                    pageInfo.previousURL = urlPart
                } else if relPart.contains("last") {
                    pageInfo.lastURL = urlPart
                } else if relPart.contains("first") {
                    pageInfo.firstURL = urlPart
                }
            }
        }
    }
}

// MARK: - Models

/// Generic API response
struct APIResponse: @unchecked Sendable {
    let statusCode: Int
    let message: String
    nonisolated(unsafe) let data: Any?
    let timestamp: Date

    nonisolated init(statusCode: Int, message: String, data: Any?, timestamp: Date) {
        self.statusCode = statusCode
        self.message = message
        self.data = data
        self.timestamp = timestamp
    }
}

/// Pagination information
struct PaginationInfo: Sendable {
    var currentPage: Int?
    var itemsPerPage: Int?
    var totalItems: Int?
    var nextURL: String?
    var previousURL: String?
    var firstURL: String?
    var lastURL: String?

    var totalPages: Int? {
        guard let total = totalItems, let perPage = itemsPerPage else {
            return nil
        }
        return (total + perPage - 1) / perPage
    }

    var hasNextPage: Bool {
        nextURL != nil
    }

    var hasPreviousPage: Bool {
        previousURL != nil
    }
}
