import SwiftUI

/// Consistent spacing values for the AI4Science app
public struct Spacing {
    // MARK: - Base Spacing Scale
    public static let none: CGFloat = 0
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let base: CGFloat = 16
    public static let lg: CGFloat = 20
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 28
    public static let xxxl: CGFloat = 32

    // MARK: - Larger Spacing
    public static let huge: CGFloat = 40
    public static let massive: CGFloat = 48
    public static let gigantic: CGFloat = 56
    public static let titanium: CGFloat = 64

    // MARK: - Component-Specific Spacing
    public static let buttonPadding = (horizontal: base, vertical: sm)
    public static let cardPadding = base
    public static let screenPadding = base
    public static let listItemPadding = (horizontal: base, vertical: md)

    // MARK: - Gap/Divider Spacing
    public static let gapSmall = xs
    public static let gapMedium = sm
    public static let gapLarge = md
    public static let gapXLarge = lg

    // MARK: - Corner Radius Spacing (used for shadows, borders)
    public static let radiusSmall: CGFloat = 4
    public static let radiusMedium: CGFloat = 8
    public static let radiusLarge: CGFloat = 12
    public static let radiusXLarge: CGFloat = 16
    public static let radiusCircle: CGFloat = 999

    // MARK: - Icon Sizing
    public static let iconSmall: CGFloat = 16
    public static let iconMedium: CGFloat = 24
    public static let iconLarge: CGFloat = 32
    public static let iconXLarge: CGFloat = 48
}

// MARK: - Padding Modifiers
extension View {
    /// Apply symmetric padding
    @ViewBuilder
    public func paddingSymmetric(
        horizontal: CGFloat? = nil,
        vertical: CGFloat? = nil
    ) -> some View {
        switch (horizontal, vertical) {
        case let (h?, v?):
            self.padding(.horizontal, h).padding(.vertical, v)
        case let (h?, nil):
            self.padding(.horizontal, h)
        case let (nil, v?):
            self.padding(.vertical, v)
        case (nil, nil):
            self
        }
    }

    /// Apply padding to specific edges
    public func paddingEdges(
        _ edges: Edge.Set = .all,
        value: CGFloat
    ) -> some View {
        padding(edges, value)
    }

    /// Apply standard screen padding
    public func screenPadding() -> some View {
        padding(Spacing.screenPadding)
    }

    /// Apply standard card padding
    public func cardPadding() -> some View {
        padding(Spacing.cardPadding)
    }

    /// Apply standard button padding
    public func buttonPadding() -> some View {
        padding(.horizontal, Spacing.buttonPadding.horizontal)
            .padding(.vertical, Spacing.buttonPadding.vertical)
    }

    /// Apply standard list item padding
    public func listItemPadding() -> some View {
        padding(.horizontal, Spacing.listItemPadding.horizontal)
            .padding(.vertical, Spacing.listItemPadding.vertical)
    }
}

// MARK: - Frame Modifiers
extension View {
    /// Create a square frame
    public func squareFrame(_ size: CGFloat) -> some View {
        frame(width: size, height: size)
    }

    /// Create a frame with aspect ratio
    public func aspectFrame(_ ratio: CGFloat, width: CGFloat) -> some View {
        frame(width: width, height: width / ratio)
    }
}

// MARK: - Spacing Structs for Common Patterns
public struct Insets {
    public static let none = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    public static let small = NSDirectionalEdgeInsets(
        top: Spacing.sm,
        leading: Spacing.sm,
        bottom: Spacing.sm,
        trailing: Spacing.sm
    )
    public static let medium = NSDirectionalEdgeInsets(
        top: Spacing.base,
        leading: Spacing.base,
        bottom: Spacing.base,
        trailing: Spacing.base
    )
    public static let large = NSDirectionalEdgeInsets(
        top: Spacing.lg,
        leading: Spacing.lg,
        bottom: Spacing.lg,
        trailing: Spacing.lg
    )
}
