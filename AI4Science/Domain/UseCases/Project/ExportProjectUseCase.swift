import Foundation

/// Use case for exporting project data
@available(iOS 15.0, *)
public actor ExportProjectUseCase: Sendable {
    private let projectService: any ProjectServiceProtocol

    public init(projectService: any ProjectServiceProtocol) {
        self.projectService = projectService
    }

    /// Export project in specified format
    /// - Parameters:
    ///   - projectId: Project ID to export
    ///   - format: Export format (JSON, CSV, PDF, ZIP)
    /// - Returns: Exported data as bytes
    /// - Throws: ProjectError if export fails
    public func execute(projectId: String, format: ExportFormat) async throws -> Data {
        guard !projectId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ProjectError.projectNotFound
        }

        do {
            let data = try await projectService.exportProject(projectId: projectId, format: format)
            return data
        } catch let error as ProjectError {
            throw error
        } catch {
            throw ProjectError.unknownError(error.localizedDescription)
        }
    }

    /// Export project as JSON
    /// - Parameter projectId: Project ID to export
    /// - Returns: JSON data
    /// - Throws: ProjectError if export fails
    public func exportAsJSON(projectId: String) async throws -> Data {
        return try await execute(projectId: projectId, format: .json)
    }

    /// Export project as CSV
    /// - Parameter projectId: Project ID to export
    /// - Returns: CSV data
    /// - Throws: ProjectError if export fails
    public func exportAsCSV(projectId: String) async throws -> Data {
        return try await execute(projectId: projectId, format: .csv)
    }

    /// Export project as ZIP archive
    /// - Parameter projectId: Project ID to export
    /// - Returns: ZIP archive data
    /// - Throws: ProjectError if export fails
    public func exportAsZIP(projectId: String) async throws -> Data {
        return try await execute(projectId: projectId, format: .zip)
    }

    /// Export project as PDF report
    /// - Parameter projectId: Project ID to export
    /// - Returns: PDF data
    /// - Throws: ProjectError if export fails
    public func exportAsPDF(projectId: String) async throws -> Data {
        return try await execute(projectId: projectId, format: .pdf)
    }
}
