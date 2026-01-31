import SwiftUI

/// Toolbar button for navigation and action bars
public struct ToolbarButton: View {
    enum Style {
        case icon
        case text
        case iconText

        public var showIcon: Bool {
            self == .icon || self == .iconText
        }

        public var showText: Bool {
            self == .text || self == .iconText
        }
    }

    let icon: Image?
    let title: String?
    let style: Style
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    @Environment(\.theme) var theme

    public init(
        icon: Image? = nil,
        title: String? = nil,
        style: Style = .icon,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(ColorPalette.utsa_primary)
                } else if style.showIcon, let icon = icon {
                    icon
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .foregroundColor(isEnabled ? ColorPalette.utsa_primary : ColorPalette.disabled)
                }

                if style.showText, let title = title {
                    Text(title)
                        .font(Typography.labelMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(isEnabled ? ColorPalette.utsa_primary : ColorPalette.disabled)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(ColorPalette.surface.opacity(0.5))
            .cornerRadius(BorderStyles.radiusMedium)
        }
        .disabled(!isEnabled || isLoading)
        .contentShape(Rectangle())
        .opacity(isLoading ? 0.8 : 1.0)
        .accessibilityLabel(title ?? "Toolbar button")
        .accessibilityHint(isLoading ? "Processing" : nil)
        .accessibilityEnabled(isEnabled)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        HStack(spacing: Spacing.sm) {
            ToolbarButton(icon: IconAssets.back) {}
            ToolbarButton(icon: IconAssets.refresh) {}
            ToolbarButton(icon: IconAssets.search) {}
        }

        HStack(spacing: Spacing.sm) {
            ToolbarButton(title: "Save", style: .text) {}
            ToolbarButton(title: "Cancel", style: .text) {}
        }

        HStack(spacing: Spacing.sm) {
            ToolbarButton(icon: IconAssets.save, title: "Save", style: .iconText) {}
            ToolbarButton(icon: IconAssets.delete, title: "Delete", style: .iconText) {}
        }

        HStack(spacing: Spacing.sm) {
            ToolbarButton(icon: IconAssets.refresh, isLoading: true) {}
            ToolbarButton(icon: IconAssets.close, isEnabled: false) {}
        }
    }
    .screenPadding()
    .background(ColorPalette.background)
}
