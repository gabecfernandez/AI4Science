import Foundation

/// API endpoint definitions
struct APIEndpoints {
    /// Base API path
    static let apiVersion = "v1"

    // MARK: - User Endpoints

    /// Users collection
    static let users = "\(apiVersion)/users"

    /// Current user endpoint
    static let currentUser = "\(apiVersion)/users/me"

    /// User profile endpoint
    static func userProfile(id: String) -> String {
        "\(users)/\(id)"
    }

    /// User profile picture upload
    static func userProfilePicture(id: String) -> String {
        "\(users)/\(id)/profile-picture"
    }

    // MARK: - Project Endpoints

    /// Projects collection
    static let projects = "\(apiVersion)/projects"

    /// Project endpoint
    static func project(id: String) -> String {
        "\(projects)/\(id)"
    }

    /// Project samples
    static func projectSamples(id: String) -> String {
        "\(projects)/\(id)/samples"
    }

    /// Project metadata
    static func projectMetadata(id: String) -> String {
        "\(projects)/\(id)/metadata"
    }

    /// Archive project
    static func archiveProject(id: String) -> String {
        "\(projects)/\(id)/archive"
    }

    /// Unarchive project
    static func unarchiveProject(id: String) -> String {
        "\(projects)/\(id)/unarchive"
    }

    // MARK: - Sample Endpoints

    /// Samples collection
    static let samples = "\(apiVersion)/samples"

    /// Sample endpoint
    static func sample(id: String) -> String {
        "\(samples)/\(id)"
    }

    /// Sample captures
    static func sampleCaptures(id: String) -> String {
        "\(samples)/\(id)/captures"
    }

    /// Sample properties
    static func sampleProperties(id: String) -> String {
        "\(samples)/\(id)/properties"
    }

    // MARK: - Capture Endpoints

    /// Captures collection
    static let captures = "\(apiVersion)/captures"

    /// Capture endpoint
    static func capture(id: String) -> String {
        "\(captures)/\(id)"
    }

    /// Capture metadata
    static func captureMetadata(id: String) -> String {
        "\(captures)/\(id)/metadata"
    }

    /// Capture annotations
    static func captureAnnotations(id: String) -> String {
        "\(captures)/\(id)/annotations"
    }

    /// Upload capture
    static let uploadCapture = "\(apiVersion)/captures/upload"

    /// Download capture
    static func downloadCapture(id: String) -> String {
        "\(captures)/\(id)/download"
    }

    // MARK: - Annotation Endpoints

    /// Annotations collection
    static let annotations = "\(apiVersion)/annotations"

    /// Annotation endpoint
    static func annotation(id: String) -> String {
        "\(annotations)/\(id)"
    }

    // MARK: - Analysis Endpoints

    /// Analysis results collection
    static let analysisResults = "\(apiVersion)/analysis"

    /// Analysis result endpoint
    static func analysisResult(id: String) -> String {
        "\(analysisResults)/\(id)"
    }

    /// Start analysis
    static let startAnalysis = "\(apiVersion)/analysis/start"

    /// Analysis status
    static func analysisStatus(id: String) -> String {
        "\(analysisResults)/\(id)/status"
    }

    /// Analysis artifacts
    static func analysisArtifacts(id: String) -> String {
        "\(analysisResults)/\(id)/artifacts"
    }

    // MARK: - ML Model Endpoints

    /// ML models collection
    static let models = "\(apiVersion)/models"

    /// Model endpoint
    static func model(id: String) -> String {
        "\(models)/\(id)"
    }

    /// Model download
    static func downloadModel(id: String) -> String {
        "\(models)/\(id)/download"
    }

    /// Model metadata
    static func modelMetadata(id: String) -> String {
        "\(models)/\(id)/metadata"
    }

    /// Model configs
    static func modelConfigs(id: String) -> String {
        "\(models)/\(id)/configs"
    }

    // MARK: - Authentication Endpoints

    /// Login endpoint
    static let login = "\(apiVersion)/auth/login"

    /// Logout endpoint
    static let logout = "\(apiVersion)/auth/logout"

    /// Refresh token endpoint
    static let refreshToken = "\(apiVersion)/auth/refresh"

    /// Register endpoint
    static let register = "\(apiVersion)/auth/register"

    /// Verify email endpoint
    static let verifyEmail = "\(apiVersion)/auth/verify-email"

    // MARK: - Sync Endpoints

    /// Sync queue endpoint
    static let syncQueue = "\(apiVersion)/sync/queue"

    /// Sync status endpoint
    static let syncStatus = "\(apiVersion)/sync/status"

    /// Force sync endpoint
    static let forceSync = "\(apiVersion)/sync/force"

    // MARK: - Search Endpoints

    /// Search endpoint
    static let search = "\(apiVersion)/search"

    /// Search projects
    static let searchProjects = "\(search)/projects"

    /// Search samples
    static let searchSamples = "\(search)/samples"

    /// Search captures
    static let searchCaptures = "\(search)/captures"

    // MARK: - Helper Methods

    /// Build query parameters string
    static func queryParameters(_ params: [String: String]) -> String {
        guard !params.isEmpty else { return "" }

        let pairs = params.map { "\($0.key)=\($0.value)" }
        return "?" + pairs.joined(separator: "&")
    }

    /// Build pagination parameters
    static func paginationParams(page: Int = 1, pageSize: Int = 20) -> String {
        queryParameters([
            "page": "\(page)",
            "pageSize": "\(pageSize)"
        ])
    }

    /// Build search parameters
    static func searchParams(query: String, type: String? = nil) -> String {
        var params: [String: String] = ["q": query]
        if let type = type {
            params["type"] = type
        }
        return queryParameters(params)
    }
}

/// API configuration
struct APIConfiguration {
    let baseURL: URL
    let timeout: TimeInterval
    let retryCount: Int
    let retryDelay: TimeInterval

    static let `default` = APIConfiguration(
        baseURL: URL(string: "https://api.ai4science.com")!,
        timeout: 30,
        retryCount: 3,
        retryDelay: 1.0
    )

    static let development = APIConfiguration(
        baseURL: URL(string: "http://localhost:8080")!,
        timeout: 30,
        retryCount: 5,
        retryDelay: 0.5
    )
}
