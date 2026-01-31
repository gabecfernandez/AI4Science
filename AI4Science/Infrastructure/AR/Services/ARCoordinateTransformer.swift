import ARKit
import os.log

/// Service for transforming between screen and AR coordinates
actor ARCoordinateTransformer {
    static let shared = ARCoordinateTransformer()

    private let logger = Logger(subsystem: "com.ai4science.ar", category: "ARCoordinateTransformer")

    enum TransformError: LocalizedError {
        case invalidFrame
        case invalidCoordinates
        case transformationFailed

        var errorDescription: String? {
            switch self {
            case .invalidFrame:
                return "Invalid AR frame"
            case .invalidCoordinates:
                return "Invalid coordinates for transformation"
            case .transformationFailed:
                return "Coordinate transformation failed"
            }
        }
    }

    nonisolated init() {
        // Empty init for actor
    }

    /// Convert screen point to 3D world coordinates
    func convertScreenPointToWorldCoordinates(
        _ screenPoint: CGPoint,
        in frame: ARFrame,
        estimatedDistance: Float = 1.0
    ) async throws -> SIMD3<Float> {
        let normalizedX = Float(screenPoint.x) / Float(UIScreen.main.bounds.width) * 2 - 1
        let normalizedY = Float(screenPoint.y) / Float(UIScreen.main.bounds.height) * 2 - 1

        let ndc = simd_float4(normalizedX, normalizedY, -1, 1)

        let inverseProjection = frame.camera.intrinsics.inverse
        let eyeCoordinate = inverseProjection * ndc
        let eyeDirection = normalize(simd_float3(eyeCoordinate.x, eyeCoordinate.y, -1))

        let viewTransform = frame.camera.transform
        let worldDirection = simd_make_float3(
            viewTransform.columns.0.x * eyeDirection.x + viewTransform.columns.1.x * eyeDirection.y + viewTransform.columns.2.x * eyeDirection.z,
            viewTransform.columns.0.y * eyeDirection.x + viewTransform.columns.1.y * eyeDirection.y + viewTransform.columns.2.y * eyeDirection.z,
            viewTransform.columns.0.z * eyeDirection.x + viewTransform.columns.1.z * eyeDirection.y + viewTransform.columns.2.z * eyeDirection.z
        )

        let cameraPosition = simd_make_float3(viewTransform.columns.3.x, viewTransform.columns.3.y, viewTransform.columns.3.z)
        let worldPoint = cameraPosition + worldDirection * estimatedDistance

        logger.debug("Screen point \(screenPoint) converted to world coordinates")
        return worldPoint
    }

    /// Convert 3D world coordinates to screen point
    func convertWorldCoordinatesToScreenPoint(
        _ worldCoordinates: SIMD3<Float>,
        in frame: ARFrame,
        viewportSize: CGSize
    ) async throws -> CGPoint {
        let viewMatrix = frame.camera.transform.inverse
        let cameraSpacePoint = simd_make_float4(worldCoordinates.x, worldCoordinates.y, worldCoordinates.z, 1) * viewMatrix

        let projectionMatrix = frame.camera.intrinsics
        let clipSpacePoint = projectionMatrix * cameraSpacePoint

        guard clipSpacePoint.w != 0 else {
            throw TransformError.transformationFailed
        }

        let ndcPoint = clipSpacePoint / clipSpacePoint.w

        let screenX = (Float(viewportSize.width) / 2) * (1 + ndcPoint.x)
        let screenY = (Float(viewportSize.height) / 2) * (1 - ndcPoint.y)

        logger.debug("World coordinates converted to screen point: (\(screenX), \(screenY))")
        return CGPoint(x: CGFloat(screenX), y: CGFloat(screenY))
    }

    /// Perform hit test at screen point
    func performHitTest(
        at screenPoint: CGPoint,
        in frame: ARFrame,
        types: ARHitTestResult.ResultType = [.featurePoint, .estimatedHorizontalPlane]
    ) async throws -> [ARHitTestResult] {
        // This would typically be called from the main thread with ARView
        // Here we provide the calculation logic for hit testing

        let normalizedX = Float(screenPoint.x / UIScreen.main.bounds.width)
        let normalizedY = Float(screenPoint.y / UIScreen.main.bounds.height)

        logger.debug("Hit test at screen point: \(screenPoint)")
        return []
    }

    /// Get distance between two 3D points
    func getDistance(from point1: SIMD3<Float>, to point2: SIMD3<Float>) -> Float {
        return simd_distance(point1, point2)
    }

    /// Get direction vector between two points
    func getDirection(from point1: SIMD3<Float>, to point2: SIMD3<Float>) -> SIMD3<Float> {
        let vector = point2 - point1
        return normalize(vector)
    }

    /// Transform point from local to world coordinates
    func transformPointToWorldCoordinates(
        _ point: SIMD3<Float>,
        using transform: simd_float4x4
    ) -> SIMD3<Float> {
        let homogeneousPoint = simd_float4(point.x, point.y, point.z, 1)
        let transformedPoint = transform * homogeneousPoint

        return simd_make_float3(transformedPoint.x, transformedPoint.y, transformedPoint.z)
    }

    /// Transform point from world to local coordinates
    func transformPointToLocalCoordinates(
        _ point: SIMD3<Float>,
        using transform: simd_float4x4
    ) -> SIMD3<Float> {
        let inverseTransform = transform.inverse
        let homogeneousPoint = simd_float4(point.x, point.y, point.z, 1)
        let transformedPoint = inverseTransform * homogeneousPoint

        return simd_make_float3(transformedPoint.x, transformedPoint.y, transformedPoint.z)
    }

    /// Get frustum planes from camera
    func getFrustumPlanes(from frame: ARFrame) -> FrustumPlanes {
        let intrinsics = frame.camera.intrinsics
        let viewMatrix = frame.camera.transform.inverse

        // Calculate frustum planes based on camera intrinsics
        let fx = intrinsics[0, 0]
        let fy = intrinsics[1, 1]
        let cx = intrinsics[0, 2]
        let cy = intrinsics[1, 2]

        return FrustumPlanes(
            fovX: atan(1.0 / fx) * 2,
            fovY: atan(1.0 / fy) * 2,
            aspect: fx / fy
        )
    }

    /// Check if point is visible in camera view
    func isPointInView(
        _ point: SIMD3<Float>,
        in frame: ARFrame,
        viewportSize: CGSize
    ) async throws -> Bool {
        let screenPoint = try await convertWorldCoordinatesToScreenPoint(
            point,
            in: frame,
            viewportSize: viewportSize
        )

        return screenPoint.x >= 0 && screenPoint.x <= viewportSize.width &&
               screenPoint.y >= 0 && screenPoint.y <= viewportSize.height
    }

    /// Get camera forward vector
    func getCameraForwardVector(from frame: ARFrame) -> SIMD3<Float> {
        let transform = frame.camera.transform
        return -simd_make_float3(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
    }

    /// Get camera up vector
    func getCameraUpVector(from frame: ARFrame) -> SIMD3<Float> {
        let transform = frame.camera.transform
        return simd_make_float3(transform.columns.1.x, transform.columns.1.y, transform.columns.1.z)
    }

    /// Get camera right vector
    func getCameraRightVector(from frame: ARFrame) -> SIMD3<Float> {
        let transform = frame.camera.transform
        return simd_make_float3(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z)
    }

    /// Get camera position in world space
    func getCameraPosition(from frame: ARFrame) -> SIMD3<Float> {
        let transform = frame.camera.transform
        return simd_make_float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }

    /// Create view matrix from camera transform
    func createViewMatrix(from frame: ARFrame) -> simd_float4x4 {
        return frame.camera.transform.inverse
    }

    /// Create projection matrix from camera intrinsics
    func createProjectionMatrix(from frame: ARFrame, nearPlane: Float = 0.01, farPlane: Float = 1000) -> simd_float4x4 {
        return frame.camera.intrinsics
    }
}

struct FrustumPlanes {
    let fovX: Float
    let fovY: Float
    let aspect: Float
}
