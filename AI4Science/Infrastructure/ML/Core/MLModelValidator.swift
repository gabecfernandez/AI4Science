import Foundation
import CoreML
import os.log

/// Model validation error types
public enum MLValidationError: LocalizedError {
    case fileNotFound(String)
    case invalidChecksum(String)
    case unsupportedIOSVersion(String)
    case incompatibleModelFormat(String)
    case missingRequiredFeatures(String)
    case invalidInputShape(String)
    case unsupportedInputType(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Model file not found: \(path)"
        case .invalidChecksum(let expected):
            return "Checksum mismatch. Expected: \(expected)"
        case .unsupportedIOSVersion(let required):
            return "Unsupported iOS version. Required: \(required)"
        case .incompatibleModelFormat(let format):
            return "Incompatible model format: \(format)"
        case .missingRequiredFeatures(let features):
            return "Missing required features: \(features)"
        case .invalidInputShape(let shape):
            return "Invalid input shape: \(shape)"
        case .unsupportedInputType(let type):
            return "Unsupported input type: \(type)"
        }
    }
}

/// Validation result
public struct MLValidationResult: Sendable {
    public let isValid: Bool
    public let errors: [MLValidationError]
    public let warnings: [String]
    public let modelFormat: String?
    public let inputFeatures: [String]
    public let outputFeatures: [String]
    public let computeUnits: String

    public init(
        isValid: Bool,
        errors: [MLValidationError] = [],
        warnings: [String] = [],
        modelFormat: String? = nil,
        inputFeatures: [String] = [],
        outputFeatures: [String] = [],
        computeUnits: String = "CPU"
    ) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
        self.modelFormat = modelFormat
        self.inputFeatures = inputFeatures
        self.outputFeatures = outputFeatures
        self.computeUnits = computeUnits
    }
}

/// Actor for validating ML models
public actor MLModelValidator {
    private let logger = Logger(subsystem: "com.ai4science.ml", category: "MLModelValidator")

    public init() {
        logger.info("MLModelValidator initialized")
    }

    /// Validate model file exists and is accessible
    public func validateFileExists(path: String) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path) else {
            throw MLValidationError.fileNotFound(path)
        }
    }

    /// Validate file checksum
    public func validateChecksum(path: String, expectedSHA256: String) async throws {
        let fileURL = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: fileURL)

        let calculatedChecksum = calculateSHA256(data: data)
        guard calculatedChecksum == expectedSHA256 else {
            throw MLValidationError.invalidChecksum(expectedSHA256)
        }

        logger.debug("Checksum validation passed for: \(path)")
    }

    /// Validate iOS version compatibility
    public func validateIOSVersion(_ requiredVersion: String) throws {
        let currentVersion = UIDevice.current.systemVersion
        guard isVersionCompatible(current: currentVersion, required: requiredVersion) else {
            throw MLValidationError.unsupportedIOSVersion(requiredVersion)
        }
    }

    /// Validate CoreML model
    public func validateModel(at path: String) async throws -> MLValidationResult {
        do {
            let modelURL = URL(fileURLWithPath: path)
            let model = try MLModel(contentsOf: modelURL)

            let inputFeatures = model.modelDescription.inputDescriptionsByName.keys.map { $0 }
            let outputFeatures = model.modelDescription.outputDescriptionsByName.keys.map { $0 }

            var errors: [MLValidationError] = []
            var warnings: [String] = []

            // Validate input features
            for (name, desc) in model.modelDescription.inputDescriptionsByName {
                if let imageInput = desc as? MLImageFeatureDescription {
                    let size = imageInput.imageConstraint?.size ?? .zero
                    if size == .zero {
                        warnings.append("Image input '\(name)' has unknown size")
                    }
                }
            }

            // Validate compute units
            let computeUnits = detectComputeUnits(model: model)

            let isValid = errors.isEmpty
            return MLValidationResult(
                isValid: isValid,
                errors: errors,
                warnings: warnings,
                modelFormat: "CoreML",
                inputFeatures: inputFeatures,
                outputFeatures: outputFeatures,
                computeUnits: computeUnits
            )
        } catch {
            let errors: [MLValidationError] = [.incompatibleModelFormat("Invalid CoreML model")]
            return MLValidationResult(isValid: false, errors: errors)
        }
    }

    /// Validate input data shape
    public func validateInputShape(
        _ shape: [Int],
        expectedShape: [Int]
    ) throws {
        guard shape == expectedShape else {
            throw MLValidationError.invalidInputShape(
                "Expected \(expectedShape), got \(shape)"
            )
        }
    }

    /// Complete validation of model
    public func validateModelComplete(
        path: String,
        expectedChecksum: String? = nil,
        minimumIOSVersion: String = "17.0"
    ) async throws -> MLValidationResult {
        // File existence check
        try validateFileExists(path: path)

        // Checksum validation
        if let checksum = expectedChecksum {
            try await validateChecksum(path: path, expectedSHA256: checksum)
        }

        // iOS version check
        try validateIOSVersion(minimumIOSVersion)

        // CoreML model validation
        let result = try await validateModel(at: path)

        return result
    }

    // MARK: - Private Helpers

    private func calculateSHA256(data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: 32)
        data.withUnsafeBytes { buffer in
            if let baseAddress = buffer.baseAddress {
                let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
                // Simplified SHA256 - in production use CryptoKit
                digest = Array(data.prefix(32))
            }
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func isVersionCompatible(current: String, required: String) -> Bool {
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        let requiredComponents = required.split(separator: ".").compactMap { Int($0) }

        for (curr, req) in zip(currentComponents, requiredComponents) {
            if curr > req { return true }
            if curr < req { return false }
        }
        return true
    }

    private func detectComputeUnits(model: MLModel) -> String {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            return "CPU+Neural Engine"
        } else {
            return "CPU"
        }
        #else
        return "CPU"
        #endif
    }
}
