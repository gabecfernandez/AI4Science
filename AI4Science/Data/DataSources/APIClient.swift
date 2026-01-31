import Foundation

/// Error types for API operations
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case encodingError
    case networkError(Error)
    case serverError(statusCode: Int)
    case unauthorized
    case notFound
    case serverUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        case .unauthorized:
            return "Unauthorized access"
        case .notFound:
            return "Resource not found"
        case .serverUnavailable:
            return "Server is unavailable"
        }
    }
}

/// API Client for making network requests
actor APIClient {
    private let baseURL: URL
    private let urlSession: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL,
        urlSession: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    /// Perform GET request
    func get<T: Decodable>(endpoint: String) async throws -> T {
        let url = try buildURL(endpoint: endpoint)
        let (data, response) = try await urlSession.data(from: url)

        try validateResponse(response)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    /// Perform POST request
    func post<T: Encodable, R: Decodable>(
        endpoint: String,
        body: T
    ) async throws -> R {
        let url = try buildURL(endpoint: endpoint)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.encodingError
        }

        let (data, response) = try await urlSession.data(for: request)

        try validateResponse(response)

        do {
            return try decoder.decode(R.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    /// Perform POST request without response body
    func post<T: Encodable>(
        endpoint: String,
        body: T
    ) async throws {
        let url = try buildURL(endpoint: endpoint)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.encodingError
        }

        let (_, response) = try await urlSession.data(for: request)

        try validateResponse(response)
    }

    /// Perform PUT request
    func put<T: Encodable, R: Decodable>(
        endpoint: String,
        body: T
    ) async throws -> R {
        let url = try buildURL(endpoint: endpoint)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.encodingError
        }

        let (data, response) = try await urlSession.data(for: request)

        try validateResponse(response)

        do {
            return try decoder.decode(R.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    /// Perform DELETE request
    func delete(endpoint: String) async throws {
        let url = try buildURL(endpoint: endpoint)

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await urlSession.data(for: request)

        try validateResponse(response)
    }

    /// Build URL from endpoint
    private func buildURL(endpoint: String) throws -> URL {
        let fullPath = baseURL.appendingPathComponent(endpoint).absoluteString
        guard let url = URL(string: fullPath) else {
            throw APIError.invalidURL
        }
        return url
    }

    /// Validate HTTP response
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
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
}

/// API Client Factory
struct APIClientFactory {
    static func makeClient(baseURL: URL) -> APIClient {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        configuration.waitsForConnectivity = true

        let urlSession = URLSession(configuration: configuration)
        return APIClient(baseURL: baseURL, urlSession: urlSession)
    }

    static func makeClient(baseURLString: String) throws -> APIClient {
        guard let baseURL = URL(string: baseURLString) else {
            throw APIError.invalidURL
        }
        return makeClient(baseURL: baseURL)
    }
}
