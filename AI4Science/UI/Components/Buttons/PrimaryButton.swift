import SwiftUI

/// Primary action button for main user interactions
public struct PrimaryButton: View {
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
                        .tint(.white)
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
            .foregroundColor(.white)
            .background(
                isEnabled
                    ? ColorPalette.utsa_primary
                    : ColorPalette.disabled
            )
            .cornerRadius(BorderStyles.radiusMedium)
            .opacity(isLoading ? 0.8 : 1.0)
        }
        .disabled(!isEnabled || isLoading)
        .contentShape(Rectangle())
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Processing" : nil)
        .accessibilityEnabled(isEnabled)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        PrimaryButton("Submit") {}

        PrimaryButton(
            "Save",
            icon: IconAssets.save,
            action: {}
        )

        PrimaryButton(
            "Loading",
            isLoading: true,
            action: {}
        )

        PrimaryButton(
            "Disabled",
            isEnabled: false,
            action: {}
        )
    }
    .screenPadding()
    .background(ColorPalette.background)
}
