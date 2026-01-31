import Foundation

public extension CGRect {
    /// Create CGRect from normalized coordinates (0.0 to 1.0)
    init(normalizedX: CGFloat, normalizedY: CGFloat, normalizedWidth: CGFloat, normalizedHeight: CGFloat) {
        self.init(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
    }

    /// Denormalize rectangle to actual size
    func denormalized(to size: CGSize) -> CGRect {
        CGRect(
            x: origin.x * size.width,
            y: origin.y * size.height,
            width: width * size.width,
            height: height * size.height
        )
    }

    /// Normalize rectangle to 0.0-1.0 range
    func normalized(to size: CGSize) -> CGRect {
        guard size.width > 0, size.height > 0 else { return .zero }
        return CGRect(
            x: origin.x / size.width,
            y: origin.y / size.height,
            width: width / size.width,
            height: height / size.height
        )
    }

    /// Get center point
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    /// Get area
    var area: CGFloat {
        width * height
    }

    /// Get aspect ratio
    var aspectRatio: CGFloat {
        guard height > 0 else { return 1 }
        return width / height
    }

    /// Expand rectangle by insets
    func expanded(by insets: UIEdgeInsets) -> CGRect {
        CGRect(
            x: origin.x - insets.left,
            y: origin.y - insets.top,
            width: width + insets.left + insets.right,
            height: height + insets.top + insets.bottom
        )
    }

    /// Inset rectangle
    func insetted(by insets: UIEdgeInsets) -> CGRect {
        CGRect(
            x: origin.x + insets.left,
            y: origin.y + insets.top,
            width: width - insets.left - insets.right,
            height: height - insets.top - insets.bottom
        )
    }

    /// Scale rectangle
    func scaled(by factor: CGFloat) -> CGRect {
        CGRect(
            x: origin.x * factor,
            y: origin.y * factor,
            width: width * factor,
            height: height * factor
        )
    }

    /// Scale rectangle from center
    func scaledFromCenter(by factor: CGFloat) -> CGRect {
        let newWidth = width * factor
        let newHeight = height * factor
        let newX = midX - newWidth / 2
        let newY = midY - newHeight / 2
        return CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
    }

    /// Offset rectangle
    func offsetted(by offset: CGPoint) -> CGRect {
        CGRect(
            x: origin.x + offset.x,
            y: origin.y + offset.y,
            width: width,
            height: height
        )
    }

    /// Offset rectangle by dx, dy
    func offsetted(dx: CGFloat, dy: CGFloat) -> CGRect {
        offsetted(by: CGPoint(x: dx, y: dy))
    }

    /// Check if rectangle is valid
    var isValid: Bool {
        !isNull && !isInfinite && width > 0 && height > 0
    }

    /// Clamp rectangle to bounds
    func clamped(to bounds: CGRect) -> CGRect {
        let clampedOrigin = CGPoint(
            x: max(min(origin.x, bounds.maxX - width), bounds.minX),
            y: max(min(origin.y, bounds.maxY - height), bounds.minY)
        )
        return CGRect(origin: clampedOrigin, size: size)
    }

    /// Fit rectangle inside bounds
    func fit(in bounds: CGRect) -> CGRect {
        let scale = min(bounds.width / width, bounds.height / height)
        let newSize = CGSize(width: width * scale, height: height * scale)
        let newOrigin = CGPoint(
            x: bounds.midX - newSize.width / 2,
            y: bounds.midY - newSize.height / 2
        )
        return CGRect(origin: newOrigin, size: newSize)
    }

    /// Aspect ratio fill
    func aspectFill(in bounds: CGRect) -> CGRect {
        let scale = max(bounds.width / width, bounds.height / height)
        let newSize = CGSize(width: width * scale, height: height * scale)
        let newOrigin = CGPoint(
            x: bounds.midX - newSize.width / 2,
            y: bounds.midY - newSize.height / 2
        )
        return CGRect(origin: newOrigin, size: newSize)
    }

    /// Get intersection with another rectangle
    func intersection(with other: CGRect) -> CGRect? {
        let intersection = self.intersection(other)
        return intersection.isNull ? nil : intersection
    }

    /// Check if rectangle contains another rectangle
    func contains(_ rect: CGRect) -> Bool {
        contains(rect.origin) && contains(CGPoint(x: rect.maxX, y: rect.maxY))
    }

    /// Create rectangle with aspect ratio
    static func aspectRatioRect(in bounds: CGRect, aspectRatio: CGFloat) -> CGRect {
        let scale = min(bounds.width, bounds.height / aspectRatio)
        let size = CGSize(width: scale, height: scale / aspectRatio)
        return CGRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}

public extension CGSize {
    /// Get area
    var area: CGFloat {
        width * height
    }

    /// Get aspect ratio
    var aspectRatio: CGFloat {
        guard height > 0 else { return 1 }
        return width / height
    }

    /// Scale size
    func scaled(by factor: CGFloat) -> CGSize {
        CGSize(width: width * factor, height: height * factor)
    }

    /// Check if size is valid
    var isValid: Bool {
        width > 0 && height > 0
    }

    /// Fit size to bounds
    func fit(in bounds: CGSize) -> CGSize {
        let scale = min(bounds.width / width, bounds.height / height)
        return CGSize(width: width * scale, height: height * scale)
    }
}

public extension CGPoint {
    /// Calculate distance to another point
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }

    /// Get midpoint between two points
    func midpoint(to point: CGPoint) -> CGPoint {
        CGPoint(x: (x + point.x) / 2, y: (y + point.y) / 2)
    }

    /// Offset point
    func offset(by offset: CGPoint) -> CGPoint {
        CGPoint(x: x + offset.x, y: y + offset.y)
    }

    /// Scale point
    func scaled(by factor: CGFloat) -> CGPoint {
        CGPoint(x: x * factor, y: y * factor)
    }
}
