import Foundation

/// API Client with authentication token support
actor AuthenticatedAPIClient {
    // MARK: - Properties

    private let apiClient: APIClient
    private let requestBuilder: APIRequestBuilder
    private let responseHandler: APIResponseHandler
    private var authToken: String?
    private var tokenRefreshHandler: (() async throws -> String)?

    // MARK: - Initialization

    init(
        baseURL: URL,
        authToken: String? = nil
    ) {
        self.apiClient = APIClient(baseURL: baseURL)
        self.requestBuilder = APIRequestBuilder(baseURL: baseURL)
        self.responseHandler = APIResponseHandler()
        self.authToken = authToken
    }

    // MARK: - Public Methods

    /// Set authentication token
    /// - Parameter token: Bearer token
    func setAuthToken(_ token: String) {
        self.authToken = token
    }

    /// Clear authentication token
    func clearAuthToken() {
        self.authToken = nil
    }

    /// Set token refresh handler
    /// - Parameter handler: Closure that returns refreshed token
    func setTokenRefreshHandler(_ handler: @escaping () async throws -> String) {
        self.tokenRefreshHandler = handler
    }

    /// Perform authenticated GET request
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - responseType: Expected response type
    /// - Returns: Decoded response
    func get<T: Decodable>(
        endpoint: String,
        as responseType: T.Type
    ) async throws -> T {
        let request = try buildAuthenticatedRequest(method: "GET", endpoint: endpoint)
        let (data, response) = try await URLSession.shared.data(for: request)
        try responseHandler.parseResponse(data, response: response)
        return try responseHandler.decode(data, as: responseType)
    }

    /// Perform authenticated POST request
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - body: Request body
    ///   - responseType: Expected response type
    /// - Returns: Decoded response
    func post<T: Encodable, R: Decodable>(
        endpoint: String,
        body: T,
        as responseType: R.Type
    ) async throws -> R {
        let bodyData = try responseHandler.encode(body)
        let request = try buildAuthenticatedRequest(
            method: "POST",
            endpoint: endpoint,
            body: bodyData
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        try responseHandler.parseResponse(data, response: response)
        return try responseHandler.decode(data, as: responseType)
    }

    /// Perform authenticated PUT request
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - body: Request body
    ///   - responseType: Expected response type
    /// - Returns: Decoded response
    func put<T: Encodable, R: Decodable>(
        endpoint: String,
        body: T,
        as responseType: R.Type
    ) async throws -> R {
        let bodyData = try responseHandler.encode(body)
        let request = try buildAuthenticatedRequest(
            method: "PUT",
            endpoint: endpoint,
            body: bodyData
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        try responseHandler.parseResponse(data, response: response)
        return try responseHandler.decode(data, as: responseType)
    }

    /// Perform authenticated DELETE request
    /// - Parameter endpoint: API endpoint
    func delete(endpoint: String) async throws {
        let request = try buildAuthenticatedRequest(method: "DELETE", endpoint: endpoint)
        let (data, response) = try await URLSession.shared.data(for: request)
        try responseHandler.parseResponse(data, response: response)
    }

    /// Perform authenticated request with custom handling
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - method: HTTP method
    ///   - body: Optional request body
    /// - Returns: Response data and HTTPURLResponse
    func performRequest(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> (data: Data, response: HTTPURLResponse) {
        let request = try buildAuthenticatedRequest(
            method: method,
            endpoint: endpoint,
            body: body
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        try responseHandler.parseResponse(data, response: httpResponse)

        return (data, httpResponse)
    }

    // MARK: - Private Methods

    private func buildAuthenticatedRequest(
        method: String,
        endpoint: String,
        body: Data? = nil
    ) throws -> URLRequest {
        guard let token = authToken else {
            throw APIError.unauthorized
        }

        var builder = APIRequestBuilder(baseURL: URL(string: "http://api.ai4science.com") ?? URL(fileURLWithPath: ""))
        builder.addAuthHeader(token)

        let request: URLRequest

        switch method {
        case "GET":
            request = try builder.buildGET(endpoint: endpoint)
        case "POST":
            request = try builder.buildPOST(endpoint: endpoint, body: body)
        case "PUT":
            request = try builder.buildPUT(endpoint: endpoint, body: body)
        case "DELETE":
            request = try builder.buildDELETE(endpoint: endpoint)
        case "PATCH":
            request = try builder.buildPATCH(endpoint: endpoint, body: body)
        default:
            throw APIError.invalidURL
        }

        return request
    }

    private func refreshTokenIfNeeded() async throws -> String {
        guard let handler = tokenRefreshHandler else {
            throw APIError.unauthorized
        }

        let newToken = try await handler()
        self.authToken = newToken
        return newToken
    }
}

// MARK: - Authentication Models

/// Authentication credentials
struct AuthCredentials: Codable, Sendable {
    let email: String
    let password: String
}

/// Authentication response
struct AuthResponse: Codable, Sendable {
    let token: String
    let refreshToken: String?
    let expiresIn: Int?
    let user: UserDTO?
}

/// User DTO for API responses
struct UserDTO: Codable, Sendable {
    let id: String
    let email: String
    let fullName: String
    let institution: String?
}

/// Token validation result
struct TokenValidation: Sendable {
    let isValid: Bool
    let isExpired: Bool
    let expiresAt: Date?
}
