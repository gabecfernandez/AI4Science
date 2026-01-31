import Foundation

/// Errors that can occur during ML model operations
public enum MLModelError: LocalizedError, Sendable {
    case modelNotFound(String)
    case loadFailed(String)
    case invalidInput
    case invalidOutput
    case inferenceError(String)
    case configurationError(String)
    case outputParsingError(String)
    case preprocessingFailed(String)
    case incompatibleModel(String)
    case insufficientMemory

    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let name):
            return "ML model not found: \(name)"
        case .loadFailed(let reason):
            return "Failed to load ML model: \(reason)"
        case .invalidInput:
            return "Invalid input provided to ML model"
        case .invalidOutput:
            return "Invalid output from ML model"
        case .inferenceError(let reason):
            return "ML inference failed: \(reason)"
        case .configurationError(let reason):
            return "ML model configuration error: \(reason)"
        case .outputParsingError(let reason):
            return "Failed to parse ML output: \(reason)"
        case .preprocessingFailed(let reason):
            return "Image preprocessing failed: \(reason)"
        case .incompatibleModel(let reason):
            return "Incompatible ML model: \(reason)"
        case .insufficientMemory:
            return "Insufficient memory to load ML model"
        }
    }
}
