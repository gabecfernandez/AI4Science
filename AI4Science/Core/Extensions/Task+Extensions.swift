import Foundation

/// Task cancellation token
public actor TaskCancellationToken {
    private var isCancelled = false

    nonisolated let id: UUID = UUID()

    /// Cancel the token
    func cancel() {
        Task {
            self.isCancelled = true
        }
    }

    /// Check if token is cancelled
    func checkCancellation() throws {
        if isCancelled {
            throw CancellationError()
        }
    }

    /// Check if not cancelled
    var isActive: Bool {
        get async {
            !isCancelled
        }
    }
}

public extension Task {
    /// Create task with cancellation token
    static func withCancellationToken(
        priority: TaskPriority? = nil,
        operation: @escaping (TaskCancellationToken) async -> Success
    ) -> (task: Task<Success, Failure>, token: TaskCancellationToken) where Failure == Error {
        let token = TaskCancellationToken()
        let task = Task(priority: priority) {
            try await operation(token)
        }
        return (task, token)
    }

    /// Add timeout to task
    static func withTimeout(
        seconds: TimeInterval,
        priority: TaskPriority? = nil,
        operation: @escaping () async throws -> Success
    ) -> Task<Success, Failure> where Failure == Error {
        Task(priority: priority) {
            try await withThrowingTaskGroup(of: Success.self) { group in
                group.addTask {
                    try await operation()
                }

                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                    throw TimeoutError()
                }

                guard let result = try await group.next() else {
                    throw CancellationError()
                }
                group.cancelAll()
                return result
            }
        }
    }

    /// Retry operation on failure
    static func withRetry(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        priority: TaskPriority? = nil,
        operation: @escaping () async throws -> Success
    ) -> Task<Success, Failure> where Failure == Error {
        Task(priority: priority) {
            var lastError: Error?

            for attempt in 1...maxAttempts {
                do {
                    return try await operation()
                } catch {
                    lastError = error

                    if attempt < maxAttempts {
                        try await Task.sleep(nanoseconds: UInt64(delay * Double(attempt) * 1_000_000_000))
                    }
                }
            }

            throw lastError ?? CancellationError()
        }
    }

    /// Execute task and catch error
    @discardableResult
    func `catch`(_ handler: @escaping (Error) -> Void) -> Task<Success, Never> where Failure == Error {
        Task {
            do {
                _ = try await value
            } catch {
                handler(error)
            }
        }
    }

    /// Execute task and handle completion
    @discardableResult
    func finally(_ handler: @escaping () -> Void) -> Task<Success, Failure> {
        Task {
            defer { handler() }
            return try await value
        }
    }
}

/// Timeout error
public struct TimeoutError: LocalizedError {
    public let errorDescription: String? = "Task timed out"
}

public extension Task where Success: Sendable, Failure == Error {
    /// Convert to async value
    var asyncValue: Success {
        get async throws {
            try await value
        }
    }
}

/// Sleep extension
public extension Task {
    /// Sleep for duration with cancellation support
    static func sleep(for duration: TimeInterval) async throws {
        try await sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }

    /// Sleep for duration in milliseconds
    static func sleepMilliseconds(_ ms: UInt64) async throws {
        try await sleep(nanoseconds: ms * 1_000_000)
    }

    /// Sleep for duration in seconds
    static func sleepSeconds(_ seconds: Double) async throws {
        try await sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

public extension TaskGroup {
    /// Add tasks from array
    mutating func addTasks<S: Sequence>(
        _ sequence: S,
        priority: TaskPriority? = nil,
        operation: @escaping (S.Element) async throws -> ChildTaskResult
    ) where S.Element: Sendable {
        for element in sequence {
            addTask(priority: priority) {
                try await operation(element)
            }
        }
    }
}
