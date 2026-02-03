import SwiftUI

/// Typography styles for the AI4Science app
public struct Typography {
    // MARK: - Display Styles
    public static let displayLarge = Font.system(size: 57, weight: .bold, design: .default)
    public static let displayMedium = Font.system(size: 45, weight: .bold, design: .default)
    public static let displaySmall = Font.system(size: 36, weight: .bold, design: .default)

    // MARK: - Headline Styles
    public static let headlineLarge = Font.system(size: 32, weight: .bold, design: .default)
    public static let headlineMedium = Font.system(size: 28, weight: .bold, design: .default)
    public static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .default)

    // MARK: - Title Styles
    public static let titleLarge = Font.system(size: 22, weight: .bold, design: .default)
    public static let titleMedium = Font.system(size: 16, weight: .semibold, design: .default)
    public static let titleSmall = Font.system(size: 14, weight: .semibold, design: .default)

    // MARK: - Body Styles
    public static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    public static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    public static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)

    // MARK: - Label Styles
    public static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    public static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    public static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

    // MARK: - Button Styles
    public static let buttonLarge = Font.system(size: 16, weight: .semibold, design: .default)
    public static let buttonMedium = Font.system(size: 14, weight: .semibold, design: .default)
    public static let buttonSmall = Font.system(size: 12, weight: .semibold, design: .default)

    // MARK: - Caption Styles
    public static let captionLarge = Font.system(size: 12, weight: .regular, design: .default)
    public static let captionMedium = Font.system(size: 11, weight: .regular, design: .default)
    public static let captionSmall = Font.system(size: 10, weight: .regular, design: .default)

    // MARK: - Code Styles
    public static let codeBlock = Font.system(size: 14, weight: .regular, design: .monospaced)
    public static let codeInline = Font.system(size: 13, weight: .regular, design: .monospaced)

    // MARK: - Convenience Aliases
    public static let title = titleLarge
    public static let body = bodyMedium
    public static let caption = captionMedium
    public static let largeTitle = displayLarge
    public static let subheadline = bodySmall
    public static let headline = headlineSmall
}

// MARK: - Typography Style Enum
public enum TypographyStyle {
    case displayLarge, displayMedium, displaySmall
    case headlineLarge, headlineMedium, headlineSmall
    case titleLarge, titleMedium, titleSmall
    case bodyLarge, bodyMedium, bodySmall
    case labelLarge, labelMedium, labelSmall
    case captionLarge, captionMedium, captionSmall
    case codeBlock, codeInline

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
        case .captionLarge: return Typography.captionLarge
        case .captionMedium: return Typography.captionMedium
        case .captionSmall: return Typography.captionSmall
        case .codeBlock: return Typography.codeBlock
        case .codeInline: return Typography.codeInline
        }
    }
}

// MARK: - Typography Modifiers
extension View {
    /// Apply typography style to view
    public func typography(_ style: Font) -> some View {
        self.font(style)
    }

    /// Apply typography style using enum
    public func typographyStyle(_ style: TypographyStyle) -> some View {
        self.font(style.font)
    }

    /// Apply display large style
    public func displayLarge() -> some View {
        self.font(Typography.displayLarge)
    }

    /// Apply headline medium style
    public func headlineMedium() -> some View {
        self.font(Typography.headlineMedium)
    }

    /// Apply body large style
    public func bodyLarge() -> some View {
        self.font(Typography.bodyLarge)
    }

    /// Apply label medium style
    public func labelMedium() -> some View {
        self.font(Typography.labelMedium)
    }
}
