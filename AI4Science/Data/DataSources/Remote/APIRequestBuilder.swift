import Foundation

/// Builder for constructing API requests
actor APIRequestBuilder {
    // MARK: - Properties

    private let baseURL: URL
    private var headers: [String: String] = [:]
    private var queryParameters: [String: String] = [:]

    // MARK: - Initialization

    init(baseURL: URL) {
        self.baseURL = baseURL
        // Set default headers directly - actor hasn't started yet
        self.headers["Accept"] = "application/json"
        self.headers["User-Agent"] = "AI4Science/1.0"
    }

    // MARK: - Public Methods

    /// Add header to request
    /// - Parameters:
    ///   - key: Header key
    ///   - value: Header value
    @discardableResult
    func addHeader(_ key: String, _ value: String) -> Self {
        headers[key] = value
        return self
    }

    /// Add authentication header
    /// - Parameter token: Bearer token
    @discardableResult
    func addAuthHeader(_ token: String) -> Self {
        addHeader("Authorization", "Bearer \(token)")
        return self
    }

    /// Add query parameter
    /// - Parameters:
    ///   - key: Parameter key
    ///   - value: Parameter value
    @discardableResult
    func addQueryParameter(_ key: String, _ value: String) -> Self {
        queryParameters[key] = value
        return self
    }

    /// Add query parameters from dictionary
    /// - Parameter parameters: Dictionary of parameters
    @discardableResult
    func addQueryParameters(_ parameters: [String: String]) -> Self {
        for (key, value) in parameters {
            queryParameters[key] = value
        }
        return self
    }

    /// Build GET request
    /// - Parameter endpoint: API endpoint path
    /// - Returns: URLRequest
    func buildGET(endpoint: String) throws -> URLRequest {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(&request)
        return request
    }

    /// Build POST request
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - body: Request body data
    /// - Returns: URLRequest
    func buildPOST(endpoint: String, body: Data?) throws -> URLRequest {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyHeaders(&request)
        return request
    }

    /// Build PUT request
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - body: Request body data
    /// - Returns: URLRequest
    func buildPUT(endpoint: String, body: Data?) throws -> URLRequest {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyHeaders(&request)
        return request
    }

    /// Build DELETE request
    /// - Parameter endpoint: API endpoint path
    /// - Returns: URLRequest
    func buildDELETE(endpoint: String) throws -> URLRequest {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        applyHeaders(&request)
        return request
    }

    /// Build PATCH request
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - body: Request body data
    /// - Returns: URLRequest
    func buildPATCH(endpoint: String, body: Data?) throws -> URLRequest {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyHeaders(&request)
        return request
    }

    // MARK: - Private Methods

    private func setDefaultHeaders() {
        headers["Accept"] = "application/json"
        headers["User-Agent"] = "AI4Science/1.0"
    }

    private func buildURL(endpoint: String) throws -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)

        // Append endpoint to path
        let currentPath = components?.path ?? ""
        components?.path = currentPath.isEmpty ? endpoint : "\(currentPath)/\(endpoint)"

        // Add query parameters
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

    private func applyHeaders(_ request: inout URLRequest) {
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
