import SwiftUI

/// Secondary action button for alternative user interactions
public struct SecondaryButton: View {
    let title: String
    let icon: Image?
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    @Environment(\.theme) var theme

    public init(
        _ title: String,
        icon: Image? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(ColorPalette.utsa_primary)
                } else if let icon = icon {
                    icon
                        .font(.system(size: 18, weight: .semibold, design: .default))
                }

                Text(title)
                    .font(Typography.buttonMedium)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .foregroundColor(isEnabled ? ColorPalette.utsa_primary : ColorPalette.neutral_500)
            .background(
                isEnabled
                    ? ColorPalette.surface
                    : ColorPalette.disabledContainer
            )
            .overlay(
                RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                    .stroke(
                        isEnabled ? ColorPalette.utsa_primary : ColorPalette.divider,
                        lineWidth: 1.5
                    )
            )
            .cornerRadius(BorderStyles.radiusMedium)
            .opacity(isLoading ? 0.8 : 1.0)
        }
        .disabled(!isEnabled || isLoading)
        .contentShape(.rect)
        .accessibilityLabel(title)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        SecondaryButton("Cancel") {}

        SecondaryButton(
            "Edit",
            icon: IconAssets.edit,
            action: {}
        )

        SecondaryButton(
            "Loading",
            isLoading: true,
            action: {}
        )

        SecondaryButton(
            "Disabled",
            isEnabled: false,
            action: {}
        )
    }
    .screenPadding()
    .background(ColorPalette.background)
}
