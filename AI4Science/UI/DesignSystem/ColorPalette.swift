import SwiftUI

/// UTSA Brand Colors and semantic color definitions for AI4Science app
public struct ColorPalette {
    // MARK: - Primary Colors (UTSA Brand)
    public static let utsa_primary = Color(red: 0.004, green: 0.443, blue: 0.663) // #0071A9
    public static let utsa_secondary = Color(red: 0.882, green: 0.612, blue: 0.141) // #E09C24
    public static let utsa_dark = Color(red: 0.0, green: 0.0, blue: 0.0) // #000000
    public static let utsa_light = Color(red: 0.973, green: 0.973, blue: 0.973) // #F8F8F8

    // MARK: - Convenience Aliases
    public static let primary = utsa_primary
    public static let secondary = utsa_secondary

    // MARK: - Semantic Colors
    public static let success = Color(red: 0.051, green: 0.588, blue: 0.322) // #0E9652
    public static let error = Color(red: 0.941, green: 0.235, blue: 0.208) // #F03B35
    public static let warning = Color(red: 1.0, green: 0.757, blue: 0.027) // #FFC107
    public static let info = Color(red: 0.004, green: 0.443, blue: 0.663) // #0071A9

    // MARK: - Neutral Colors
    public static let neutral_100 = Color(red: 0.973, green: 0.973, blue: 0.973) // #F8F8F8
    public static let neutral_200 = Color(red: 0.933, green: 0.933, blue: 0.933) // #EEEEEE
    public static let neutral_300 = Color(red: 0.886, green: 0.886, blue: 0.886) // #E2E2E2
    public static let neutral_400 = Color(red: 0.741, green: 0.741, blue: 0.741) // #BDBDBD
    public static let neutral_500 = Color(red: 0.627, green: 0.627, blue: 0.627) // #A0A0A0
    public static let neutral_600 = Color(red: 0.498, green: 0.498, blue: 0.498) // #7F7F7F
    public static let neutral_700 = Color(red: 0.373, green: 0.373, blue: 0.373) // #5F5F5F
    public static let neutral_800 = Color(red: 0.247, green: 0.247, blue: 0.247) // #3F3F3F
    public static let neutral_900 = Color(red: 0.122, green: 0.122, blue: 0.122) // #1F1F1F

    // MARK: - Functional Colors
    public static let background = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1)
            : UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    })

    public static let surface = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1)
            : UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)
    })

    public static let surfaceVariant = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.24, green: 0.24, blue: 0.24, alpha: 1)
            : UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1)
    })

    public static let onBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1)
            : UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
    })

    public static let onSurface = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1)
            : UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1)
    })

    public static let onSurfaceVariant = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.73, green: 0.73, blue: 0.73, alpha: 1)
            : UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 1)
    })

    // MARK: - State Colors
    public static let disabled = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.31, green: 0.31, blue: 0.31, alpha: 0.38)
            : UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 0.38)
    })

    public static let disabledContainer = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 0.12)
            : UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 0.12)
    })

    // MARK: - Highlight Colors
    public static let highlight = utsa_secondary.opacity(0.2)
    public static let divider = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 1, green: 1, blue: 1, alpha: 0.12)
            : UIColor(red: 0, green: 0, blue: 0, alpha: 0.12)
    })

    // MARK: - Science/Analysis Colors
    public static let confidence_high = Color(red: 0.051, green: 0.588, blue: 0.322) // Green
    public static let confidence_medium = Color(red: 1.0, green: 0.757, blue: 0.027) // Yellow
    public static let confidence_low = Color(red: 0.941, green: 0.235, blue: 0.208) // Red

    // Chart colors
    public static let chart_blue = Color(red: 0.004, green: 0.443, blue: 0.663)
    public static let chart_orange = Color(red: 1.0, green: 0.596, blue: 0.0)
    public static let chart_green = Color(red: 0.051, green: 0.588, blue: 0.322)
    public static let chart_purple = Color(red: 0.608, green: 0.349, blue: 0.713)
    public static let chart_red = Color(red: 0.941, green: 0.235, blue: 0.208)
}

// MARK: - Color Extensions
extension Color {
    /// Returns an opacity-adjusted color
    public func withOpacity(_ opacity: Double) -> Color {
        self.opacity(opacity)
    }

    /// Returns a lighter shade of the color
    public func lighter(by percentage: CGFloat = 0.2) -> Color {
        guard let components = cgColor?.components, components.count >= 3 else {
            return self
        }
        return Color(
            red: min(1.0, Double(components[0]) + Double(percentage)),
            green: min(1.0, Double(components[1]) + Double(percentage)),
            blue: min(1.0, Double(components[2]) + Double(percentage))
        )
    }

    /// Returns a darker shade of the color
    public func darker(by percentage: CGFloat = 0.2) -> Color {
        guard let components = cgColor?.components, components.count >= 3 else {
            return self
        }
        return Color(
            red: max(0.0, Double(components[0]) - Double(percentage)),
            green: max(0.0, Double(components[1]) - Double(percentage)),
            blue: max(0.0, Double(components[2]) - Double(percentage))
        )
    }
}
