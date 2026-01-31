import Foundation

extension Task where Success == Never, Failure == Never {
    /// Sleep for duration
    public static func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

/// Run async operation with timeout
public func withTimeout<T>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError.timedOut
        }

        guard let result = try await group.next() else {
            throw TimeoutError.timedOut
        }

        group.cancelAll()
        return result
    }
}

/// Run async operation with deadline
public func withDeadline<T>(
    _ deadline: Date,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    let timeout = deadline.timeIntervalSinceNow
    guard timeout > 0 else { throw TimeoutError.timedOut }
    return try await withTimeout(seconds: timeout, operation: operation)
}

enum TimeoutError: LocalizedError, Sendable {
    case timedOut

    var errorDescription: String? {
        "Operation timed out"
    }
}
