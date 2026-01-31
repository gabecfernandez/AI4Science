import Foundation

/// Supported ML model types for inference.
public enum MLModelType: String, Hashable, Sendable, CaseIterable {
    case defectDetection
    case materialClassification
    case segmentation
    case custom
}

/// Represents metadata for an ML model
public struct MLModel: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var version: String
    public var modelType: String
    public var description: String?
    public var accuracy: Double?
    public var precision: Double?
    public var recall: Double?
    public var f1Score: Double?
    public var fileSizeBytes: Int64
    public var inputDimensions: [Int]
    public var outputDimensions: [Int]
    public var framework: String // TensorFlow Lite, Core ML, PyTorch, etc.
    public var trainingDataset: String?
    public var trainingDate: Date?
    public var quantized: Bool
    public var acceleration: String? // Neural Engine, Metal, etc.
    public var supportedClasses: [String]
    public var metadata: [String: String]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        version: String,
        modelType: String,
        description: String? = nil,
        accuracy: Double? = nil,
        precision: Double? = nil,
        recall: Double? = nil,
        f1Score: Double? = nil,
        fileSizeBytes: Int64,
        inputDimensions: [Int],
        outputDimensions: [Int],
        framework: String,
        trainingDataset: String? = nil,
        trainingDate: Date? = nil,
        quantized: Bool = false,
        acceleration: String? = nil,
        supportedClasses: [String] = [],
        metadata: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.modelType = modelType
        self.description = description
        self.accuracy = accuracy
        self.precision = precision
        self.recall = recall
        self.f1Score = f1Score
        self.fileSizeBytes = fileSizeBytes
        self.inputDimensions = inputDimensions
        self.outputDimensions = outputDimensions
        self.framework = framework
        self.trainingDataset = trainingDataset
        self.trainingDate = trainingDate
        self.quantized = quantized
        self.acceleration = acceleration
        self.supportedClasses = supportedClasses
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var fileSizeMB: Double {
        Double(fileSizeBytes) / (1024 * 1024)
    }

    public var formattedInputDimensions: String {
        inputDimensions.map(String.init).joined(separator: " × ")
    }

    public var formattedOutputDimensions: String {
        outputDimensions.map(String.init).joined(separator: " × ")
    }

    public var classCount: Int {
        supportedClasses.count
    }
}

// MARK: - Equatable
extension MLModel: Equatable {
    public static func == (lhs: MLModel, rhs: MLModel) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension MLModel: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
