import Foundation
import CoreML
import Vision

/// Protocol defining the contract for image preprocessors
public protocol PreprocessorProtocol: Sendable {
    /// Name of the preprocessor
    var name: String { get }

    /// Target image size for preprocessing
    var targetImageSize: CGSize { get }

    /// Normalize pixel values
    var shouldNormalize: Bool { get }

    /// Mean values for normalization [R, G, B]
    var normalizationMeans: (Float, Float, Float) { get }

    /// Standard deviation values for normalization [R, G, B]
    var normalizationStds: (Float, Float, Float) { get }

    /// Preprocess image to prepare for model input
    func preprocess(_ image: UIImage) async throws -> MLFeatureProvider

    /// Preprocess from pixel buffer
    func preprocessPixelBuffer(_ pixelBuffer: CVPixelBuffer) async throws -> MLFeatureProvider

    /// Get the input feature description
    func getInputFeatureDescription() -> MLFeatureDescription?
}

/// Default implementations
public extension PreprocessorProtocol {
    var shouldNormalize: Bool {
        true
    }

    var normalizationMeans: (Float, Float, Float) {
        (0.485, 0.456, 0.406)
    }

    var normalizationStds: (Float, Float, Float) {
        (0.229, 0.224, 0.225)
    }
}
