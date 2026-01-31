import ResearchKit
import Foundation

/// Manages research study lifecycle and task progression
@MainActor
final class StudyManager: NSObject {
    // MARK: - Singleton

    static let shared = StudyManager()

    // MARK: - Properties

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var activeStudies: [String: StudySession] = [:]
    private var taskCache: [String: ORKTask] = [:]

    private let studyQueue = DispatchQueue(
        label: "com.ai4science.study.manager",
        qos: .userInitiated
    )

    // MARK: - Study Initialization

    /// Initialize a new study session
    func initializeStudy(
        _ study: Study,
        participantID: String
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            studyQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ResearchError.noActiveStudy)
                    return
                }

                do {
                    let session = StudySession(
                        study: study,
                        participantID: participantID,
                        startDate: Date()
                    )
                    self.activeStudies[study.id] = session

                    // Create study directory structure
                    try self.createStudyDirectories(for: study.id)

                    // Save study metadata
                    try self.saveStudyMetadata(session)

                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Load existing study
    func loadStudy(_ study: Study) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            studyQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ResearchError.noActiveStudy)
                    return
                }

                do {
                    let session = try self.loadStudySession(study.id)
                    self.activeStudies[study.id] = session
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Task Management

    /// Get next task in study protocol
    func getNextTask(for study: Study) async throws -> ORKTask {
        return try await withCheckedThrowingContinuation { continuation in
            studyQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ResearchError.noActiveStudy)
                    return
                }

                do {
                    guard let session = self.activeStudies[study.id] else {
                        throw ResearchError.noActiveStudy
                    }

                    let task = try self.buildNextTask(
                        for: study,
                        session: session
                    )
                    continuation.resume(returning: task)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Get all tasks for study
    func getAllTasks(for study: Study) async throws -> [ORKTask] {
        return try await withCheckedThrowingContinuation { continuation in
            studyQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ResearchError.noActiveStudy)
                    return
                }

                do {
                    let tasks = try self.buildAllTasks(for: study)
                    continuation.resume(returning: tasks)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Get specific task by ID
    func getTask(withID taskID: String, from study: Study) async throws -> ORKTask {
        return try await withCheckedThrowingContinuation { continuation in
            studyQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ResearchError.noActiveStudy)
                    return
                }

                do {
                    if let cached = self.taskCache[taskID] {
                        continuation.resume(returning: cached)
                        return
                    }

                    let task = try self.buildTask(withID: taskID, from: study)
                    self.taskCache[taskID] = task
                    continuation.resume(returning: task)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Result Handling

    /// Save task result
    func saveResult(_ result: ProcessedResult) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            studyQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ResearchError.noActiveStudy)
                    return
                }

                do {
                    try self.persistResult(result)

                    if let session = self.activeStudies[result.studyID] {
                        var updatedSession = session
                        updatedSession.completedTaskIDs.insert(result.taskID)
                        updatedSession.results.append(result)
                        self.activeStudies[result.studyID] = updatedSession
                    }

                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Get all results for study
    func getResults(for studyID: String) async throws -> [ProcessedResult] {
        return try await withCheckedThrowingContinuation { continuation in
            studyQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ResearchError.noActiveStudy)
                    return
                }

                do {
                    guard let session = self.activeStudies[studyID] else {
                        throw ResearchError.noActiveStudy
                    }
                    continuation.resume(returning: session.results)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Study Completion

    /// Mark study as completed
    func completeStudy(_ study: Study) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            studyQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ResearchError.noActiveStudy)
                    return
                }

                do {
                    if var session = self.activeStudies[study.id] {
                        session.completionDate = Date()
                        session.status = .completed
                        self.activeStudies[study.id] = session
                        try self.saveStudyMetadata(session)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Withdraw from study
    func withdrawStudy(_ study: Study) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            studyQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ResearchError.noActiveStudy)
                    return
                }

                do {
                    if var session = self.activeStudies[study.id] {
                        session.status = .withdrawn
                        session.completionDate = Date()
                        self.activeStudies[study.id] = session
                        try self.saveStudyMetadata(session)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Helpers

    private func createStudyDirectories(for studyID: String) throws {
        let baseURL = getStudyBaseURL(for: studyID)

        try fileManager.createDirectory(
            at: baseURL,
            withIntermediateDirectories: true
        )

        let subdirectories = ["results", "images", "consent", "metadata"]
        for subdir in subdirectories {
            try fileManager.createDirectory(
                at: baseURL.appendingPathComponent(subdir),
                withIntermediateDirectories: true
            )
        }
    }

    private func saveStudyMetadata(_ session: StudySession) throws {
        let url = getStudyBaseURL(for: session.study.id)
            .appendingPathComponent("metadata")
            .appendingPathComponent("session.json")

        let data = try encoder.encode(session)
        try data.write(to: url)
    }

    private func loadStudySession(_ studyID: String) throws -> StudySession {
        let url = getStudyBaseURL(for: studyID)
            .appendingPathComponent("metadata")
            .appendingPathComponent("session.json")

        let data = try Data(contentsOf: url)
        return try decoder.decode(StudySession.self, from: data)
    }

    private func buildNextTask(for study: Study, session: StudySession) throws -> ORKTask {
        let remainingTasks = study.taskIDs.filter { !session.completedTaskIDs.contains($0) }
        guard let nextTaskID = remainingTasks.first else {
            throw ResearchError.taskNotFound
        }

        return try buildTask(withID: nextTaskID, from: study)
    }

    private func buildAllTasks(for study: Study) throws -> [ORKTask] {
        try study.taskIDs.map { taskID in
            try buildTask(withID: taskID, from: study)
        }
    }

    private func buildTask(withID taskID: String, from study: Study) throws -> ORKTask {
        // This would be implemented based on your task definitions
        // For now, returning a basic instruction task
        let instructionStep = ORKInstructionStep(identifier: taskID)
        instructionStep.title = "Task: \(taskID)"
        return ORKOrderedTask(identifier: taskID, steps: [instructionStep])
    }

    private func persistResult(_ result: ProcessedResult) throws {
        let url = getStudyBaseURL(for: result.studyID)
            .appendingPathComponent("results")
            .appendingPathComponent("\(result.taskID)_result.json")

        let data = try encoder.encode(result)
        try data.write(to: url)
    }

    private func getStudyBaseURL(for studyID: String) -> URL {
        let appSupportURL = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return (appSupportURL ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("Studies")
            .appendingPathComponent(studyID)
    }
}

// MARK: - Models

struct StudySession: Codable {
    var study: Study
    let participantID: String
    let startDate: Date
    var completionDate: Date?
    var status: StudyStatus = .active
    var completedTaskIDs: Set<String> = []
    var results: [ProcessedResult] = []

    enum CodingKeys: String, CodingKey {
        case study, participantID, startDate, completionDate, status, completedTaskIDs, results
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        study = try container.decode(Study.self, forKey: .study)
        participantID = try container.decode(String.self, forKey: .participantID)
        startDate = try container.decode(Date.self, forKey: .startDate)
        completionDate = try container.decodeIfPresent(Date.self, forKey: .completionDate)
        status = try container.decode(StudyStatus.self, forKey: .status)
        completedTaskIDs = try container.decode(Set<String>.self, forKey: .completedTaskIDs)
        results = try container.decode([ProcessedResult].self, forKey: .results)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(study, forKey: .study)
        try container.encode(participantID, forKey: .participantID)
        try container.encode(startDate, forKey: .startDate)
        try container.encodeIfPresent(completionDate, forKey: .completionDate)
        try container.encode(status, forKey: .status)
        try container.encode(completedTaskIDs, forKey: .completedTaskIDs)
        try container.encode(results, forKey: .results)
    }
}

enum StudyStatus: String, Codable {
    case active
    case completed
    case withdrawn
    case paused
}

struct ProcessedResult: Identifiable, Codable {
    let id: String = UUID().uuidString
    let studyID: String
    let taskID: String
    let participantID: String
    let resultData: [String: AnyCodable]
    let timestamp: Date
    let duration: TimeInterval

    enum CodingKeys: String, CodingKey {
        case id, studyID, taskID, participantID, resultData, timestamp, duration
    }
}
