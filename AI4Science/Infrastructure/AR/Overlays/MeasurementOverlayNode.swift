import SceneKit
import os.log

/// AR node for measurement visualization
class MeasurementOverlayNode: SCNNode {
    private let logger = Logger(subsystem: "com.ai4science.ar", category: "MeasurementOverlayNode")

    private let lineNode = SCNNode()
    private let startMarker = SCNNode()
    private let endMarker = SCNNode()
    private let labelNode = SCNNode()

    let measurementId: String
    var startPoint: SCNVector3
    var endPoint: SCNVector3
    let unit: String

    init(
        measurementId: String,
        from startPoint: SCNVector3,
        to endPoint: SCNVector3,
        unit: String = "m"
    ) {
        self.measurementId = measurementId
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.unit = unit

        super.init()

        self.setupNode()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupNode() {
        // Set position to midpoint
        position = SCNVector3(
            (startPoint.x + endPoint.x) / 2,
            (startPoint.y + endPoint.y) / 2,
            (startPoint.z + endPoint.z) / 2
        )

        // Create line
        createLine()

        // Create markers
        createStartMarker()
        createEndMarker()

        // Create label
        updateLabel()

        logger.info("Measurement overlay node created: \(measurementId)")
    }

    private func createLine() {
        let relativeStart = SCNVector3(
            startPoint.x - position.x,
            startPoint.y - position.y,
            startPoint.z - position.z
        )
        let relativeEnd = SCNVector3(
            endPoint.x - position.x,
            endPoint.y - position.y,
            endPoint.z - position.z
        )

        let vector = SCNVector3(
            relativeEnd.x - relativeStart.x,
            relativeEnd.y - relativeStart.y,
            relativeEnd.z - relativeStart.z
        )

        let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        let capsuleGeometry = SCNCapsule(capRadius: 0.01, height: CGFloat(length))

        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0, green: 1, blue: 1, alpha: 0.8)  // Cyan
        capsuleGeometry.materials = [material]

        lineNode.geometry = capsuleGeometry
        lineNode.position = relativeStart

        // Align capsule with vector
        let direction = SCNVector3(vector.x / length, vector.y / length, vector.z / length)
        lineNode.look(at: SCNVector3(
            relativeStart.x + direction.x,
            relativeStart.y + direction.y,
            relativeStart.z + direction.z
        ), up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 1, 0))

        addChildNode(lineNode)
    }

    private func createStartMarker() {
        let sphereGeometry = SCNSphere(radius: 0.03)

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green
        sphereGeometry.materials = [material]

        let relativeStart = SCNVector3(
            startPoint.x - position.x,
            startPoint.y - position.y,
            startPoint.z - position.z
        )

        startMarker.geometry = sphereGeometry
        startMarker.position = relativeStart

        addChildNode(startMarker)
    }

    private func createEndMarker() {
        let sphereGeometry = SCNSphere(radius: 0.03)

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        sphereGeometry.materials = [material]

        let relativeEnd = SCNVector3(
            endPoint.x - position.x,
            endPoint.y - position.y,
            endPoint.z - position.z
        )

        endMarker.geometry = sphereGeometry
        endMarker.position = relativeEnd

        addChildNode(endMarker)
    }

    // MARK: - Public Methods

    /// Update measurement endpoints
    func updateEndpoints(from newStart: SCNVector3, to newEnd: SCNVector3) {
        startPoint = newStart
        endPoint = newEnd

        position = SCNVector3(
            (startPoint.x + endPoint.x) / 2,
            (startPoint.y + endPoint.y) / 2,
            (startPoint.z + endPoint.z) / 2
        )

        // Recreate visual elements
        lineNode.removeFromParentNode()
        startMarker.removeFromParentNode()
        endMarker.removeFromParentNode()
        labelNode.removeFromParentNode()

        createLine()
        createStartMarker()
        createEndMarker()
        updateLabel()

        logger.info("Measurement \(measurementId) endpoints updated")
    }

    /// Get measurement distance
    func getMeasurementDistance() -> Float {
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let dz = endPoint.z - startPoint.z

        return sqrt(dx * dx + dy * dy + dz * dz)
    }

    /// Highlight the measurement
    func highlight() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3

        if let lineMaterial = lineNode.geometry?.materials.first {
            lineMaterial.diffuse.contents = UIColor.yellow
            lineMaterial.emission.contents = UIColor.yellow
        }

        SCNTransaction.commit()
    }

    /// Remove highlight
    func removeHighlight() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3

        if let lineMaterial = lineNode.geometry?.materials.first {
            lineMaterial.diffuse.contents = UIColor(red: 0, green: 1, blue: 1, alpha: 0.8)
            lineMaterial.emission.contents = UIColor.clear
        }

        SCNTransaction.commit()
    }

    /// Animate pulsing effect
    func pulse() {
        let scaleUp = SCNAction.scale(to: 1.1, duration: 0.5)
        let scaleDown = SCNAction.scale(to: 1.0, duration: 0.5)
        let sequence = SCNAction.sequence([scaleUp, scaleDown])
        let repeatAction = SCNAction.repeatForever(sequence)

        runAction(repeatAction)
    }

    /// Stop animation
    func stopAnimation() {
        removeAllActions()
    }

    // MARK: - Private Methods

    private func updateLabel() {
        labelNode.removeFromParentNode()

        let distance = getMeasurementDistance()
        let labelText = String(format: "%.2f %@", distance, unit)

        let textGeometry = SCNText(string: labelText, extrusionDepth: 0.1)
        textGeometry.font = UIFont.boldSystemFont(ofSize: 2)

        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0, green: 1, blue: 1, alpha: 1.0)
        textGeometry.materials = [material]

        labelNode.geometry = textGeometry
        labelNode.position = SCNVector3(0, 0.2, 0)
        labelNode.scale = SCNVector3(0.01, 0.01, 0.01)

        addChildNode(labelNode)
    }
}
