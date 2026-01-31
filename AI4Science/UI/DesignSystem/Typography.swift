import SwiftUI

/// Typography styles for the AI4Science app
public struct Typography {
    // MARK: - Display Styles
    public static let displayLarge = Font.system(size: 57, weight: .bold, design: .default)
        .tracking(0)

    public static let displayMedium = Font.system(size: 45, weight: .bold, design: .default)
        .tracking(0)

    public static let displaySmall = Font.system(size: 36, weight: .bold, design: .default)
        .tracking(0)

    // MARK: - Headline Styles
    public static let headlineLarge = Font.system(size: 32, weight: .bold, design: .default)
        .tracking(0)

    public static let headlineMedium = Font.system(size: 28, weight: .bold, design: .default)
        .tracking(0)

    public static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .default)
        .tracking(0)

    // MARK: - Title Styles
    public static let titleLarge = Font.system(size: 22, weight: .bold, design: .default)
        .tracking(0)

    public static let titleMedium = Font.system(size: 16, weight: .semibold, design: .default)
        .tracking(0.15)

    public static let titleSmall = Font.system(size: 14, weight: .semibold, design: .default)
        .tracking(0.1)

    // MARK: - Body Styles
    public static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        .tracking(0.15)

    public static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        .tracking(0.25)

    public static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
        .tracking(0.4)

    // MARK: - Label Styles
    public static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
        .tracking(0.1)

    public static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        .tracking(0.5)

    public static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
        .tracking(0.5)

    // MARK: - Button Styles
    public static let buttonLarge = Font.system(size: 16, weight: .semibold, design: .default)
        .tracking(0.1)

    public static let buttonMedium = Font.system(size: 14, weight: .semibold, design: .default)
        .tracking(0.1)

    public static let buttonSmall = Font.system(size: 12, weight: .semibold, design: .default)
        .tracking(0.5)
}

// MARK: - ViewModifier for Text Styles
public struct TypographyModifier: ViewModifier {
    public enum Style {
        case displayLarge, displayMedium, displaySmall
        case headlineLarge, headlineMedium, headlineSmall
        case titleLarge, titleMedium, titleSmall
        case bodyLarge, bodyMedium, bodySmall
        case labelLarge, labelMedium, labelSmall
        case buttonLarge, buttonMedium, buttonSmall

        public var font: Font {
            switch self {
            case .displayLarge: return Typography.displayLarge
            case .displayMedium: return Typography.displayMedium
            case .displaySmall: return Typography.displaySmall
            case .headlineLarge: return Typography.headlineLarge
            case .headlineMedium: return Typography.headlineMedium
            case .headlineSmall: return Typography.headlineSmall
            case .titleLarge: return Typography.titleLarge
            case .titleMedium: return Typography.titleMedium
            case .titleSmall: return Typography.titleSmall
            case .bodyLarge: return Typography.bodyLarge
            case .bodyMedium: return Typography.bodyMedium
            case .bodySmall: return Typography.bodySmall
            case .labelLarge: return Typography.labelLarge
            case .labelMedium: return Typography.labelMedium
            case .labelSmall: return Typography.labelSmall
            case .buttonLarge: return Typography.buttonLarge
            case .buttonMedium: return Typography.buttonMedium
            case .buttonSmall: return Typography.buttonSmall
            }
        }

        public var lineHeight: CGFloat {
            switch self {
            case .displayLarge: return 64
            case .displayMedium: return 52
            case .displaySmall: return 44
            case .headlineLarge: return 40
            case .headlineMedium: return 36
            case .headlineSmall: return 32
            case .titleLarge: return 28
            case .titleMedium: return 24
            case .titleSmall: return 20
            case .bodyLarge: return 24
            case .bodyMedium: return 20
            case .bodySmall: return 16
            case .labelLarge: return 20
            case .labelMedium: return 16
            case .labelSmall: return 16
            case .buttonLarge: return 24
            case .buttonMedium: return 20
            case .buttonSmall: return 16
            }
        }
    }

    let style: Style

    public func body(content: Content) -> some View {
        content
            .font(style.font)
            .lineSpacing(style.lineHeight - style.font.pointSize)
    }
}

// MARK: - Text Style Extension
extension Text {
    public func typographyStyle(_ style: TypographyModifier.Style) -> some View {
        self.modifier(TypographyModifier(style: style))
    }
}

// MARK: - View Extension
extension View {
    public func typographyStyle(_ style: TypographyModifier.Style) -> some View {
        self.modifier(TypographyModifier(style: style))
    }
}
