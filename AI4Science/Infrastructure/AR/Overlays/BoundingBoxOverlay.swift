import SceneKit
import os.log

/// AR node for bounding box visualization
class BoundingBoxOverlay: SCNNode {
    private let logger = Logger(subsystem: "com.ai4science.ar", category: "BoundingBoxOverlay")

    private let boxNode = SCNNode()
    private let edgeNodes: [SCNNode] = []
    private let cornerNodes: [SCNNode] = []

    let boxId: String
    var center: SCNVector3
    var extent: SCNVector3

    enum BoundingBoxStyle {
        case wireframe
        case solid
        case edges
        case corners

        var description: String {
            switch self {
            case .wireframe:
                return "Wireframe"
            case .solid:
                return "Solid"
            case .edges:
                return "Edges"
            case .corners:
                return "Corners"
            }
        }
    }

    init(
        boxId: String,
        center: SCNVector3,
        extent: SCNVector3,
        color: UIColor = UIColor(red: 0, green: 1, blue: 1, alpha: 0.5),
        style: BoundingBoxStyle = .wireframe
    ) {
        self.boxId = boxId
        self.center = center
        self.extent = extent

        super.init()

        self.position = center
        self.setupNode(color: color, style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupNode(color: UIColor, style: BoundingBoxStyle) {
        switch style {
        case .wireframe:
            createWireframeBox(color: color)
        case .solid:
            createSolidBox(color: color)
        case .edges:
            createEdges(color: color)
        case .corners:
            createCorners(color: color)
        }

        logger.info("Bounding box overlay created: \(boxId) with style: \(style.description)")
    }

    private func createWireframeBox(color: UIColor) {
        let boxGeometry = SCNBox(
            width: CGFloat(extent.x),
            height: CGFloat(extent.y),
            length: CGFloat(extent.z),
            chamferRadius: 0
        )

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.clear
        material.isDoubleSided = true

        // Create wireframe by using stroke
        boxGeometry.materials = [material]

        boxNode.geometry = boxGeometry
        addChildNode(boxNode)

        // Create visible edges
        createWireframeEdges(color: color)
    }

    private func createWireframeEdges(color: UIColor) {
        let halfX = CGFloat(extent.x) / 2
        let halfY = CGFloat(extent.y) / 2
        let halfZ = CGFloat(extent.z) / 2

        let corners = [
            SCNVector3(-halfX, -halfY, -halfZ),
            SCNVector3(halfX, -halfY, -halfZ),
            SCNVector3(-halfX, halfY, -halfZ),
            SCNVector3(halfX, halfY, -halfZ),
            SCNVector3(-halfX, -halfY, halfZ),
            SCNVector3(halfX, -halfY, halfZ),
            SCNVector3(-halfX, halfY, halfZ),
            SCNVector3(halfX, halfY, halfZ),
        ]

        let edgePairs = [
            (0, 1), (2, 3), (4, 5), (6, 7),  // X edges
            (0, 2), (1, 3), (4, 6), (5, 7),  // Y edges
            (0, 4), (1, 5), (2, 6), (3, 7),  // Z edges
        ]

        for (start, end) in edgePairs {
            let startCorner = corners[start]
            let endCorner = corners[end]

            let edgeNode = createCapsule(
                from: startCorner,
                to: endCorner,
                color: color
            )

            addChildNode(edgeNode)
        }
    }

    private func createSolidBox(color: UIColor) {
        let boxGeometry = SCNBox(
            width: CGFloat(extent.x),
            height: CGFloat(extent.y),
            length: CGFloat(extent.z),
            chamferRadius: 0.01
        )

        let material = SCNMaterial()
        material.diffuse.contents = color
        material.transparency = 0.6
        material.isDoubleSided = true
        boxGeometry.materials = [material]

        boxNode.geometry = boxGeometry
        addChildNode(boxNode)
    }

    private func createEdges(color: UIColor) {
        let halfX = CGFloat(extent.x) / 2
        let halfY = CGFloat(extent.y) / 2
        let halfZ = CGFloat(extent.z) / 2

        let corners = [
            SCNVector3(-halfX, -halfY, -halfZ),
            SCNVector3(halfX, -halfY, -halfZ),
            SCNVector3(-halfX, halfY, -halfZ),
            SCNVector3(halfX, halfY, -halfZ),
            SCNVector3(-halfX, -halfY, halfZ),
            SCNVector3(halfX, -halfY, halfZ),
            SCNVector3(-halfX, halfY, halfZ),
            SCNVector3(halfX, halfY, halfZ),
        ]

        let edgePairs = [
            (0, 1), (2, 3), (4, 5), (6, 7),
            (0, 2), (1, 3), (4, 6), (5, 7),
            (0, 4), (1, 5), (2, 6), (3, 7),
        ]

        for (start, end) in edgePairs {
            let startCorner = corners[start]
            let endCorner = corners[end]

            let edgeNode = createCapsule(
                from: startCorner,
                to: endCorner,
                color: color,
                radius: 0.02
            )

            addChildNode(edgeNode)
        }
    }

    private func createCorners(color: UIColor) {
        let halfX = CGFloat(extent.x) / 2
        let halfY = CGFloat(extent.y) / 2
        let halfZ = CGFloat(extent.z) / 2

        let corners = [
            SCNVector3(-halfX, -halfY, -halfZ),
            SCNVector3(halfX, -halfY, -halfZ),
            SCNVector3(-halfX, halfY, -halfZ),
            SCNVector3(halfX, halfY, -halfZ),
            SCNVector3(-halfX, -halfY, halfZ),
            SCNVector3(halfX, -halfY, halfZ),
            SCNVector3(-halfX, halfY, halfZ),
            SCNVector3(halfX, halfY, halfZ),
        ]

        for corner in corners {
            let sphereGeometry = SCNSphere(radius: 0.05)

            let material = SCNMaterial()
            material.diffuse.contents = color
            sphereGeometry.materials = [material]

            let cornerNode = SCNNode()
            cornerNode.geometry = sphereGeometry
            cornerNode.position = corner

            addChildNode(cornerNode)
        }
    }

    // MARK: - Public Methods

    /// Update bounding box extent
    func updateExtent(_ newExtent: SCNVector3) {
        extent = newExtent

        removeAllChildNodes()
        setupNode(color: .cyan, style: .wireframe)
    }

    /// Update bounding box color
    func updateColor(_ newColor: UIColor) {
        for child in childNodes {
            if let geometry = child.geometry {
                if let material = geometry.materials.first {
                    material.diffuse.contents = newColor
                }
            }
        }

        logger.info("Bounding box \(boxId) color updated")
    }

    /// Highlight the bounding box
    func highlight() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3

        opacity = 1.0

        for child in childNodes {
            if let geometry = child.geometry {
                if let material = geometry.materials.first {
                    material.emission.contents = UIColor.yellow
                }
            }
        }

        SCNTransaction.commit()
    }

    /// Remove highlight
    func removeHighlight() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3

        opacity = 0.7

        for child in childNodes {
            if let geometry = child.geometry {
                if let material = geometry.materials.first {
                    material.emission.contents = UIColor.clear
                }
            }
        }

        SCNTransaction.commit()
    }

