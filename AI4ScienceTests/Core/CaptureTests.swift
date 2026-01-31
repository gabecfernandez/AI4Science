//
//  CaptureTests.swift
//  AI4ScienceTests
//
//  Created for AI4Science UTSA
//

import Testing
import Foundation
@testable import AI4Science

@Suite("Capture Model Tests")
struct CaptureTests {

    @Test("Photo capture initializes correctly")
    func testPhotoCaptureInit() {
        let capture = Capture(
            id: UUID(),
            sampleId: UUID(),
            type: .photo,
            fileURL: URL(fileURLWithPath: "/captures/photo_001.heic"),
            thumbnailURL: URL(fileURLWithPath: "/captures/thumb_001.jpg"),
            metadata: CaptureMetadata(
                width: 4032,
                height: 3024,
                colorSpace: .sRGB,
                captureDate: Date(),
                deviceModel: "iPhone 15 Pro",
                exposureTime: 1/120,
                iso: 100,
                focalLength: 6.86
            ),
            createdAt: Date(),
            createdBy: UUID()
        )

        #expect(capture.type == .photo)
        #expect(capture.metadata.width == 4032)
        #expect(capture.metadata.height == 3024)
    }

    @Test("Video capture with duration")
    func testVideoCaptureInit() {
        let capture = Capture(
            id: UUID(),
            sampleId: UUID(),
            type: .video,
            fileURL: URL(fileURLWithPath: "/captures/video_001.mov"),
            thumbnailURL: URL(fileURLWithPath: "/captures/thumb_video_001.jpg"),
            metadata: CaptureMetadata(
                width: 1920,
                height: 1080,
                colorSpace: .sRGB,
                captureDate: Date(),
                deviceModel: "iPhone 15 Pro",
                duration: 30.5,
                frameRate: 60
            ),
            createdAt: Date(),
            createdBy: UUID()
        )

        #expect(capture.type == .video)
        #expect(capture.metadata.duration == 30.5)
        #expect(capture.metadata.frameRate == 60)
    }

    @Test("Capture aspect ratio calculation")
    func testCaptureAspectRatio() {
        let metadata = CaptureMetadata(
            width: 4032,
            height: 3024,
            colorSpace: .sRGB,
            captureDate: Date(),
            deviceModel: "iPhone 15 Pro"
        )

        let aspectRatio = metadata.aspectRatio
        #expect(abs(aspectRatio - 1.333) < 0.01)
    }

    @Test("Capture file size formatting")
    func testFileSizeFormatting() {
        let capture = Capture(
            id: UUID(),
            sampleId: UUID(),
            type: .photo,
            fileURL: URL(fileURLWithPath: "/test.jpg"),
            thumbnailURL: nil,
            metadata: CaptureMetadata(
                width: 100,
                height: 100,
                colorSpace: .sRGB,
                captureDate: Date(),
                deviceModel: "Test"
            ),
            fileSize: 2_500_000,
            createdAt: Date(),
            createdBy: UUID()
        )

        #expect(capture.formattedFileSize == "2.5 MB")
    }

    @Test("Capture is Sendable across actors")
    func testCaptureSendable() async {
        let capture = Capture(
            id: UUID(),
            sampleId: UUID(),
            type: .photo,
            fileURL: URL(fileURLWithPath: "/test.jpg"),
            thumbnailURL: nil,
            metadata: CaptureMetadata(
                width: 100,
                height: 100,
                colorSpace: .sRGB,
                captureDate: Date(),
                deviceModel: "Test"
            ),
            createdAt: Date(),
            createdBy: UUID()
        )

        let result = await Task.detached {
            return capture.type
        }.value

        #expect(result == .photo)
    }

    @Test("Capture codable serialization")
    func testCaptureCodable() throws {
        let original = Capture(
            id: UUID(),
            sampleId: UUID(),
            type: .photo,
            fileURL: URL(fileURLWithPath: "/test.jpg"),
            thumbnailURL: nil,
            metadata: CaptureMetadata(
                width: 1920,
                height: 1080,
                colorSpace: .sRGB,
                captureDate: Date(),
                deviceModel: "iPhone"
            ),
            createdAt: Date(),
            createdBy: UUID()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Capture.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.type == original.type)
    }
}

@Suite("Capture Metadata Tests")
struct CaptureMetadataTests {

    @Test("Metadata extracts EXIF data")
    func testMetadataExif() {
        let metadata = CaptureMetadata(
            width: 4032,
            height: 3024,
            colorSpace: .displayP3,
            captureDate: Date(),
            deviceModel: "iPhone 15 Pro Max",
            exposureTime: 1/1000,
            iso: 50,
            focalLength: 6.86,
            aperture: 1.78,
            flashFired: false
        )

        #expect(metadata.exposureTime == 1/1000)
        #expect(metadata.iso == 50)
        #expect(metadata.aperture == 1.78)
        #expect(metadata.flashFired == false)
    }

    @Test("Metadata GPS coordinates")
    func testMetadataGPS() {
        let metadata = CaptureMetadata(
            width: 1920,
            height: 1080,
            colorSpace: .sRGB,
            captureDate: Date(),
            deviceModel: "iPhone",
            latitude: 29.4241,
            longitude: -98.4936
        )

        #expect(metadata.latitude == 29.4241)
        #expect(metadata.longitude == -98.4936)
        #expect(metadata.hasLocation == true)
    }
}
