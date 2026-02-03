import Foundation

/// Protocol for remote data source operations
/// Note: Protocol and implementations are MainActor-isolated
@MainActor
protocol RemoteDataSourceProtocol {
    associatedtype Model: Codable

    func create(_ model: Model) async throws -> Model
    func read(id: String) async throws -> Model
    func update(_ model: Model) async throws -> Model
    func delete(id: String) async throws
    func readAll(page: Int, pageSize: Int) async throws -> [Model]
}

/// Base remote data source
@MainActor
final class RemoteDataSource<T: Codable & Sendable>: RemoteDataSourceProtocol {
    typealias Model = T

    private let apiClient: APIClient
    private let endpoint: String

    init(apiClient: APIClient, endpoint: String) {
        self.apiClient = apiClient
        self.endpoint = endpoint
    }

    func create(_ model: T) async throws -> T {
        let response: T = try await apiClient.post(
            endpoint: endpoint,
            body: model
        )
        return response
    }

    func read(id: String) async throws -> T {
        let path = "\(endpoint)/\(id)"
        return try await apiClient.get(endpoint: path)
    }

    func update(_ model: T) async throws -> T {
        let response: T = try await apiClient.put(
            endpoint: endpoint,
            body: model
        )
        return response
    }

    func delete(id: String) async throws {
        let path = "\(endpoint)/\(id)"
        try await apiClient.delete(endpoint: path)
    }

    func readAll(page: Int = 1, pageSize: Int = 20) async throws -> [T] {
        let path = "\(endpoint)?page=\(page)&pageSize=\(pageSize)"
        return try await apiClient.get(endpoint: path)
    }
}

/// User remote data source
@MainActor
final class UserRemoteDataSource: RemoteDataSourceProtocol {
    typealias Model = UserDTO

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func create(_ model: UserDTO) async throws -> UserDTO {
        try await apiClient.post(
            endpoint: APIEndpoints.users,
            body: model
        )
    }

    func read(id: String) async throws -> UserDTO {
        try await apiClient.get(endpoint: "\(APIEndpoints.users)/\(id)")
    }

    func update(_ model: UserDTO) async throws -> UserDTO {
        try await apiClient.put(
            endpoint: "\(APIEndpoints.users)/\(model.id)",
            body: model
        )
    }

    func delete(id: String) async throws {
        try await apiClient.delete(endpoint: "\(APIEndpoints.users)/\(id)")
    }

    func readAll(page: Int = 1, pageSize: Int = 20) async throws -> [UserDTO] {
        try await apiClient.get(
            endpoint: "\(APIEndpoints.users)?page=\(page)&pageSize=\(pageSize)"
        )
    }
}

/// Project remote data source
@MainActor
final class ProjectRemoteDataSource: RemoteDataSourceProtocol {
    typealias Model = ProjectDTO

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func create(_ model: ProjectDTO) async throws -> ProjectDTO {
        try await apiClient.post(
            endpoint: APIEndpoints.projects,
            body: model
        )
    }

    func read(id: String) async throws -> ProjectDTO {
        try await apiClient.get(endpoint: "\(APIEndpoints.projects)/\(id)")
    }

    func update(_ model: ProjectDTO) async throws -> ProjectDTO {
        try await apiClient.put(
            endpoint: "\(APIEndpoints.projects)/\(model.id)",
            body: model
        )
    }

    func delete(id: String) async throws {
        try await apiClient.delete(endpoint: "\(APIEndpoints.projects)/\(id)")
    }

    func readAll(page: Int = 1, pageSize: Int = 20) async throws -> [ProjectDTO] {
        try await apiClient.get(
            endpoint: "\(APIEndpoints.projects)?page=\(page)&pageSize=\(pageSize)"
        )
    }
}

// MARK: - Data Transfer Objects

/// Data transfer objects for API communication
/// These are value types for API communication - marked nonisolated to avoid
/// MainActor-isolated Codable conformance issues
nonisolated struct UserDTO: Codable, Sendable {
    let id: String
    let email: String
    let fullName: String
    let institution: String?
    let profileImageURL: String?
    let createdAt: Date
    let updatedAt: Date
}

nonisolated struct ProjectDTO: Codable, Sendable {
    let id: String
    let name: String
    let description: String
    let projectType: String
    let createdAt: Date
    let updatedAt: Date
}

nonisolated struct CaptureDTO: Codable, Sendable {
    let id: String
    let captureType: String
    let capturedAt: Date
    let createdAt: Date
    let updatedAt: Date
}

nonisolated struct AnalysisResultDTO: Codable, Sendable {
    let id: String
    let modelID: String
    let analysisType: String
    let status: String
    let startedAt: Date
    let completedAt: Date?
}
