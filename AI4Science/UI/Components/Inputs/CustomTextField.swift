import SwiftUI

/// Custom styled text field component
public struct CustomTextField: View {
    let label: String
    let placeholder: String
    let icon: Image?
    let isSecure: Bool
    let isError: Bool
    let errorMessage: String?
    @Binding var text: String

    @Environment(\.theme) var theme
    @FocusState private var isFocused: Bool

    public init(
        _ label: String,
        placeholder: String = "",
        icon: Image? = nil,
        text: Binding<String>,
        isSecure: Bool = false,
        isError: Bool = false,
        errorMessage: String? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.icon = icon
        self._text = text
        self.isSecure = isSecure
        self.isError = isError
        self.errorMessage = errorMessage
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(Typography.labelMedium)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.onBackground)

            HStack(spacing: Spacing.sm) {
                if let icon = icon {
                    icon
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(
                            isFocused ? ColorPalette.utsa_primary : ColorPalette.onSurfaceVariant
                        )
                }

                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(.none)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .textContentType(.none)
                        .focused($isFocused)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(ColorPalette.surface)
            .cornerRadius(BorderStyles.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                    .stroke(
                        isError ? ColorPalette.error :
                        isFocused ? ColorPalette.utsa_primary :
                        ColorPalette.divider,
                        lineWidth: isError ? 2 : 1.5
                    )
            )

            if isError, let message = errorMessage {
                HStack(spacing: Spacing.xs) {
                    IconAssets.error
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.error)

                    Text(message)
                        .font(Typography.labelSmall)
                        .foregroundColor(ColorPalette.error)
                }
            }
        }
        .accessibilityLabel(label)
        .accessibilityValue(text)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        CustomTextField(
            "Email",
            placeholder: "Enter your email",
            icon: IconAssets.mail,
            text: .constant(""),
            errorMessage: nil
        )

        CustomTextField(
            "Password",
            placeholder: "Enter your password",
            icon: IconAssets.lock,
            text: .constant(""),
            isSecure: true
        )

        CustomTextField(
            "Search",
            placeholder: "Search samples...",
            icon: IconAssets.search,
            text: .constant(""),
            isError: true,
            errorMessage: "Invalid search query"
        )
    }
    .screenPadding()
    .background(ColorPalette.background)
}
