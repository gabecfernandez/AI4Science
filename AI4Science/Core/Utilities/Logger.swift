import Foundation
import os.log

/// Centralized logger using os.log
public actor AppLogger {
    // MARK: - Shared Instance Wrapper
    public static let shared = AppLoggerShared()

    public enum Level: Sendable {
        case debug
        case info
        case warning
        case error
        case fault
    }

    private static let subsystem = "com.ai4science.ios"
    private nonisolated(unsafe) static var configuredLevel: Level = .debug

    /// Configure the minimum log level
    public nonisolated static func configure(level: Level) {
        configuredLevel = level
    }

    public static func debug(_ message: String, subsystem: String? = nil) {
        log(message, level: .debug, subsystem: subsystem)
    }

    public static func info(_ message: String, subsystem: String? = nil) {
        log(message, level: .info, subsystem: subsystem)
    }

    public static func warning(_ message: String, subsystem: String? = nil) {
        log(message, level: .warning, subsystem: subsystem)
    }

    public static func error(_ message: String, subsystem: String? = nil) {
        log(message, level: .error, subsystem: subsystem)
    }

    public static func fault(_ message: String, subsystem: String? = nil) {
        log(message, level: .fault, subsystem: subsystem)
    }

    public static func debug(_ error: Error, subsystem: String? = nil) {
        let message = "Debug Error: \(error.localizedDescription)"
        log(message, level: .debug, subsystem: subsystem)
    }

    public static func error(_ error: Error, subsystem: String? = nil) {
        let message = "Error: \(error.localizedDescription)"
        log(message, level: .error, subsystem: subsystem)
    }

    public static func fault(_ error: Error, subsystem: String? = nil) {
        let message = "Fault: \(error.localizedDescription)"
        log(message, level: .fault, subsystem: subsystem)
    }

    private static func log(_ message: String, level: Level, subsystem: String?) {
        let subsystem = subsystem ?? Self.subsystem
        let osLog = OSLog(subsystem: subsystem, category: categoryForLevel(level))

        let type: OSLogType = switch level {
        case .debug: .debug
        case .info: .info
        case .warning: .default
        case .error: .error
        case .fault: .fault
        }

        os_log("%{public}@", log: osLog, type: type, message)

        #if DEBUG
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let levelString = levelString(level)
        print("[\(levelString)] [\(timestamp)] \(message)")
        #endif
    }

    private static func categoryForLevel(_ level: Level) -> String {
        switch level {
        case .debug: "Debug"
        case .info: "Info"
        case .warning: "Warning"
        case .error: "Error"
        case .fault: "Fault"
        }
    }

    private static func levelString(_ level: Level) -> String {
        switch level {
        case .debug: "DEBUG"
        case .info: "INFO"
        case .warning: "WARNING"
        case .error: "ERROR"
        case .fault: "FAULT"
        }
    }
}

/// Non-actor wrapper for AppLogger that provides instance methods
/// Use `AppLogger.shared` to access these methods
public struct AppLoggerShared: Sendable {
    public func debug(_ message: String) {
        AppLogger.debug(message)
    }

    public func info(_ message: String) {
        AppLogger.info(message)
    }

    public func warning(_ message: String) {
        AppLogger.warning(message)
    }

    public func error(_ message: String) {
        AppLogger.error(message)
    }

    public func fault(_ message: String) {
        AppLogger.fault(message)
    }
}
