import ARKit
import SceneKit
import os.log

/// AR node for defect highlighting
class DefectOverlayNode: SCNNode {
    private let logger = Logger(subsystem: "com.ai4science.ar", category: "DefectOverlayNode")

    private let boxNode = SCNNode()
    private let labelNode = SCNNode()
    private let confidenceIndicator = SCNNode()

    let defectId: String
    let severity: DefectSeverity
    let confidence: Float

    enum DefectSeverity {
        case low
        case medium
        case high
        case critical

        var color: UIColor {
            switch self {
            case .low:
                return UIColor(red: 0, green: 1, blue: 0, alpha: 0.6)  // Green
            case .medium:
                return UIColor(red: 1, green: 1, blue: 0, alpha: 0.6)  // Yellow
            case .high:
                return UIColor(red: 1, green: 0.5, blue: 0, alpha: 0.6) // Orange
            case .critical:
                return UIColor(red: 1, green: 0, blue: 0, alpha: 0.6)   // Red
            }
        }

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

    init(
        defectId: String,
        position: SCNVector3,
        extent: SCNVector3,
        severity: DefectSeverity,
        confidence: Float,
        description: String
    ) {
        self.defectId = defectId
        self.severity = severity
        self.confidence = confidence

        super.init()

        self.position = position
        self.setupNode(with: extent, description: description)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupNode(with extent: SCNVector3, description: String) {
        // Create bounding box
        let boxGeometry = SCNBox(
            width: CGFloat(extent.x),
            height: CGFloat(extent.y),
            length: CGFloat(extent.z),
            chamferRadius: 0.01
        )

        let material = SCNMaterial()
        material.diffuse.contents = severity.color
        material.transparency = 0.6
        material.isDoubleSided = true

        boxGeometry.materials = [material]
        boxNode.geometry = boxGeometry
        addChildNode(boxNode)

        // Create label
        createLabel(text: "\(severity.description) Severity\nConfidence: \(Int(confidence * 100))%")

        // Create confidence indicator
        createConfidenceIndicator()

        logger.info("Defect overlay node created: \(defectId)")
    }

    private func createLabel(text: String) {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.1)
        textGeometry.font = UIFont.systemFont(ofSize: 2)
        textGeometry.containerFrame = CGRect(x: 0, y: 0, width: 20, height: 10)
        textGeometry.isWrapped = true

        let material = SCNMaterial()
        material.diffuse.contents = severity.color
        textGeometry.materials = [material]

        labelNode.geometry = textGeometry
        labelNode.position = SCNVector3(0, 2, 0)
        labelNode.scale = SCNVector3(0.02, 0.02, 0.02)

        addChildNode(labelNode)
    }

    private func createConfidenceIndicator() {
        // Create a ring to show confidence level
        let ringRadius: CGFloat = 0.5
        let confidenceAngle = CGFloat(confidence) * .pi * 2

        let ringGeometry = SCNTorus(
            ringRadius: ringRadius,
            tubeRadius: 0.05
        )

        let material = SCNMaterial()
        material.diffuse.contents = severity.color
        ringGeometry.materials = [material]

        confidenceIndicator.geometry = ringGeometry
        confidenceIndicator.position = SCNVector3(0, 0.5, 0)
        confidenceIndicator.eulerAngles = SCNVector3(-.pi / 2, 0, 0)

        addChildNode(confidenceIndicator)
    }

    // MARK: - Public Methods

    /// Update severity color
    func updateSeverity(_ newSeverity: DefectSeverity) {
        let newColor = newSeverity.color

        if let boxMaterial = boxNode.geometry?.materials.first {
            boxMaterial.diffuse.contents = newColor
        }

        if let textMaterial = labelNode.geometry?.materials.first {
            textMaterial.diffuse.contents = newColor
        }

        if let ringMaterial = confidenceIndicator.geometry?.materials.first {
            ringMaterial.diffuse.contents = newColor
        }

        logger.info("Defect \(defectId) severity updated to: \(newSeverity.description)")
    }

    /// Animate the node
    func animate() {
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 3)
        let repeatAction = SCNAction.repeatForever(rotation)
        runAction(repeatAction)
    }

    /// Stop animation
    func stopAnimation() {
        removeAllActions()
    }

    /// Highlight the node
    func highlight() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3

        let highlightMaterial = SCNMaterial()
        highlightMaterial.diffuse.contents = severity.color
        highlightMaterial.emission.contents = severity.color
        highlightMaterial.transparency = 0.7

        if let boxGeometry = boxNode.geometry {
            boxGeometry.materials = [highlightMaterial]
        }

        SCNTransaction.commit()
    }

    /// Remove highlight
    func removeHighlight() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3

        let material = SCNMaterial()
        material.diffuse.contents = severity.color
        material.transparency = 0.6

        if let boxGeometry = boxNode.geometry {
            boxGeometry.materials = [material]
        }

        SCNTransaction.commit()
    }

    /// Get defect information
    func getDefectInfo() -> DefectInfo {
        return DefectInfo(
            id: defectId,
            severity: severity,
            confidence: confidence,
            position: position
        )
    }
}

struct DefectInfo {
    let id: String
    let severity: DefectOverlayNode.DefectSeverity
    let confidence: Float
    let position: SCNVector3
}
