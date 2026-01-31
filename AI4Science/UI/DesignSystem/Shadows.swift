import SwiftUI

/// Shadow styles for the AI4Science app
public struct Shadows {
    // MARK: - Shadow Properties
    public struct ShadowConfig {
        public let color: Color
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat
        public let opacity: Double

        public init(
            color: Color = .black,
            radius: CGFloat,
            x: CGFloat = 0,
            y: CGFloat = 0,
            opacity: Double = 0.1
        ) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
            self.opacity = opacity
        }
    }

    // MARK: - Standard Shadows
    public static let none = ShadowConfig(radius: 0, opacity: 0)

    public static let small = ShadowConfig(
        radius: 4,
        x: 0,
        y: 2,
        opacity: 0.08
    )

    public static let medium = ShadowConfig(
        radius: 8,
        x: 0,
        y: 4,
        opacity: 0.12
    )

    public static let large = ShadowConfig(
        radius: 12,
        x: 0,
        y: 8,
        opacity: 0.16
    )

    public static let extraLarge = ShadowConfig(
        radius: 16,
        x: 0,
        y: 12,
        opacity: 0.20
    )

    // MARK: - Elevation Shadows (Material Design inspired)
    public static let elevation1 = ShadowConfig(
        radius: 1,
        x: 0,
        y: 1,
        opacity: 0.12
    )

    public static let elevation2 = ShadowConfig(
        radius: 3,
        x: 0,
        y: 3,
        opacity: 0.16
    )

    public static let elevation3 = ShadowConfig(
        radius: 6,
        x: 0,
        y: 6,
        opacity: 0.12
    )

    public static let elevation4 = ShadowConfig(
        radius: 8,
        x: 0,
        y: 8,
        opacity: 0.15
    )

    public static let elevation5 = ShadowConfig(
        radius: 12,
        x: 0,
        y: 12,
        opacity: 0.20
    )

    // MARK: - Soft Shadows
    public static let softSmall = ShadowConfig(
        radius: 2,
        x: 0,
        y: 1,
        opacity: 0.05
    )

    public static let softMedium = ShadowConfig(
        radius: 4,
        x: 0,
        y: 2,
        opacity: 0.08
    )

    public static let softLarge = ShadowConfig(
        radius: 8,
        x: 0,
        y: 4,
        opacity: 0.12
    )

    // MARK: - Color-Based Shadows
    public static func coloredShadow(
        color: Color,
        radius: CGFloat = 8,
        opacity: Double = 0.2
    ) -> ShadowConfig {
        ShadowConfig(
            color: color,
            radius: radius,
            x: 0,
            y: 4,
            opacity: opacity
        )
    }
}

// MARK: - Shadow Modifier
public struct ShadowModifier: ViewModifier {
    let shadow: Shadows.ShadowConfig

    public func body(content: Content) -> some View {
        content
            .shadow(
                color: shadow.color.opacity(shadow.opacity),
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

// MARK: - Shadow Modifiers Extension
extension View {
    /// Apply a shadow to the view
    public func shadow(_ shadow: Shadows.ShadowConfig) -> some View {
        modifier(ShadowModifier(shadow: shadow))
    }

    /// Apply a small shadow
    public func shadowSmall() -> some View {
        shadow(Shadows.small)
    }

    /// Apply a medium shadow
    public func shadowMedium() -> some View {
        shadow(Shadows.medium)
    }

    /// Apply a large shadow
    public func shadowLarge() -> some View {
        shadow(Shadows.large)
    }

    /// Apply elevation shadow
    public func shadowElevation(_ level: Int) -> some View {
        switch level {
        case 1: return AnyView(shadow(Shadows.elevation1))
        case 2: return AnyView(shadow(Shadows.elevation2))
        case 3: return AnyView(shadow(Shadows.elevation3))
        case 4: return AnyView(shadow(Shadows.elevation4))
        case 5: return AnyView(shadow(Shadows.elevation5))
        default: return AnyView(shadow(Shadows.none))
        }
    }
}
