import SwiftUI

/// Icon-only button for compact UI elements
public struct IconButton: View {
    let icon: Image
    let size: IconAssets.IconSize
    let tint: Color
    let backgroundColor: Color?
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    @Environment(\.theme) var theme

    public init(
        _ icon: Image,
        size: IconAssets.IconSize = .medium,
        tint: Color = ColorPalette.utsa_primary,
        backgroundColor: Color? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.tint = tint
        self.backgroundColor = backgroundColor
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .tint(tint)
                    .frame(width: size.value, height: size.value)
            } else {
                icon
                    .font(.system(size: size.value, weight: .semibold, design: .default))
                    .foregroundColor(isEnabled ? tint : ColorPalette.disabled)
            }
        }
        .frame(width: size.value + Spacing.md, height: size.value + Spacing.md)
        .background(backgroundColor ?? Color.clear)
        .cornerRadius(BorderStyles.radiusMedium)
        .disabled(!isEnabled || isLoading)
        .contentShape(Rectangle())
        .opacity(isLoading ? 0.8 : 1.0)
        .accessibilityElement(children: .ignore)
        .accessibilityEnabled(isEnabled)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        HStack(spacing: Spacing.md) {
            IconButton(IconAssets.back) {}
            IconButton(IconAssets.forward) {}
            IconButton(IconAssets.search) {}
        }

        HStack(spacing: Spacing.md) {
            IconButton(
                IconAssets.close,
                tint: ColorPalette.error,
                backgroundColor: ColorPalette.error.opacity(0.1)
            ) {}
            IconButton(
                IconAssets.save,
                tint: ColorPalette.success,
                backgroundColor: ColorPalette.success.opacity(0.1)
            ) {}
            IconButton(
                IconAssets.warning,
                tint: ColorPalette.warning,
                backgroundColor: ColorPalette.warning.opacity(0.1)
            ) {}
        }

        HStack(spacing: Spacing.md) {
            IconButton(IconAssets.refresh, isLoading: true) {}
            IconButton(IconAssets.delete, isEnabled: false) {}
        }
    }
    .screenPadding()
    .background(ColorPalette.background)
}
