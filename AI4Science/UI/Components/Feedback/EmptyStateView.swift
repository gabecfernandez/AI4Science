import SwiftUI

/// Empty state placeholder component
public struct EmptyStateView: View {
    let icon: Image
    let title: String
    let message: String?
    let action: (label: String, handler: () -> Void)?

    @Environment(\.theme) var theme

    public init(
        icon: Image,
        title: String,
        message: String? = nil,
        action: (label: String, handler: () -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
    }

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            icon
                .font(.system(size: 64, weight: .light))
                .foregroundColor(ColorPalette.onSurfaceVariant)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(Typography.titleLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorPalette.onBackground)

                if let message = message {
                    Text(message)
                        .font(Typography.bodyMedium)
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
            }

            if let action = action {
                PrimaryButton(action.label, action: action.handler)
                    .padding(.top, Spacing.md)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(ColorPalette.background)
    }
}

#Preview {
    VStack {
        EmptyStateView(
            icon: IconAssets.projects,
            title: "No Projects Yet",
            message: "Create your first project to get started with AI4Science",
            action: ("Create Project", {})
        )
    }
}
