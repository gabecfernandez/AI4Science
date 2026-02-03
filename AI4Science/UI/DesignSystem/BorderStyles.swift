import SwiftUI

/// Border styles and corner radius configurations for the AI4Science app
public struct BorderStyles {
    // MARK: - Corner Radius Presets
    public static let radiusNone: CGFloat = 0
    public static let radiusSmall: CGFloat = 4
    public static let radiusMedium: CGFloat = 8
    public static let radiusLarge: CGFloat = 12
    public static let radiusXLarge: CGFloat = 16
    public static let radiusXXLarge: CGFloat = 20
    public static let radiusCircle: CGFloat = 999

    // MARK: - Border Width Presets
    public static let borderNone: CGFloat = 0
    public static let borderThin: CGFloat = 0.5
    public static let borderLight: CGFloat = 1
    public static let borderMedium: CGFloat = 2
    public static let borderHeavy: CGFloat = 3

    // MARK: - Border Configurations
    public struct BorderConfig {
        public let width: CGFloat
        public let color: Color
        public let cornerRadius: CGFloat

        public init(
            width: CGFloat = borderLight,
            color: Color = ColorPalette.divider,
            cornerRadius: CGFloat = radiusMedium
        ) {
            self.width = width
            self.color = color
            self.cornerRadius = cornerRadius
        }
    }

    // MARK: - Standard Border Configs
    public static let standard = BorderConfig()

    public static let subtle = BorderConfig(
        width: borderThin,
        color: ColorPalette.divider.opacity(0.5),
        cornerRadius: radiusMedium
    )

    public static let prominent = BorderConfig(
        width: borderMedium,
        color: ColorPalette.divider,
        cornerRadius: radiusMedium
    )

    public static let accentBorder = BorderConfig(
        width: borderLight,
        color: ColorPalette.utsa_primary,
        cornerRadius: radiusMedium
    )

    public static let warningBorder = BorderConfig(
        width: borderLight,
        color: ColorPalette.warning,
        cornerRadius: radiusMedium
    )

    public static let errorBorder = BorderConfig(
        width: borderLight,
        color: ColorPalette.error,
        cornerRadius: radiusMedium
    )

    public static let successBorder = BorderConfig(
        width: borderLight,
        color: ColorPalette.success,
        cornerRadius: radiusMedium
    )
}

// MARK: - RoundedRectangle Builders
public struct RoundedCorners {
    public enum Style {
        case none
        case small
        case medium
        case large
        case xLarge
        case xxLarge
        case circle
        case custom(CGFloat)

        public var radius: CGFloat {
            switch self {
            case .none: return BorderStyles.radiusNone
            case .small: return BorderStyles.radiusSmall
            case .medium: return BorderStyles.radiusMedium
            case .large: return BorderStyles.radiusLarge
            case .xLarge: return BorderStyles.radiusXLarge
            case .xxLarge: return BorderStyles.radiusXXLarge
            case .circle: return BorderStyles.radiusCircle
            case .custom(let value): return value
            }
        }
    }

    /// Create rounded corners for specific edges only
    public static func partial(
        _ edges: [Edge],
        radius: CGFloat
    ) -> some Shape {
        RoundedRectangle(cornerRadius: radius)
    }
}

// MARK: - Border Modifiers
public struct BorderModifier: ViewModifier {
    let config: BorderStyles.BorderConfig

    public func body(content: Content) -> some View {
        content
            .cornerRadius(config.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .stroke(config.color, lineWidth: config.width)
            )
    }
}

extension View {
    /// Apply a border with configuration
    public func border(_ config: BorderStyles.BorderConfig) -> some View {
        modifier(BorderModifier(config: config))
    }

    /// Apply standard border
    public func borderStandard() -> some View {
        border(BorderStyles.standard)
    }

    /// Apply subtle border
    public func borderSubtle() -> some View {
        border(BorderStyles.subtle)
    }

    /// Apply prominent border
    public func borderProminent() -> some View {
        border(BorderStyles.prominent)
    }

    /// Apply accent border
    public func borderAccent() -> some View {
        border(BorderStyles.accentBorder)
    }

    /// Apply corner radius
    public func cornerRadius(_ style: RoundedCorners.Style) -> some View {
        cornerRadius(style.radius)
    }

    /// Apply specific corner radius to edges
    public func customCornerRadius(
        _ radius: CGFloat,
        corners: UIRectCorner = .allCorners
    ) -> some View {
        clipShape(
            RoundedRectangle(
                cornerRadius: radius,
                style: .continuous
            )
        )
    }
}

// Note: Shape already provides fill() and stroke() methods via SwiftUI

// MARK: - Divider Styles
public struct DividerStyle {
    public enum Style {
        case horizontal
        case vertical
        case dashed
        case dotted
    }

    public let width: CGFloat
    public let color: Color
    public let style: Style

    public init(
        width: CGFloat = 1,
        color: Color = ColorPalette.divider,
        style: Style = .horizontal
    ) {
        self.width = width
        self.color = color
        self.style = style
    }
}

public struct CustomDivider: View {
    let style: DividerStyle

    public init(_ dividerStyle: DividerStyle = DividerStyle()) {
        self.style = dividerStyle
    }

    public var body: some View {
        switch style.style {
        case .horizontal:
            style.color
                .frame(height: style.width)

        case .vertical:
            style.color
                .frame(width: style.width)

        case .dashed:
            Canvas { context, size in
                let dashes = stride(from: 0, through: size.width, by: 8)
                for x in dashes {
                    var rect = CGRect(x: x, y: 0, width: 4, height: style.width)
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: style.width / 2),
                        with: .color(style.color)
                    )
                }
            }
            .frame(height: style.width)

        case .dotted:
            Canvas { context, size in
                let dots = stride(from: 0, through: size.width, by: 6)
                for x in dots {
                    let circle = Path(
                        ellipseIn: CGRect(x: x, y: 0, width: style.width, height: style.width)
                    )
                    context.fill(circle, with: .color(style.color))
                }
            }
            .frame(height: style.width)
        }
    }
}
