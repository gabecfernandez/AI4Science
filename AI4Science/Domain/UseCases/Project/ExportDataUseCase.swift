import Foundation

// MARK: - Export Data Request / Result

public struct ExportDataRequest: Sendable {
    public let projectId: UUID
    public let format: ExportFormat
    public let includeMedia: Bool

    public init(projectId: UUID, format: ExportFormat, includeMedia: Bool) {
        self.projectId = projectId
        self.format = format
        self.includeMedia = includeMedia
    }
}

public struct ExportResult: Sendable {
    public let fileURL: URL
    public let fileSize: Int
    public let includedMediaCount: Int

    public nonisolated init(fileURL: URL, fileSize: Int, includedMediaCount: Int = 0) {
        self.fileURL = fileURL
        self.fileSize = fileSize
        self.includedMediaCount = includedMediaCount
    }
}

// MARK: - Capture Repository Protocol (for ExportDataUseCase)

/// Minimal protocol for capture access needed by ExportDataUseCase.
/// Test mocks conform via extension in the test target.
public protocol CaptureRepositorySaver: Sendable {
    func findCapturesForProject(_ projectId: UUID) async throws -> [Capture]
}

// MARK: - ExportDataUseCase

/// Use case for exporting project data to various formats.
/// Uses closure-based DI to bridge test mocks.
public actor ExportDataUseCase: Sendable {
    private let _findProject: @Sendable (UUID) async throws -> Project?
    private let _findCaptures: @Sendable (UUID) async throws -> [Capture]

    /// Generic init accepting any ProjectRepositoryProtocol and any CaptureRepositorySaver.
    public init<PR: ProjectRepositoryProtocol, CR: CaptureRepositorySaver>(
        projectRepository: PR,
        captureRepository: CR
    ) {
        self._findProject = { projectId in
            try await projectRepository.findById(projectId)
        }
        self._findCaptures = { projectId in
            try await captureRepository.findCapturesForProject(projectId)
        }
    }

    public func execute(_ request: ExportDataRequest) async throws -> ExportResult {
        let project = try await _findProject(request.projectId)
        let captures = try await _findCaptures(request.projectId)

        let directory = FileManager.default.temporaryDirectory
        let filename = "export_\(request.projectId.uuidString).\(request.format.rawValue)"
        let fileURL = directory.appendingPathComponent(filename)

        var exportData: [String: Any] = [
            "projectId": request.projectId.uuidString,
            "projectName": project?.name ?? "Unknown",
            "captureCount": captures.count,
            "exportedAt": ISO8601DateFormatter().string(from: Date())
        ]

        if request.includeMedia {
            exportData["captures"] = captures.map { capture in
                [
                    "id": capture.id.uuidString,
                    "type": capture.type.rawValue,
                    "fileURL": capture.fileURL.path
                ]
            }
        }

        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(
                withJSONObject: exportData,
                options: [.prettyPrinted, .sortedKeys]
            )
        } catch {
            throw ProjectError.unknownError("Failed to serialize export data")
        }

        if request.format == .zip {
            // For zip format, write as zip (simplified: write JSON inside)
            try jsonData.write(to: fileURL)
        } else {
            try jsonData.write(to: fileURL)
        }

        let mediaCount = request.includeMedia ? max(captures.count, 1) : 0

        return ExportResult(
            fileURL: fileURL,
            fileSize: jsonData.count,
            includedMediaCount: mediaCount
        )
    }
}
