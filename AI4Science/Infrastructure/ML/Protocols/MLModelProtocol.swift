import Foundation
import CoreML

/// Protocol defining the contract for ML model wrappers
public protocol MLModelProtocol: Sendable {
    /// Unique identifier for the model
    var modelIdentifier: String { get }

    /// Model version
    var modelVersion: String { get }

    /// Minimum iOS version required
    var minimumIOSVersion: String { get }

    /// Expected input image size
    var inputImageSize: CGSize { get }

    /// Model input name
    var inputMLFeatureName: String { get }

    /// Model output name
    var outputMLFeatureName: String { get }

    /// Total model size in bytes
    var modelSizeBytes: UInt64 { get }

    /// Whether the model is currently loaded in memory
    var isLoaded: Bool { get async }

    /// Load the model into memory
    func load() async throws

    /// Unload the model from memory
    func unload() async throws

    /// Get the underlying CoreML model
    func getMLModel() async throws -> MLModel
}

/// Default implementations for MLModelProtocol
public extension MLModelProtocol {
    var minimumIOSVersion: String {
        "17.0"
    }
}
