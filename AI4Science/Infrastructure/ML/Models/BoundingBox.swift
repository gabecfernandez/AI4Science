import Foundation
import CoreGraphics

/// Normalized bounding box representation
/// Coordinates are normalized to 0-1 range relative to image dimensions
public struct BoundingBox: Codable, Sendable, Equatable {
    /// X coordinate (0-1, normalized)
    public let x: Float

    /// Y coordinate (0-1, normalized)
    public let y: Float

    /// Width (0-1, normalized)
    public let width: Float

    /// Height (0-1, normalized)
    public let height: Float

    // MARK: - Initialization

    public nonisolated init(x: Float, y: Float, width: Float, height: Float) {
        self.x = max(0, min(1, x))
        self.y = max(0, min(1, y))
        self.width = max(0, min(1 - x, width))
        self.height = max(0, min(1 - y, height))
    }

    // MARK: - Computed Properties

    /// Right edge coordinate (x + width)
    var right: Float {
        x + width
    }

    /// Bottom edge coordinate (y + height)
    var bottom: Float {
        y + height
    }

    /// Center X coordinate
    var centerX: Float {
        x + width / 2
    }

    /// Center Y coordinate
    var centerY: Float {
        y + height / 2
    }

    /// Area of bounding box
    var area: Float {
        width * height
    }

    /// Aspect ratio (width / height)
    var aspectRatio: Float {
        guard height > 0 else { return 0 }
        return width / height
    }

    // MARK: - Coordinate Conversion

    /// Convert to pixel coordinates
    /// - Parameter imageSize: Size of the image in pixels
    /// - Returns: BoundingBox with pixel coordinates
    func toPixelCoordinates(imageSize: CGSize) -> CGRect {
        let pixelX = x * Float(imageSize.width)
        let pixelY = y * Float(imageSize.height)
        let pixelWidth = width * Float(imageSize.width)
        let pixelHeight = height * Float(imageSize.height)

        return CGRect(x: CGFloat(pixelX), y: CGFloat(pixelY), width: CGFloat(pixelWidth), height: CGFloat(pixelHeight))
    }

    /// Create from pixel coordinates
    /// - Parameters:
    ///   - rect: CGRect in pixel coordinates
    ///   - imageSize: Size of the image in pixels
    /// - Returns: Normalized BoundingBox
    static func fromPixelCoordinates(
        _ rect: CGRect,
        imageSize: CGSize
    ) -> BoundingBox {
        guard imageSize.width > 0 && imageSize.height > 0 else {
            return BoundingBox(x: 0, y: 0, width: 0, height: 0)
        }

        let x = Float(rect.minX / imageSize.width)
        let y = Float(rect.minY / imageSize.height)
        let width = Float(rect.width / imageSize.width)
        let height = Float(rect.height / imageSize.height)

        return BoundingBox(x: x, y: y, width: width, height: height)
    }

    // MARK: - Operations

    /// Calculate Intersection over Union with another box
    /// - Parameter other: Other bounding box
    /// - Returns: IoU value (0-1)
    func intersectionOverUnion(with other: BoundingBox) -> Float {
        let intersectionX = max(x, other.x)
        let intersectionY = max(y, other.y)
        let intersectionRight = min(right, other.right)
        let intersectionBottom = min(bottom, other.bottom)

        guard intersectionRight > intersectionX && intersectionBottom > intersectionY else {
            return 0
        }

        let intersectionWidth = intersectionRight - intersectionX
        let intersectionHeight = intersectionBottom - intersectionY
        let intersectionArea = intersectionWidth * intersectionHeight

        let unionArea = area + other.area - intersectionArea

        guard unionArea > 0 else { return 0 }

        return intersectionArea / unionArea
    }

    /// Check if this box contains another box
    /// - Parameter other: Other bounding box
    /// - Returns: true if other is fully contained
    func contains(_ other: BoundingBox) -> Bool {
        return other.x >= x &&
               other.y >= y &&
               other.right <= right &&
               other.bottom <= bottom
    }

    /// Check if this box intersects with another box
    /// - Parameter other: Other bounding box
    /// - Returns: true if boxes overlap
    func intersects(with other: BoundingBox) -> Bool {
        return !(right < other.x || other.right < x ||
                 bottom < other.y || other.bottom < y)
    }

    /// Calculate distance to another box center
    /// - Parameter other: Other bounding box
    /// - Returns: Euclidean distance between centers
    func distanceToCenter(of other: BoundingBox) -> Float {
        let dx = centerX - other.centerX
        let dy = centerY - other.centerY
        return sqrt(dx * dx + dy * dy)
    }

