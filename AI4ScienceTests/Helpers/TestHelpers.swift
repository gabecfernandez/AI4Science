//
//  TestHelpers.swift
//  AI4ScienceTests
//
//  Utility functions and extensions for testing
//

import Foundation
import SwiftData
import CoreGraphics
@testable import AI4Science

// MARK: - Test Data Generators

enum TestDataGenerator {

    static func createUser(
        id: UUID = UUID(),
        email: String = "test@utsa.edu",
        displayName: String = "Test User",
        role: UserRole = .researcher
    ) -> User {
        User(
            id: id,
            email: email,
            displayName: displayName,
            role: role,
            labAffiliation: createLabAffiliation()
        )
    }

    static func createLabAffiliation(
        id: UUID = UUID(),
        name: String = "Vision & AI Lab",
        institution: String = "UT San Antonio"
    ) -> LabAffiliation {
        LabAffiliation(
            id: id,
            name: name,
            institution: institution,
            department: "Computer Science"
        )
    }

    static func createProject(
        id: UUID = UUID(),
        title: String = "Test Project",
        description: String = "A test project for unit testing",
        status: ProjectStatus = .active,
        principalInvestigatorID: UUID = UUID()
    ) -> Project {
        Project(
            id: id,
            title: title,
            description: description,
            status: status,
            principalInvestigatorID: principalInvestigatorID,
            labAffiliation: createLabAffiliation(),
            startDate: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static func createSample(
        id: UUID = UUID(),
        projectId: UUID = UUID(),
        name: String = "Test Sample"
    ) -> Sample {
        Sample(
            id: id,
            projectId: projectId,
            name: name,
            description: "A test sample",
            materialType: "Steel",
            status: .pending,
            createdAt: Date(),
            createdBy: UUID()
        )
    }

    static func createCapture(
        id: UUID = UUID(),
        sampleId: UUID = UUID(),
        type: CaptureType = .photo
    ) -> Capture {
        Capture(
            id: id,
            sampleId: sampleId,
            type: type,
            fileURL: URL(fileURLWithPath: "/test/capture_\(id.uuidString).heic"),
            thumbnailURL: URL(fileURLWithPath: "/test/thumb_\(id.uuidString).jpg"),
            metadata: createCaptureMetadata(),
            createdAt: Date(),
            createdBy: UUID()
        )
    }

    static func createCaptureMetadata(
        width: Int = 4032,
        height: Int = 3024
    ) -> CaptureMetadata {
        CaptureMetadata(
            width: width,
            height: height,
            colorSpace: .sRGB,
            captureDate: Date(),
            deviceModel: "iPhone 15 Pro"
        )
    }

    static func createAnnotation(
        id: UUID = UUID(),
        captureId: UUID = UUID(),
        type: AnnotationType = .rectangle
    ) -> Annotation {
        Annotation(
            id: id,
            captureId: captureId,
            type: type,
            geometry: .rectangle(CGRect(x: 100, y: 100, width: 200, height: 150)),
            label: "Test Defect",
            defectType: .crack,
            severity: .moderate,
            confidence: 0.92,
            createdAt: Date(),
            createdBy: UUID()
        )
    }

    static func createAnalysisResult(
        id: UUID = UUID(),
        captureId: UUID = UUID()
    ) -> AnalysisResult {
        AnalysisResult(
            id: id,
            captureId: captureId,
            modelType: "DefectDetector-v2",
            modelVersion: "2.0.0",
            detections: [
                DetectionResult(
                    id: UUID(),
                    label: "crack",
                    confidence: 0.95,
                    boundingBox: CGRect(x: 50, y: 50, width: 100, height: 80)
                )
            ],
            processingTime: 0.156,
            createdAt: Date()
        )
    }

    static func createMLModelMetadata(
        type: MLModelType = .defectDetection
    ) -> MLModelMetadata {
        MLModelMetadata(
            id: UUID(),
            name: "TestModel",
            version: "1.0.0",
            type: type,
            inputSize: CGSize(width: 640, height: 640),
            fileSize: 45_000_000,
            accuracy: 0.94,
            createdAt: Date()
        )
    }
}

// MARK: - Test Container Factory

enum TestContainerFactory {

    @MainActor
    static func createInMemoryContainer(
        for modelTypes: any PersistentModel.Type...
    ) throws -> ModelContainer {
        let schema = Schema(modelTypes)
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

// MARK: - Async Test Helpers

extension Task where Success == Never, Failure == Never {
    /// Sleep for a specified number of milliseconds
    static func sleepMilliseconds(_ milliseconds: UInt64) async throws {
        try await Task.sleep(nanoseconds: milliseconds * 1_000_000)
    }
}

// MARK: - Date Test Helpers

extension Date {
    static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    }

    static func hoursAgo(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: -hours, to: Date())!
    }

    static func minutesAgo(_ minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: -minutes, to: Date())!
    }
}

// MARK: - Image Test Helpers

enum TestImageGenerator {

    static func createTestCGImage(
        width: Int = 100,
        height: Int = 100,
        color: CGColor = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
    ) -> CGImage {
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

        context.setFillColor(color)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()!
    }

    static func createTestImageData(
        width: Int = 100,
        height: Int = 100
    ) -> Data {
        // Create minimal JPEG data for testing
        let cgImage = createTestCGImage(width: width, height: height)
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .jpeg, properties: [:])!
    }
}

// MARK: - Supporting Types for Tests

struct DetectionResult: Identifiable, Codable, Sendable {
    let id: UUID
    let label: String
    let confidence: Double
    let boundingBox: CGRect
}

struct AnalysisResult: Identifiable, Codable, Sendable {
    let id: UUID
    let captureId: UUID
    let modelType: String
    let modelVersion: String
    let detections: [DetectionResult]
    let processingTime: TimeInterval
    let createdAt: Date
}

struct MLModelMetadata: Identifiable, Codable, Sendable {
    let id: UUID
    let name: String
    let version: String
    let type: MLModelType
    let inputSize: CGSize
    let fileSize: Int
    var accuracy: Double?
    var minimumOSVersion: String?
    let createdAt: Date
}

// MARK: - NSBitmapImageRep stub for Linux/testing

#if !os(macOS)
class NSBitmapImageRep {
    init(cgImage: CGImage) {}

    func representation(using format: ImageFormat, properties: [String: Any]) -> Data? {
        // Return minimal valid JPEG for testing
        return Data([0xFF, 0xD8, 0xFF, 0xD9])
    }

    enum ImageFormat {
        case jpeg
    }
}
#endif
