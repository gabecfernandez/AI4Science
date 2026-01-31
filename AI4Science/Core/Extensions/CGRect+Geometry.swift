import UIKit

extension CGRect {
    /// Create rectangle from center and size
    public init(center: CGPoint, size: CGSize) {
        self.init(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    /// Get center point
    public var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    /// Get scaled rect
    public func scaled(by scale: CGFloat) -> CGRect {
        let newSize = CGSize(width: width * scale, height: height * scale)
        return CGRect(center: center, size: newSize)
    }

    /// Get inset rect
    public func insetBy(x: CGFloat, y: CGFloat) -> CGRect {
        insetBy(dx: x, dy: y)
    }

    /// Check if rect contains point
    public func containsPoint(_ point: CGPoint) -> Bool {
        contains(point)
    }

    /// Get intersection with another rect
    public func intersection(with other: CGRect) -> CGRect? {
        let intersection = intersection(other)
        return intersection.isEmpty ? nil : intersection
    }

    /// Check if rect intersects with another
    public func intersects(with other: CGRect) -> Bool {
        intersects(other)
    }

    /// Normalize rect to 0...1 range
    public func normalized(in bounds: CGRect) -> CGRect {
        CGRect(
            x: origin.x / bounds.width,
            y: origin.y / bounds.height,
            width: width / bounds.width,
            height: height / bounds.height
        )
    }

    /// Denormalize rect from 0...1 range
    public func denormalized(in bounds: CGRect) -> CGRect {
        CGRect(
            x: origin.x * bounds.width,
            y: origin.y * bounds.height,
            width: width * bounds.width,
            height: height * bounds.height
        )
    }

    /// Get aspect ratio
    public var aspectRatio: CGFloat {
        guard height > 0 else { return 0 }
        return width / height
    }

    /// Get area
    public var area: CGFloat {
        width * height
    }

    /// Fit rect inside bounds maintaining aspect ratio
    public func fitInside(_ bounds: CGRect) -> CGRect {
        let boundAspect = bounds.width / bounds.height
        let selfAspect = aspectRatio

        let size: CGSize
        if selfAspect > boundAspect {
            size = CGSize(width: bounds.width, height: bounds.width / selfAspect)
        } else {
            size = CGSize(width: bounds.height * selfAspect, height: bounds.height)
        }

        return CGRect(center: bounds.center, size: size)
    }

    /// Round corners
    public func roundedCorners(radius: CGFloat) -> UIBezierPath {
        UIBezierPath(roundedRect: self, cornerRadius: radius)
    }

    /// Create path with rounded corners
    public func roundedPath(radius: CGFloat) -> UIBezierPath {
        UIBezierPath(roundedRect: self, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: radius, height: radius))
    }
}

extension CGPoint {
    /// Get distance to another point
    public func distance(to point: CGPoint) -> CGFloat {
        let dx = self.x - point.x
        let dy = self.y - point.y
        return sqrt(dx * dx + dy * dy)
    }

    /// Get angle to another point (in radians)
    public func angle(to point: CGPoint) -> CGFloat {
        atan2(point.y - y, point.x - x)
    }

    /// Move point by offset
    public func offset(by offset: CGSize) -> CGPoint {
        CGPoint(x: x + offset.width, y: y + offset.height)
    }

    /// Scale point
    public func scaled(by scale: CGFloat) -> CGPoint {
        CGPoint(x: x * scale, y: y * scale)
    }

    /// Normalize point to 0...1 range
    public func normalized(in bounds: CGRect) -> CGPoint {
        CGPoint(
            x: (x - bounds.minX) / bounds.width,
            y: (y - bounds.minY) / bounds.height
        )
    }

    /// Denormalize point from 0...1 range
    public func denormalized(in bounds: CGRect) -> CGPoint {
        CGPoint(
            x: bounds.minX + (x * bounds.width),
            y: bounds.minY + (y * bounds.height)
        )
    }
}

extension CGSize {
    /// Scale size
    public func scaled(by scale: CGFloat) -> CGSize {
        CGSize(width: width * scale, height: height * scale)
    }

    /// Fit size inside bounds maintaining aspect ratio
    public func fitInside(_ bounds: CGSize) -> CGSize {
        let boundAspect = bounds.width / bounds.height
        let selfAspect = width / height

        if selfAspect > boundAspect {
            return CGSize(width: bounds.width, height: bounds.width / selfAspect)
        } else {
            return CGSize(width: bounds.height * selfAspect, height: bounds.height)
        }
    }

    /// Get aspect ratio
    public var aspectRatio: CGFloat {
        guard height > 0 else { return 0 }
        return width / height
    }

    /// Get area
    public var area: CGFloat {
        width * height
    }
}
