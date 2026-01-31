import Foundation
import os.log

/// Centralized logger using os.log
public struct AppLogger: Sendable {
    public enum Level: Sendable {
        case debug
        case info
        case warning
        case error
        case fault
    }

    /// Shared instance for instance-method style calls
    public static let shared = AppLogger()

    nonisolated(unsafe) private static var currentLevel: Level = .debug
    nonisolated(unsafe) private static let subsystem = "com.ai4science.ios"

    public static nonisolated func configure(level: Level) {
        currentLevel = level
    }

    // MARK: - Instance Methods

    public func debug(_ message: String, subsystem: String? = nil) {
        AppLogger.log(message, level: .debug, subsystem: subsystem)
    }

    public func info(_ message: String, subsystem: String? = nil) {
        AppLogger.log(message, level: .info, subsystem: subsystem)
    }

    public func warning(_ message: String, subsystem: String? = nil) {
        AppLogger.log(message, level: .warning, subsystem: subsystem)
    }

    public func error(_ message: String, subsystem: String? = nil) {
        AppLogger.log(message, level: .error, subsystem: subsystem)
    }

    public func fault(_ message: String, subsystem: String? = nil) {
        AppLogger.log(message, level: .fault, subsystem: subsystem)
    }

    // MARK: - Static Methods

    public static nonisolated func debug(_ message: String, subsystem: String? = nil) {
        log(message, level: .debug, subsystem: subsystem)
    }

    public static nonisolated func info(_ message: String, subsystem: String? = nil) {
        log(message, level: .info, subsystem: subsystem)
    }

    public static nonisolated func warning(_ message: String, subsystem: String? = nil) {
        log(message, level: .warning, subsystem: subsystem)
    }

    public static nonisolated func error(_ message: String, subsystem: String? = nil) {
        log(message, level: .error, subsystem: subsystem)
    }

    public static nonisolated func fault(_ message: String, subsystem: String? = nil) {
        log(message, level: .fault, subsystem: subsystem)
    }

    public static nonisolated func debug(_ error: Error, subsystem: String? = nil) {
        log("Debug Error: \(error.localizedDescription)", level: .debug, subsystem: subsystem)
    }

    public static nonisolated func error(_ error: Error, subsystem: String? = nil) {
        log("Error: \(error.localizedDescription)", level: .error, subsystem: subsystem)
    }

    public static nonisolated func fault(_ error: Error, subsystem: String? = nil) {
        log("Fault: \(error.localizedDescription)", level: .fault, subsystem: subsystem)
    }

    // MARK: - Private

    private static nonisolated func log(_ message: String, level: Level, subsystem: String?) {
        let sub = subsystem ?? Self.subsystem
        let osLog = OSLog(subsystem: sub, category: categoryForLevel(level))

        let type: OSLogType = switch level {
        case .debug: .debug
        case .info: .info
        case .warning: .default
        case .error: .error
        case .fault: .fault
        }

        os_log("%{public}@", log: osLog, type: type, message)

        #if DEBUG
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        let timestamp = formatter.string(from: Date())
        print("[\(levelString(level))] [\(timestamp)] \(message)")
        #endif
    }

    private static nonisolated func categoryForLevel(_ level: Level) -> String {
        switch level {
        case .debug: "Debug"
        case .info: "Info"
        case .warning: "Warning"
        case .error: "Error"
        case .fault: "Fault"
        }
    }

    private static nonisolated func levelString(_ level: Level) -> String {
        switch level {
        case .debug: "DEBUG"
        case .info: "INFO"
        case .warning: "WARNING"
        case .error: "ERROR"
        case .fault: "FAULT"
        }
    }
}
