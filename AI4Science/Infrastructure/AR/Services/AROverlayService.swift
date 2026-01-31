import ARKit
import os.log

/// Service for creating real-time AR overlays for defect visualization
actor AROverlayService {
    static let shared = AROverlayService()

    private let logger = Logger(subsystem: "com.ai4science.ar", category: "AROverlayService")

    private var activeOverlays: [String: AROverlay] = [:]

    enum OverlayError: LocalizedError {
        case invalidAnchor
        case overlayNotFound
        case invalidGeometry

        var errorDescription: String? {
            switch self {
            case .invalidAnchor:
                return "Invalid AR anchor"
            case .overlayNotFound:
                return "Overlay not found"
            case .invalidGeometry:
                return "Invalid geometry for overlay"
            }
        }
    }

    struct AROverlay {
        let id: String
        let type: OverlayType
        let anchor: AnchorData
        var isVisible: Bool
        let createdAt: Date

        enum OverlayType {
            case defect(DefectInfo)
            case measurement(MeasurementInfo)
            case label(LabelInfo)
            case boundingBox(BoundingBoxInfo)
        }
    }

    struct DefectInfo {
        let severity: DefectSeverity
        let location: SIMD3<Float>
        let extent: SIMD3<Float>
        let confidence: Float
        let description: String

        enum DefectSeverity {
            case low
            case medium
            case high
            case critical

            var color: (red: Float, green: Float, blue: Float) {
                switch self {
                case .low:
                    return (0.0, 1.0, 0.0)  // Green
                case .medium:
                    return (1.0, 1.0, 0.0)  // Yellow
                case .high:
                    return (1.0, 0.5, 0.0)  // Orange
                case .critical:
                    return (1.0, 0.0, 0.0)  // Red
                }
            }
        }
    }

    struct MeasurementInfo {
        let startPoint: SIMD3<Float>
        let endPoint: SIMD3<Float>
        let distance: Float
        let unit: String
    }

    struct LabelInfo {
        let position: SIMD3<Float>
        let text: String
        let fontSize: Float
    }

    struct BoundingBoxInfo {
        let center: SIMD3<Float>
        let extent: SIMD3<Float>
        let orientation: simd_quatf
    }

    struct AnchorData {
        let position: SIMD3<Float>
        let transform: simd_float4x4
    }

    nonisolated init() {
        // Empty init for actor
    }

    /// Create a defect overlay
    func createDefectOverlay(
        id: String,
        location: SIMD3<Float>,
        extent: SIMD3<Float>,
        severity: DefectInfo.DefectSeverity,
        confidence: Float,
        description: String,
        in frame: ARFrame
    ) async throws -> AROverlay {
        let defectInfo = DefectInfo(
            severity: severity,
            location: location,
            extent: extent,
            confidence: confidence,
            description: description
        )

        let anchor = AnchorData(
            position: location,
            transform: frame.camera.transform
        )

        let overlay = AROverlay(
            id: id,
            type: .defect(defectInfo),
            anchor: anchor,
            isVisible: true,
            createdAt: Date()
        )

        activeOverlays[id] = overlay

        logger.info("Defect overlay created: \(id) with severity: \(severity.description)")
        return overlay
    }

    /// Create a measurement overlay
    func createMeasurementOverlay(
        id: String,
        from startPoint: SIMD3<Float>,
        to endPoint: SIMD3<Float>,
        unit: String = "m",
        in frame: ARFrame
    ) async throws -> AROverlay {
        let distance = simd_distance(startPoint, endPoint)

        let measurementInfo = MeasurementInfo(
            startPoint: startPoint,
            endPoint: endPoint,
            distance: distance,
            unit: unit
        )

        let midPoint = (startPoint + endPoint) / 2
        let anchor = AnchorData(
            position: midPoint,
            transform: frame.camera.transform
        )

        let overlay = AROverlay(
            id: id,
            type: .measurement(measurementInfo),
            anchor: anchor,
            isVisible: true,
            createdAt: Date()
        )

        activeOverlays[id] = overlay

        logger.info("Measurement overlay created: \(id), distance: \(distance) \(unit)")
        return overlay
    }

    /// Create a label overlay
    func createLabelOverlay(
        id: String,
        text: String,
        at position: SIMD3<Float>,
        fontSize: Float = 1.0,
        in frame: ARFrame
    ) async throws -> AROverlay {
        let labelInfo = LabelInfo(
            position: position,
            text: text,
            fontSize: fontSize
        )

        let anchor = AnchorData(
            position: position,
            transform: frame.camera.transform
        )

        let overlay = AROverlay(
            id: id,
            type: .label(labelInfo),
            anchor: anchor,
            isVisible: true,
            createdAt: Date()
        )

        activeOverlays[id] = overlay

        logger.info("Label overlay created: \(id), text: '\(text)'")
        return overlay
    }

    /// Create a bounding box overlay
    func createBoundingBoxOverlay(
        id: String,
        center: SIMD3<Float>,
        extent: SIMD3<Float>,
        orientation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0]),
        in frame: ARFrame
    ) async throws -> AROverlay {
        let boundingBoxInfo = BoundingBoxInfo(
            center: center,
            extent: extent,
            orientation: orientation
        )

        let anchor = AnchorData(
            position: center,
            transform: frame.camera.transform
        )

        let overlay = AROverlay(
            id: id,
            type: .boundingBox(boundingBoxInfo),
            anchor: anchor,
            isVisible: true,
            createdAt: Date()
        )

        activeOverlays[id] = overlay

        logger.info("Bounding box overlay created: \(id)")
        return overlay
    }

    /// Update overlay visibility
    func setOverlayVisibility(id: String, visible: Bool) throws {
        guard var overlay = activeOverlays[id] else {
            throw OverlayError.overlayNotFound
        }

        overlay.isVisible = visible
        activeOverlays[id] = overlay

        logger.debug("Overlay \(id) visibility: \(visible)")
    }

    /// Remove overlay
    func removeOverlay(id: String) throws {
        guard activeOverlays.removeValue(forKey: id) != nil else {
            throw OverlayError.overlayNotFound
        }

        logger.info("Overlay removed: \(id)")
    }

    /// Remove all overlays
    func removeAllOverlays() {
        activeOverlays.removeAll()
        logger.info("All overlays removed")
    }

    /// Get overlay by ID
    func getOverlay(id: String) -> AROverlay? {
        return activeOverlays[id]
    }

    /// Get all active overlays
    func getAllOverlays() -> [AROverlay] {
        return Array(activeOverlays.values)
    }

    /// Get all visible overlays
    func getVisibleOverlays() -> [AROverlay] {
        return activeOverlays.values.filter { $0.isVisible }
    }

    /// Update overlay position
    func updateOverlayPosition(id: String, newPosition: SIMD3<Float>) throws {
        guard var overlay = activeOverlays[id] else {
            throw OverlayError.overlayNotFound
        }

        var updatedAnchor = overlay.anchor
        updatedAnchor.position = newPosition
        overlay = AROverlay(
            id: overlay.id,
            type: overlay.type,
            anchor: updatedAnchor,
            isVisible: overlay.isVisible,
            createdAt: overlay.createdAt
        )
        activeOverlays[id] = overlay

        logger.debug("Overlay \(id) position updated")
    }

    /// Get overlays in region
    func getOverlaysInRegion(center: SIMD3<Float>, radius: Float) -> [AROverlay] {
        return activeOverlays.values.filter { overlay in
            let distance = simd_distance(overlay.anchor.position, center)
            return distance <= radius
        }
    }

    /// Count overlays by type
    func countOverlaysByType() -> [String: Int] {
        var counts: [String: Int] = [:]

        for overlay in activeOverlays.values {
            let typeKey: String
            switch overlay.type {
            case .defect:
                typeKey = "defect"
            case .measurement:
                typeKey = "measurement"
            case .label:
                typeKey = "label"
            case .boundingBox:
                typeKey = "boundingBox"
            }

            counts[typeKey, default: 0] += 1
        }

        return counts
    }
}

private extension AROverlayService.DefectInfo.DefectSeverity {
    var description: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        case .critical:
            return "Critical"
        }
    }
}
