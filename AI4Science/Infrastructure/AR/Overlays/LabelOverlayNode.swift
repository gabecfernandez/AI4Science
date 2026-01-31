import SceneKit
import os.log

/// AR node for text labels
class LabelOverlayNode: SCNNode {
    private let logger = Logger(subsystem: "com.ai4science.ar", category: "LabelOverlayNode")

    private let textNode = SCNNode()
    private let backgroundNode = SCNNode()

    let labelId: String
    var labelText: String

    enum TextAlignment {
        case left
        case center
        case right

        var value: String {
            switch self {
            case .left:
                return "left"
            case .center:
                return "center"
            case .right:
                return "right"
            }
        }
    }

    init(
        labelId: String,
        text: String,
        position: SCNVector3,
        fontSize: CGFloat = 1.0,
        color: UIColor = .white,
        alignment: TextAlignment = .center,
        hasBackground: Bool = true
    ) {
        self.labelId = labelId
        self.labelText = text

        super.init()

        self.position = position
        self.setupNode(
            with: text,
            fontSize: fontSize,
            color: color,
            alignment: alignment,
            hasBackground: hasBackground
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupNode(
        with text: String,
        fontSize: CGFloat,
        color: UIColor,
        alignment: TextAlignment,
        hasBackground: Bool
    ) {
        createTextGeometry(
            text: text,
            fontSize: fontSize,
            color: color,
            alignment: alignment
        )

        if hasBackground {
            createBackground(color: color)
        }

        logger.info("Label overlay node created: \(labelId)")
    }

    private func createTextGeometry(
        text: String,
        fontSize: CGFloat,
        color: UIColor,
        alignment: TextAlignment
    ) {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.1)
        textGeometry.font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        textGeometry.alignmentMode = alignment.value
        textGeometry.truncationMode = "middle"

        let material = SCNMaterial()
        material.diffuse.contents = color
        material.emission.contents = color.withAlphaComponent(0.3)
        textGeometry.materials = [material]

        textNode.geometry = textGeometry
        textNode.scale = SCNVector3(0.01, 0.01, 0.01)

        addChildNode(textNode)
    }

    private func createBackground(color: UIColor) {
        let backgroundGeometry = SCNBox(width: 2.0, height: 0.8, length: 0.2, chamferRadius: 0.05)

        let material = SCNMaterial()
        material.diffuse.contents = color.withAlphaComponent(0.3)
        material.isDoubleSided = true
        backgroundGeometry.materials = [material]

        backgroundNode.geometry = backgroundGeometry
        backgroundNode.position = SCNVector3(0, 0, -0.15)
        backgroundNode.renderingOrder = -1

        addChildNode(backgroundNode)
    }

    // MARK: - Public Methods

    /// Update label text
    func updateText(_ newText: String) {
        labelText = newText

        textNode.removeFromParentNode()
        createTextGeometry(
            text: newText,
            fontSize: 1.0,
            color: .white,
            alignment: .center
        )

        logger.info("Label \(labelId) text updated to: '\(newText)'")
    }

    /// Update label color
    func updateColor(_ newColor: UIColor) {
        if let textMaterial = textNode.geometry?.materials.first {
            textMaterial.diffuse.contents = newColor
            textMaterial.emission.contents = newColor.withAlphaComponent(0.3)
        }

        if let backgroundMaterial = backgroundNode.geometry?.materials.first {
            backgroundMaterial.diffuse.contents = newColor.withAlphaComponent(0.3)
        }

        logger.info("Label \(labelId) color updated")
    }

    /// Make label face camera
    func billboardToCamera(_ camera: SCNNode) {
        // Calculate direction from this node to camera
        let direction = SCNVector3(
            camera.position.x - position.x,
            camera.position.y - position.y,
            camera.position.z - position.z
        )

        // Point towards camera
        look(at: camera.position, up: SCNVector3(0, 1, 0), localFront: direction)
    }

    /// Animate fade in
    func fadeIn(duration: TimeInterval = 0.3) {
        opacity = 0
        let fadeIn = SCNAction.fadeIn(duration: duration)
        runAction(fadeIn)
    }

    /// Animate fade out
    func fadeOut(duration: TimeInterval = 0.3) {
        let fadeOut = SCNAction.fadeOut(duration: duration)
        runAction(fadeOut)
    }

    /// Scale animation
    func scaleAnimation(duration: TimeInterval = 0.5) {
        let scaleUp = SCNAction.scale(to: 1.1, duration: duration / 2)
        let scaleDown = SCNAction.scale(to: 1.0, duration: duration / 2)
        let sequence = SCNAction.sequence([scaleUp, scaleDown])

        runAction(sequence)
    }

    /// Continuous pulse animation
    func startPulsing() {
        let scaleUp = SCNAction.scale(to: 1.05, duration: 1.0)
        let scaleDown = SCNAction.scale(to: 0.95, duration: 1.0)
        let sequence = SCNAction.sequence([scaleUp, scaleDown])
        let repeatAction = SCNAction.repeatForever(sequence)

        runAction(repeatAction)
    }

    /// Stop all animations
    func stopAnimations() {
        removeAllActions()
    }

    /// Get label information
    func getLabelInfo() -> LabelInfo {
        return LabelInfo(
            id: labelId,
            text: labelText,
            position: position,
            opacity: Float(opacity)
        )
    }
}

struct LabelInfo {
    let id: String
    let text: String
    let position: SCNVector3
    let opacity: Float
}
