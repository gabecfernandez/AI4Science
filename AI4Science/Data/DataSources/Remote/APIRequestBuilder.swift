import Foundation

/// Builder for constructing API requests
struct APIRequestBuilder: @unchecked Sendable {
    // MARK: - Properties

    private let baseURL: URL
    private var headers: [String: String] = [:]
    private var queryParameters: [String: String] = [:]

    // MARK: - Initialization

    nonisolated init(baseURL: URL) {
        self.baseURL = baseURL
        self.headers = ["Accept": "application/json", "User-Agent": "AI4Science/1.0"]
        self.queryParameters = [:]
    }

    // MARK: - Public Methods

    /// Add header to request
    @discardableResult
    nonisolated mutating func addHeader(_ key: String, _ value: String) -> Self {
        headers[key] = value
        return self
    }

    /// Add authentication header
    @discardableResult
    nonisolated mutating func addAuthHeader(_ token: String) -> Self {
        headers["Authorization"] = "Bearer \(token)"
        return self
    }

    /// Add query parameter
    @discardableResult
    nonisolated mutating func addQueryParameter(_ key: String, _ value: String) -> Self {
        queryParameters[key] = value
        return self
    }

    /// Add query parameters from dictionary
    @discardableResult
    nonisolated mutating func addQueryParameters(_ parameters: [String: String]) -> Self {
        for (key, value) in parameters {
            queryParameters[key] = value
        }
        return self
    }

    /// Build GET request
    nonisolated func buildGET(endpoint: String) throws -> URLRequest {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(&request)
        return request
    }

    /// Build POST request
    nonisolated func buildPOST(endpoint: String, body: Data?) throws -> URLRequest {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyHeaders(&request)
        return request
    }

    /// Build PUT request
    nonisolated func buildPUT(endpoint: String, body: Data?) throws -> URLRequest {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyHeaders(&request)
        return request
    }

    /// Build DELETE request
    nonisolated func buildDELETE(endpoint: String) throws -> URLRequest {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        applyHeaders(&request)
        return request
    }

    /// Build PATCH request
    nonisolated func buildPATCH(endpoint: String, body: Data?) throws -> URLRequest {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyHeaders(&request)
        return request
    }

    // MARK: - Private Methods

    private nonisolated func buildURL(endpoint: String) throws -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)

        let currentPath = components?.path ?? ""
        components?.path = currentPath.isEmpty ? endpoint : "\(currentPath)/\(endpoint)"

        if !queryParameters.isEmpty {
            components?.queryItems = queryParameters.map { key, value in
                URLQueryItem(name: key, value: value)
            }
        }

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        return url
    }

    private nonisolated func applyHeaders(_ request: inout URLRequest) {
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
}

/// API Request DTO
struct APIRequest<T: Encodable>: Sendable {
    let method: String
    let endpoint: String
    let headers: [String: String]
    let body: T?

    init(
        method: String,
        endpoint: String,
        headers: [String: String] = [:],
        body: T? = nil
    ) {
        self.method = method
        self.endpoint = endpoint
        self.headers = headers
        self.body = body
    }
}
