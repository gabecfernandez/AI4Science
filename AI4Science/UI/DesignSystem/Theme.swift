import SwiftUI

/// Main theme configuration for the AI4Science app
public struct Theme {
    // MARK: - Singleton Access
    public static let shared = Theme()

    // MARK: - Color Scheme
    public let colors = ColorPalette()
    public let typography = Typography()
    public let spacing = Spacing()
    public let shadows = Shadows()
    public let borders = BorderStyles()
    public let icons = IconAssets()

    // MARK: - Default Theme Properties
    public var primaryColor: Color { ColorPalette.utsa_primary }
    public var secondaryColor: Color { ColorPalette.utsa_secondary }
    public var backgroundColor: Color { ColorPalette.background }
    public var surfaceColor: Color { ColorPalette.surface }
    public var errorColor: Color { ColorPalette.error }
    public var successColor: Color { ColorPalette.success }
    public var warningColor: Color { ColorPalette.warning }

    // MARK: - Environment Key
    public struct ThemeKey: EnvironmentKey {
        public static let defaultValue = Theme()
    }
}

// MARK: - Environment Modifier
extension EnvironmentValues {
    public var theme: Theme {
        get { self[Theme.ThemeKey.self] }
        set { self[Theme.ThemeKey.self] = newValue }
    }
}

// MARK: - View Extension for Theme Access
extension View {
    public func theme(_ theme: Theme = .shared) -> some View {
        environment(\.theme, theme)
    }
}

// MARK: - Theme Preview Helper
public struct ThemePreview: View {
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Colors
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Colors").typographyStyle(.titleLarge)

                    HStack(spacing: Spacing.sm) {
                        ColorSwatch(color: ColorPalette.utsa_primary, label: "Primary")
                        ColorSwatch(color: ColorPalette.utsa_secondary, label: "Secondary")
                        ColorSwatch(color: ColorPalette.success, label: "Success")
                        ColorSwatch(color: ColorPalette.error, label: "Error")
                    }
                }
                .padding(Spacing.base)
                .background(ColorPalette.surface)
                .cornerRadius(BorderStyles.radiusMedium)

                // Typography
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Typography").typographyStyle(.titleLarge)

                    Text("Display Large").typographyStyle(.displayLarge)
                    Text("Headline Large").typographyStyle(.headlineLarge)
                    Text("Title Large").typographyStyle(.titleLarge)
                    Text("Body Large").typographyStyle(.bodyLarge)
                    Text("Label Large").typographyStyle(.labelLarge)
                }
                .padding(Spacing.base)
                .background(ColorPalette.surface)
                .cornerRadius(BorderStyles.radiusMedium)

                // Spacing
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Spacing").typographyStyle(.titleLarge)

                    HStack(spacing: Spacing.sm) {
                        ForEach([4, 8, 12, 16, 24], id: \.self) { size in
                            VStack {
                                ColorPalette.utsa_primary
                                    .frame(width: CGFloat(size), height: CGFloat(size))

                                Text("\(size)").font(.caption)
                            }
                        }
                    }
                }
                .padding(Spacing.base)
                .background(ColorPalette.surface)
                .cornerRadius(BorderStyles.radiusMedium)
            }
            .screenPadding()
        }
        .background(ColorPalette.background)
    }
}

// MARK: - Color Swatch Component
struct ColorSwatch: View {
    let color: Color
    let label: String

    var body: some View {
        VStack(spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .fill(color)
                .frame(height: 60)

            Text(label)
                .font(.caption)
                .lineLimit(1)
        }
    }
}

#Preview {
    ThemePreview()
}