    /// Expand box by a relative factor
    /// - Parameter factor: Expansion factor (1.0 = no change, 1.1 = 10% expansion)
    /// - Returns: Expanded BoundingBox
    func expanded(by factor: Float) -> BoundingBox {
        let widthDelta = (width * factor - width) / 2
        let heightDelta = (height * factor - height) / 2

        let newX = max(0, x - widthDelta)
        let newY = max(0, y - heightDelta)
        let newWidth = width * factor
        let newHeight = height * factor

        return BoundingBox(x: newX, y: newY, width: newWidth, height: newHeight)
    }

    /// Shrink box by a relative factor
    /// - Parameter factor: Shrink factor (0.0 = point, 1.0 = no change)
    /// - Returns: Shrunk BoundingBox
    func shrunk(by factor: Float) -> BoundingBox {
        let scaledWidth = width * factor
        let scaledHeight = height * factor
        let deltaX = (width - scaledWidth) / 2
        let deltaY = (height - scaledHeight) / 2

        return BoundingBox(
            x: x + deltaX,
            y: y + deltaY,
            width: scaledWidth,
            height: scaledHeight
        )
    }

    /// Translate box by offset
    /// - Parameters:
    ///   - dx: X offset
    ///   - dy: Y offset
    /// - Returns: Translated BoundingBox
    func translated(by dx: Float, dy: Float) -> BoundingBox {
        return BoundingBox(
            x: x + dx,
            y: y + dy,
            width: width,
            height: height
        )
    }

    /// Clip box to image boundaries
    /// - Returns: Clipped BoundingBox
    func clipped() -> BoundingBox {
        return BoundingBox(
            x: max(0, min(1, x)),
            y: max(0, min(1, y)),
            width: min(1 - x, width),
            height: min(1 - y, height)
        )
    }

    /// Rotate box coordinates (90 degree rotations)
    /// - Parameter degrees: Rotation angle (90, 180, 270)
    /// - Returns: Rotated BoundingBox
    func rotated(by degrees: Int) -> BoundingBox {
        let normalizedDegrees = ((degrees % 360) + 360) % 360

        switch normalizedDegrees {
        case 90:
            // (x, y) -> (1-y-h, x)
            return BoundingBox(x: 1 - y - height, y: x, width: height, height: width)
        case 180:
            // (x, y) -> (1-x-w, 1-y-h)
            return BoundingBox(x: 1 - x - width, y: 1 - y - height, width: width, height: height)
        case 270:
            // (x, y) -> (y, 1-x-w)
            return BoundingBox(x: y, y: 1 - x - width, width: height, height: width)
        default:
            return self
        }
    }

    // MARK: - Comparison

    /// Check equality
    public static func == (lhs: BoundingBox, rhs: BoundingBox) -> Bool {
        return abs(lhs.x - rhs.x) < 0.001 &&
               abs(lhs.y - rhs.y) < 0.001 &&
               abs(lhs.width - rhs.width) < 0.001 &&
               abs(lhs.height - rhs.height) < 0.001
    }

    // MARK: - Description

    /// Human-readable string representation
    var description: String {
        return String(format: "BoundingBox(x: %.3f, y: %.3f, w: %.3f, h: %.3f)", x, y, width, height)
    }

    /// CGRect representation (normalized coordinates)
    var cgRect: CGRect {
        return CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height))
    }
}

// MARK: - Collection of Bounding Boxes

/// Group of bounding boxes for batch processing
struct BoundingBoxGroup: Sendable {
    let boxes: [BoundingBox]
    let timestamp: Date

    /// Filter boxes by area size
    /// - Parameters:
    ///   - minArea: Minimum box area
    ///   - maxArea: Maximum box area
    /// - Returns: Filtered boxes
    func filterByArea(minArea: Float = 0.001, maxArea: Float = 1.0) -> [BoundingBox] {
        boxes.filter { $0.area >= minArea && $0.area <= maxArea }
    }

    /// Filter boxes by aspect ratio
    /// - Parameters:
    ///   - minRatio: Minimum aspect ratio
    ///   - maxRatio: Maximum aspect ratio
    /// - Returns: Filtered boxes
    func filterByAspectRatio(minRatio: Float = 0.1, maxRatio: Float = 10.0) -> [BoundingBox] {
        boxes.filter { $0.aspectRatio >= minRatio && $0.aspectRatio <= maxRatio }
    }

    /// Remove duplicate/overlapping boxes
    /// - Parameter threshold: IoU threshold for considering boxes as duplicates
    /// - Returns: Non-overlapping boxes
    func removeDuplicates(threshold: Float = 0.5) -> [BoundingBox] {
        var result: [BoundingBox] = []

        for box in boxes {
            let isDuplicate = result.contains { $0.intersectionOverUnion(with: box) > threshold }
            if !isDuplicate {
                result.append(box)
            }
        }

        return result
    }
}
