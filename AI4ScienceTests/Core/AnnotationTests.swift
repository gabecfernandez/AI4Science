//
//  AnnotationTests.swift
//  AI4ScienceTests
//
//  Created for AI4Science UTSA
//

import Testing
import Foundation
import CoreGraphics
@testable import AI4Science

@Suite("Annotation Model Tests")
struct AnnotationTests {

    // MARK: - Point Annotation Tests

    @Test("Point annotation initializes correctly")
    func testPointAnnotationInit() {
        let annotation = Annotation(
            id: UUID(),
            captureId: UUID(),
            type: .point,
            geometry: .point(CGPoint(x: 100, y: 150)),
            label: "Crack",
            defectType: .crack,
            severity: .moderate,
            confidence: 0.95,
            createdAt: Date(),
            createdBy: UUID()
        )

        #expect(annotation.type == .point)
        #expect(annotation.label == "Crack")
        #expect(annotation.severity == .moderate)

        if case .point(let point) = annotation.geometry {
            #expect(point.x == 100)
            #expect(point.y == 150)
        } else {
            Issue.record("Expected point geometry")
        }
    }

    // MARK: - Rectangle Annotation Tests

    @Test("Rectangle annotation initializes correctly")
    func testRectAnnotationInit() {
        let rect = CGRect(x: 50, y: 50, width: 200, height: 100)
        let annotation = Annotation(
            id: UUID(),
            captureId: UUID(),
            type: .rectangle,
            geometry: .rectangle(rect),
            label: "Void",
            defectType: .void,
            severity: .severe,
            confidence: 0.88,
            createdAt: Date(),
            createdBy: UUID()
        )

        #expect(annotation.type == .rectangle)

        if case .rectangle(let annotationRect) = annotation.geometry {
            #expect(annotationRect.width == 200)
            #expect(annotationRect.height == 100)
        } else {
            Issue.record("Expected rectangle geometry")
        }
    }

    // MARK: - Polygon Annotation Tests

    @Test("Polygon annotation initializes with points")
    func testPolygonAnnotationInit() {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 100, y: 0),
            CGPoint(x: 100, y: 100),
            CGPoint(x: 50, y: 150),
            CGPoint(x: 0, y: 100)
        ]

        let annotation = Annotation(
            id: UUID(),
            captureId: UUID(),
            type: .polygon,
            geometry: .polygon(points),
            label: "Inclusion",
            defectType: .inclusion,
            severity: .minor,
            confidence: 0.92,
            createdAt: Date(),
            createdBy: UUID()
        )

        #expect(annotation.type == .polygon)

        if case .polygon(let annotationPoints) = annotation.geometry {
            #expect(annotationPoints.count == 5)
        } else {
            Issue.record("Expected polygon geometry")
        }
    }

    // MARK: - Freeform Annotation Tests

    @Test("Freeform annotation with path")
    func testFreeformAnnotation() {
        let pathPoints = (0..<50).map { i in
            CGPoint(x: Double(i) * 2, y: sin(Double(i) / 5) * 20 + 50)
        }

        let annotation = Annotation(
            id: UUID(),
            captureId: UUID(),
            type: .freeform,
            geometry: .freeform(pathPoints),
            label: "Scratch",
            defectType: .scratch,
            severity: .minor,
            confidence: 0.78,
            createdAt: Date(),
            createdBy: UUID()
        )

        #expect(annotation.type == .freeform)

        if case .freeform(let path) = annotation.geometry {
            #expect(path.count == 50)
        } else {
            Issue.record("Expected freeform geometry")
        }
    }

    // MARK: - Bounding Box Tests

    @Test("Annotation calculates bounding box correctly")
    func testBoundingBox() {
        let points = [
            CGPoint(x: 10, y: 20),
            CGPoint(x: 100, y: 20),
            CGPoint(x: 100, y: 80),
            CGPoint(x: 10, y: 80)
        ]

        let annotation = Annotation(
            id: UUID(),
            captureId: UUID(),
            type: .polygon,
            geometry: .polygon(points),
            label: "Test",
            defectType: .other,
            severity: .minor,
            confidence: 0.9,
            createdAt: Date(),
            createdBy: UUID()
        )

        let boundingBox = annotation.boundingBox

        #expect(boundingBox.origin.x == 10)
        #expect(boundingBox.origin.y == 20)
        #expect(boundingBox.width == 90)
        #expect(boundingBox.height == 60)
    }

    // MARK: - Area Calculation Tests

    @Test("Rectangle annotation area calculation")
    func testRectangleArea() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        let annotation = Annotation(
            id: UUID(),
            captureId: UUID(),
            type: .rectangle,
            geometry: .rectangle(rect),
            label: "Test",
            defectType: .void,
            severity: .moderate,
            confidence: 0.85,
            createdAt: Date(),
            createdBy: UUID()
        )

        #expect(annotation.area == 5000)
    }

    // MARK: - Codable Tests

    @Test("Annotation encodes and decodes correctly")
    func testAnnotationCodable() throws {
        let original = Annotation(
            id: UUID(),
            captureId: UUID(),
            type: .rectangle,
            geometry: .rectangle(CGRect(x: 10, y: 20, width: 100, height: 50)),
            label: "Defect",
            defectType: .crack,
            severity: .severe,
            confidence: 0.95,
            createdAt: Date(),
            createdBy: UUID()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Annotation.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.type == original.type)
        #expect(decoded.label == original.label)
        #expect(decoded.severity == original.severity)
    }

    // MARK: - Severity Tests

    @Test("Defect severity ordering")
    func testSeverityOrdering() {
        #expect(DefectSeverity.minor.rawValue < DefectSeverity.moderate.rawValue)
        #expect(DefectSeverity.moderate.rawValue < DefectSeverity.severe.rawValue)
        #expect(DefectSeverity.severe.rawValue < DefectSeverity.critical.rawValue)
    }
}

// MARK: - Defect Type Tests

@Suite("Defect Type Tests")
struct DefectTypeTests {

    @Test("All defect types have display names")
    func testDefectTypeDisplayNames() {
        for defectType in DefectType.allCases {
            #expect(!defectType.displayName.isEmpty)
        }
    }

    @Test("All defect types have icons")
    func testDefectTypeIcons() {
        for defectType in DefectType.allCases {
            #expect(!defectType.iconName.isEmpty)
        }
    }

    @Test("Defect type categories are correct")
    func testDefectTypeCategories() {
        #expect(DefectType.crack.category == .structural)
        #expect(DefectType.void.category == .structural)
        #expect(DefectType.inclusion.category == .contamination)
        #expect(DefectType.scratch.category == .surface)
    }
}
