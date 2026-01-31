import SwiftUI
import ResearchKit

/// Coordinates task flow in SwiftUI
@MainActor
final class TaskViewCoordinator: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isPresented = false
    @Published var taskResult: ProcessedResult?
    @Published var error: Error?
    @Published var isLoading = false
    @Published var currentStepProgress: Double = 0

    // MARK: - Properties
    private let taskService: TaskService
    private let resultProcessor: ResultProcessor
    let logger = Logger(subsystem: "com.ai4science.researchkit", category: "TaskCoordinator")

    // MARK: - Initialization
    init(
        taskService: TaskService = TaskService(),
        resultProcessor: ResultProcessor = ResultProcessor()
    ) {
        self.taskService = taskService
        self.resultProcessor = resultProcessor
        super.init()
    }

    // MARK: - Public Methods

    /// Present a task
    func presentTask(
        identifier: String,
        title: String,
        steps: [ORKStep]
    ) async {
        logger.info("Presenting task: \(identifier)")
        isPresented = true
    }

    /// Present sample collection task
    func presentSampleCollectionTask(sampleType: String = "general") async {
        logger.info("Presenting sample collection task")
        isPresented = true
    }

    /// Present quality assessment task
    func presentQualityAssessmentTask(dataType: String = "general") async {
        logger.info("Presenting quality assessment task")
        isPresented = true
    }

    /// Handle task completion
    func handleTaskCompletion(_ taskResult: ORKTaskResult) async {
        logger.debug("Processing task completion: \(taskResult.identifier)")
        isLoading = true
        defer { isLoading = false }

        do {
            let processed = try await resultProcessor.process(taskResult)
            self.taskResult = processed

            logger.info("Task completed successfully: \(taskResult.identifier)")

        } catch {
            logger.error("Failed to process task: \(error.localizedDescription)")
            self.error = error
        }
    }

    /// Get task result
    func getTaskResult() -> ProcessedResult? {
        return taskResult
    }

    /// Export task result
    func exportResult(format: ResultExportFormat) async throws -> Data {
        guard let result = taskResult else {
            throw TaskCoordinatorError.noTaskResults
        }

        logger.debug("Exporting task result in format: \(format.rawValue)")
        return try await ResultExporter.export(result, format: format)
    }

    /// Reset task state
    func resetTask() {
        logger.debug("Resetting task state")
        taskResult = nil
        error = nil
        isLoading = false
        currentStepProgress = 0
    }
}

// MARK: - SwiftUI View
struct TaskView: View {
    @StateObject private var coordinator = TaskViewCoordinator()

    let taskIdentifier: String
    let taskTitle: String
    var steps: [ORKStep]?
    var onCompletion: ((ProcessedResult) -> Void)?
    var onCancel: (() -> Void)?

    var body: some View {
        ZStack {
            if coordinator.isLoading {
                TaskProcessingView()
            } else if let result = coordinator.taskResult {
                TaskResultView(result: result)
            } else {
                TaskStartView(
                    title: taskTitle,
                    onStart: {
                        Task {
                            await coordinator.presentTask(
                                identifier: taskIdentifier,
                                title: taskTitle,
                                steps: steps ?? []
                            )
                        }
                    }
                )
            }

            if let error = coordinator.error {
                TaskErrorView(error: error)
            }
        }
        .environmentObject(coordinator)
    }
}

// MARK: - Task Start View
struct TaskStartView: View {
    let title: String
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clipboard.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text(title)
                .font(.title)
                .fontWeight(.bold)

            Text("Complete this task to contribute to the research")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Guided steps")
                }

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.green)
                    Text("Your data is secure")
                }

                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.green)
                    Text("Takes about 15-20 minutes")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)

            Button(action: onStart) {
                Text("Start Task")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Task Processing View
struct TaskProcessingView: View {
    @State private var animate = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.blue, lineWidth: 12)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(animate ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: animate)
            }

            Text("Processing Task")
                .font(.headline)

            Text("Please wait...")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
        .onAppear { animate = true }
    }
}

// MARK: - Task Result View
struct TaskResultView: View {
    let result: ProcessedResult

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Task Complete")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Task ID:")
                    Spacer()
                    Text(result.taskIdentifier)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Divider()

                HStack {
                    Text("Duration:")
                    Spacer()
                    Text(formatDuration(result.duration))
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Status:")
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(result.isComplete ? "Complete" : "Incomplete")
                    }
                }

                if result.errors.count > 0 {
                    Divider()
                    HStack {
                        Text("Errors:")
                        Spacer()
                        Text("\(result.errors.count)")
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)

            Text("Thank you for completing this task!")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Task Error View
struct TaskErrorView: View {
    let error: Error

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)

                Text("Task Error")
                    .fontWeight(.semibold)

                Spacer()
            }

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color(.systemRed).opacity(0.1))
        .cornerRadius(8)
        .padding()
    }
}

// MARK: - Helper Functions
private func formatDuration(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds) / 60
    let remainingSeconds = Int(seconds) % 60

    if minutes > 0 {
        return "\(minutes)m \(remainingSeconds)s"
    } else {
        return "\(remainingSeconds)s"
    }
}

// MARK: - Error Types
enum TaskCoordinatorError: LocalizedError {
    case noTaskResults

    var errorDescription: String? {
        switch self {
        case .noTaskResults:
            return "No task results available"
        }
    }
}

// MARK: - Logger Helper
private struct Logger {
    private let subsystem: String
    private let category: String

    init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }

    func debug(_ message: String) {
        os_log("%{public}@", log: getLog(), type: .debug, message)
    }

    func info(_ message: String) {
        os_log("%{public}@", log: getLog(), type: .info, message)
    }

    func warning(_ message: String) {
        os_log("%{public}@", log: getLog(), type: .default, message)
    }

    func error(_ message: String) {
        os_log("%{public}@", log: getLog(), type: .error, message)
    }

    private func getLog() -> os.OSLog {
        return OSLog(subsystem: subsystem, category: category)
    }
}

import os
