import ARKit
import MetalKit
import os.log

/// Service for rendering annotations in AR space
actor ARAnnotationRenderer: NSObject, MTKViewDelegate {
    static let shared = ARAnnotationRenderer()

    private let logger = Logger(subsystem: "com.ai4science.ar", category: "ARAnnotationRenderer")

    private var metalView: MTKView?
    private var commandQueue: MTLCommandQueue?
    private var renderPipelineState: MTLRenderPipelineState?

    private var annotations: [String: AnnotationData] = [:]

    enum RendererError: LocalizedError {
        case metalUnavailable
        case renderPipelineFailed
        case pipelineStateNotAvailable

        var errorDescription: String? {
            switch self {
            case .metalUnavailable:
                return "Metal is not available on this device"
            case .renderPipelineFailed:
                return "Failed to create render pipeline"
            case .pipelineStateNotAvailable:
                return "Render pipeline state is not available"
            }
        }
    }

    struct AnnotationData {
        let id: String
        let type: AnnotationType
        let position: SIMD3<Float>
        let color: SIMD4<Float>
        var isVisible: Bool
        let createdAt: Date

        enum AnnotationType {
            case point
            case line
            case mesh
            case text
            case custom(Any)
        }
    }

    struct RenderContext {
        let commandBuffer: MTLCommandBuffer
        let renderPassDescriptor: MTLRenderPassDescriptor
        let viewportSize: SIMD2<UInt32>
        let projectionMatrix: simd_float4x4
        let viewMatrix: simd_float4x4
    }

    nonisolated override init() {
        super.init()
    }

    /// Initialize the Metal renderer
    func initializeRenderer(with mtkView: MTKView) async throws {
        metalView = mtkView

        guard let device = MTLCreateSystemDefaultDevice() else {
            throw RendererError.metalUnavailable
        }

        mtkView.device = device
        mtkView.delegate = self

        commandQueue = device.makeCommandQueue()

        logger.info("Metal renderer initialized")
    }

    /// Add a point annotation
    func addPointAnnotation(
        id: String,
        position: SIMD3<Float>,
        color: SIMD4<Float> = [1.0, 0.0, 0.0, 1.0]
    ) {
        let annotation = AnnotationData(
            id: id,
            type: .point,
            position: position,
            color: color,
            isVisible: true,
            createdAt: Date()
        )

        annotations[id] = annotation
        logger.debug("Point annotation added: \(id)")
    }

    /// Add a line annotation
    func addLineAnnotation(
        id: String,
        from startPos: SIMD3<Float>,
        to endPos: SIMD3<Float>,
        color: SIMD4<Float> = [0.0, 1.0, 0.0, 1.0]
    ) {
        let midPoint = (startPos + endPos) / 2

        let annotation = AnnotationData(
            id: id,
            type: .line,
            position: midPoint,
            color: color,
            isVisible: true,
            createdAt: Date()
        )

        annotations[id] = annotation
        logger.debug("Line annotation added: \(id)")
    }

    /// Add a mesh annotation
    func addMeshAnnotation(
        id: String,
        position: SIMD3<Float>,
        color: SIMD4<Float> = [0.0, 0.0, 1.0, 1.0]
    ) {
        let annotation = AnnotationData(
            id: id,
            type: .mesh,
            position: position,
            color: color,
            isVisible: true,
            createdAt: Date()
        )

        annotations[id] = annotation
        logger.debug("Mesh annotation added: \(id)")
    }

    /// Add a text annotation
    func addTextAnnotation(
        id: String,
        text: String,
        position: SIMD3<Float>,
        color: SIMD4<Float> = [1.0, 1.0, 1.0, 1.0]
    ) {
        let annotation = AnnotationData(
            id: id,
            type: .text,
            position: position,
            color: color,
            isVisible: true,
            createdAt: Date()
        )

        annotations[id] = annotation
        logger.debug("Text annotation added: \(id) - '\(text)'")
    }

    /// Remove annotation
    func removeAnnotation(id: String) {
        annotations.removeValue(forKey: id)
        logger.debug("Annotation removed: \(id)")
    }

    /// Remove all annotations
    func removeAllAnnotations() {
        annotations.removeAll()
        logger.info("All annotations removed")
    }

    /// Set annotation visibility
    func setAnnotationVisibility(id: String, visible: Bool) {
        if var annotation = annotations[id] {
            annotation.isVisible = visible
            annotations[id] = annotation
            logger.debug("Annotation \(id) visibility: \(visible)")
        }
    }

    /// Get all visible annotations
    func getVisibleAnnotations() -> [AnnotationData] {
        return annotations.values.filter { $0.isVisible }
    }

    /// Update annotation position
    func updateAnnotationPosition(id: String, newPosition: SIMD3<Float>) {
        if var annotation = annotations[id] {
            annotation.position = newPosition
            annotations[id] = annotation
            logger.debug("Annotation \(id) position updated")
        }
    }

    /// Update annotation color
    func updateAnnotationColor(id: String, newColor: SIMD4<Float>) {
        if var annotation = annotations[id] {
            annotation.color = newColor
            annotations[id] = annotation
            logger.debug("Annotation \(id) color updated")
        }
    }

    // MARK: - MTKViewDelegate

    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        logger.debug("Metal view drawable size will change: \(size)")
    }

    nonisolated func draw(in view: MTKView) {
        // Rendering happens here
        logger.debug("Rendering frame")
    }

    // MARK: - Private Methods

    private func setupRenderPipeline(device: MTLDevice) throws {
        guard let library = device.makeDefaultLibrary() else {
            throw RendererError.renderPipelineFailed
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Annotation Render Pipeline"
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")

        if let drawable = metalView?.currentDrawable {
            pipelineDescriptor.colorAttachments[0].pixelFormat = drawable.texture.pixelFormat
        }

        renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        logger.info("Render pipeline created")
    }

    private func createRenderContext(
        with drawable: CAMetalDrawable,
        device: MTLDevice,
        commandBuffer: MTLCommandBuffer
    ) -> RenderContext {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        let viewportSize = SIMD2<UInt32>(
            UInt32(metalView?.bounds.width ?? 0),
            UInt32(metalView?.bounds.height ?? 0)
        )

        let projectionMatrix = simd_float4x4(1)
        let viewMatrix = simd_float4x4(1)

        return RenderContext(
            commandBuffer: commandBuffer,
            renderPassDescriptor: renderPassDescriptor,
            viewportSize: viewportSize,
            projectionMatrix: projectionMatrix,
            viewMatrix: viewMatrix
        )
    }
}