    /// Rotate animation
    func rotate(duration: TimeInterval = 3.0) {
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: duration)
        let repeatAction = SCNAction.repeatForever(rotation)

        runAction(repeatAction)
    }

    /// Stop animation
    func stopAnimation() {
        removeAllActions()
    }

    /// Get bounding box information
    func getBoundingBoxInfo() -> BoundingBoxInfo {
        return BoundingBoxInfo(
            id: boxId,
            center: position,
            extent: extent,
            rotation: eulerAngles
        )
    }

    // MARK: - Private Methods

    private func createCapsule(
        from start: SCNVector3,
        to end: SCNVector3,
        color: UIColor,
        radius: CGFloat = 0.01
    ) -> SCNNode {
        let vector = SCNVector3(
            end.x - start.x,
            end.y - start.y,
            end.z - start.z
        )

        let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        let capsuleGeometry = SCNCapsule(capRadius: radius, height: CGFloat(length))

        let material = SCNMaterial()
        material.diffuse.contents = color
        capsuleGeometry.materials = [material]

        let capsuleNode = SCNNode(geometry: capsuleGeometry)
        capsuleNode.position = start

        let midPoint = SCNVector3(
            (start.x + end.x) / 2,
            (start.y + end.y) / 2,
            (start.z + end.z) / 2
        )

        capsuleNode.look(
            at: midPoint,
            up: SCNVector3(0, 1, 0),
            localFront: SCNVector3(0, 1, 0)
        )

        return capsuleNode
    }
}

struct BoundingBoxInfo {
    let id: String
    let center: SCNVector3
    let extent: SCNVector3
    let rotation: SCNVector3
}
