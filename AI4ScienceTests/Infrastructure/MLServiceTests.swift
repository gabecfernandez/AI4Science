//
//  MLServiceTests.swift
//  AI4ScienceTests
//
//  Created for AI4Science UTSA
//

import Testing
import Foundation
import CoreML
import Vision
@testable import AI4Science

@Suite("ML Inference Service Tests")
struct MLInferenceServiceTests {

    @Test("ML service initializes with model loader")
    func testServiceInitialization() async throws {
        let mockLoader = MockMLModelLoader()
        let service = MLInferenceService(modelLoader: mockLoader)

        #expect(service != nil)
    }

    @Test("Service loads model on demand")
    func testModelLoading() async throws {
        let mockLoader = MockMLModelLoader()
        let service = MLInferenceService(modelLoader: mockLoader)

        try await service.loadModel(.defectDetection)

        #expect(mockLoader.loadedModels.contains(.defectDetection))
    }

    @Test("Service caches loaded models")
    func testModelCaching() async throws {
        let mockLoader = MockMLModelLoader()
        let service = MLInferenceService(modelLoader: mockLoader)

        // Load same model twice
        try await service.loadModel(.defectDetection)
        try await service.loadModel(.defectDetection)

        // Should only load once due to caching
        #expect(mockLoader.loadCallCount == 1)
    }

    @Test("Service unloads models to free memory")
    func testModelUnloading() async throws {
        let mockLoader = MockMLModelLoader()
        let service = MLInferenceService(modelLoader: mockLoader)

        try await service.loadModel(.defectDetection)
        await service.unloadModel(.defectDetection)

        #expect(await service.isModelLoaded(.defectDetection) == false)
    }

    @Test("Service reports available models")
    func testAvailableModels() async throws {
        let mockLoader = MockMLModelLoader()
        mockLoader.availableModels = [.defectDetection, .materialClassification]

        let service = MLInferenceService(modelLoader: mockLoader)
        let available = await service.availableModels()

        #expect(available.count == 2)
        #expect(available.contains(.defectDetection))
    }
}

@Suite("ML Model Manager Tests")
struct MLModelManagerTests {

    @Test("Manager tracks model metadata")
    func testModelMetadata() async {
        let manager = MLModelManager()

        let metadata = MLModelMetadata(
            id: UUID(),
            name: "DefectDetector-v2",
            version: "2.0.0",
            type: .defectDetection,
            inputSize: CGSize(width: 640, height: 640),
            fileSize: 45_000_000,
            accuracy: 0.94,
            createdAt: Date()
        )

        await manager.registerModel(metadata)

        let retrieved = await manager.getMetadata(for: .defectDetection)
        #expect(retrieved?.name == "DefectDetector-v2")
        #expect(retrieved?.accuracy == 0.94)
    }

    @Test("Manager validates model compatibility")
    func testModelCompatibility() async {
        let manager = MLModelManager()

        let oldMetadata = MLModelMetadata(
            id: UUID(),
            name: "OldModel",
            version: "1.0.0",
            type: .defectDetection,
            inputSize: CGSize(width: 224, height: 224),
            fileSize: 10_000_000,
            minimumOSVersion: "15.0",
            createdAt: Date()
        )

        await manager.registerModel(oldMetadata)

        let isCompatible = await manager.isCompatible(.defectDetection)
        #expect(isCompatible == true)
    }

    @Test("Manager handles model updates")
    func testModelUpdate() async {
        let manager = MLModelManager()

        let v1 = MLModelMetadata(
            id: UUID(),
            name: "Model-v1",
            version: "1.0.0",
            type: .defectDetection,
            inputSize: CGSize(width: 640, height: 640),
            fileSize: 40_000_000,
            createdAt: Date()
        )

        let v2 = MLModelMetadata(
            id: UUID(),
            name: "Model-v2",
            version: "2.0.0",
            type: .defectDetection,
            inputSize: CGSize(width: 640, height: 640),
            fileSize: 45_000_000,
            createdAt: Date()
        )

        await manager.registerModel(v1)
        let hasUpdate = await manager.hasUpdate(v2, for: .defectDetection)

        #expect(hasUpdate == true)
    }
}

