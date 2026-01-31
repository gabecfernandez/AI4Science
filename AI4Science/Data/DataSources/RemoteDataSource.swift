import Foundation

/// Data transfer objects for remote API communication

struct CaptureDTO: Codable, Sendable {
    let id: String
    let captureType: String
    let capturedAt: Date
    let createdAt: Date
    let updatedAt: Date
}

struct AnalysisResultDTO: Codable, Sendable {
    let id: String
    let modelID: String
    let analysisType: String
    let status: String
    let startedAt: Date
    let completedAt: Date?
}

struct ProjectDTO: Codable, Sendable {
    let id: String
    let name: String
    let description: String
    let projectType: String
    let createdAt: Date
    let updatedAt: Date
}
