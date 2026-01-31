import SwiftUI

/// Error display component
public struct ErrorView: View {
    let title: String
    let message: String
    let errorCode: String?
    let action: (label: String, handler: () -> Void)?
    let isDismissible: Bool
    let onDismiss: (() -> Void)?

    @Environment(\.theme) var theme

    public init(
        title: String,
        message: String,
        errorCode: String? = nil,
        action: (label: String, handler: () -> Void)? = nil,
        isDismissible: Bool = false,
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.errorCode = errorCode
        self.action = action
        self.isDismissible = isDismissible
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(title)
                        .font(Typography.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorPalette.error)

                    Text(message)
                        .font(Typography.bodySmall)
                        .foregroundColor(ColorPalette.onBackground)

                    if let code = errorCode {
                        Text("Error: \(code)")
                            .font(Typography.labelSmall)
                            .foregroundColor(ColorPalette.onSurfaceVariant)
                    }
                }

                if isDismissible {
                    Spacer()

                    Button(action: { onDismiss?() }) {
                        IconAssets.close
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(ColorPalette.error)
                    }
                }
            }

            if let action = action {
                PrimaryButton(action.label, action: action.handler)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.base)
        .background(
            ColorPalette.error.opacity(0.1)
        )
        .cornerRadius(BorderStyles.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .stroke(ColorPalette.error.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        ErrorView(
            title: "Failed to Load",
            message: "Unable to retrieve project data. Please check your connection.",
            errorCode: "NET_ERROR_001"
        )

        ErrorView(
            title: "Analysis Failed",
            message: "The analysis could not be completed. Try again.",
            isDismissible: true,
            onDismiss: {}
        )

        ErrorView(
            title: "Permission Denied",
            message: "You don't have permission to access this resource.",
            action: ("Request Access", {})
        )

        Spacer()
    }
    .screenPadding()
    .background(ColorPalette.background)
}