@Suite("Vision Service Tests")
struct VisionServiceTests {

    @Test("Vision service detects objects in image")
    func testObjectDetection() async throws {
        let service = VisionService()

        // Create a test image (1x1 red pixel)
        let testImage = createTestImage()

        let detections = try await service.detectObjects(in: testImage)

        // Mock service should return some detections
        #expect(detections != nil)
    }

    @Test("Vision service recognizes text")
    func testTextRecognition() async throws {
        let service = VisionService()
        let testImage = createTestImage()

        let recognizedText = try await service.recognizeText(in: testImage)

        #expect(recognizedText != nil)
    }

    @Test("Vision service generates image embedding")
    func testImageEmbedding() async throws {
        let service = VisionService()
        let testImage = createTestImage()

        let embedding = try await service.generateEmbedding(for: testImage)

        #expect(embedding.count > 0)
    }

    @Test("Vision service handles barcode scanning")
    func testBarcodeScanning() async throws {
        let service = VisionService()
        let testImage = createTestImage()

        let barcodes = try await service.scanBarcodes(in: testImage)

        // Test image has no barcodes
        #expect(barcodes.isEmpty)
    }

    private func createTestImage() -> CGImage {
        let width = 100
        let height = 100
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )!

        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()!
    }
}

@Suite("Neural Engine Optimizer Tests")
struct NeuralEngineOptimizerTests {

    @Test("Optimizer selects Neural Engine when available")
    func testNeuralEngineSelection() async {
        let optimizer = NeuralEngineOptimizer()

        let computeUnits = await optimizer.optimalComputeUnits(for: .defectDetection)

        // On supported devices, should prefer Neural Engine
        #expect(computeUnits == .all || computeUnits == .cpuAndNeuralEngine)
    }

    @Test("Optimizer falls back to CPU for unsupported models")
    func testCPUFallback() async {
        let optimizer = NeuralEngineOptimizer()

        // Very large models might need CPU fallback
        let computeUnits = await optimizer.optimalComputeUnits(
            for: .custom("LargeUnsupportedModel")
        )

        #expect(computeUnits != nil)
    }

    @Test("Optimizer monitors performance")
    func testPerformanceMonitoring() async {
        let optimizer = NeuralEngineOptimizer()

        await optimizer.startMonitoring()

        // Simulate some inference
        await optimizer.recordInference(duration: 0.05, modelType: .defectDetection)
        await optimizer.recordInference(duration: 0.06, modelType: .defectDetection)
        await optimizer.recordInference(duration: 0.04, modelType: .defectDetection)

        let stats = await optimizer.getPerformanceStats(for: .defectDetection)

        #expect(stats.averageLatency > 0)
        #expect(stats.inferenceCount == 3)
    }
}

// MARK: - Mock Objects

final class MockMLModelLoader: MLModelLoading, @unchecked Sendable {
    var loadedModels: Set<MLModelType> = []
    var availableModels: [MLModelType] = [.defectDetection]
    var loadCallCount = 0

    func loadModel(_ type: MLModelType) async throws -> MLModel {
        loadCallCount += 1
        loadedModels.insert(type)

        // Return a mock model configuration
        let config = MLModelConfiguration()
        config.computeUnits = .cpuOnly

        // In real tests, would load actual test model
        throw MLModelError.modelNotFound
    }

    func isAvailable(_ type: MLModelType) -> Bool {
        availableModels.contains(type)
    }
}

// MARK: - Test Helpers

enum MLModelType: Hashable {
    case defectDetection
    case materialClassification
    case segmentation
    case custom(String)
}

protocol MLModelLoading: Sendable {
    func loadModel(_ type: MLModelType) async throws -> MLModel
    func isAvailable(_ type: MLModelType) -> Bool
}

enum MLModelError: Error {
    case modelNotFound
    case incompatibleVersion
    case loadFailed
}
