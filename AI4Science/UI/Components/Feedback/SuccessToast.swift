import SwiftUI

/// Success notification toast component
public struct SuccessToast: View {
    let message: String
    let icon: Image
    let duration: TimeInterval
    let onDismiss: () -> Void

    @Environment(\.theme) var theme
    @State private var isVisible = true

    public init(
        _ message: String,
        icon: Image = IconAssets.success,
        duration: TimeInterval = 3.0,
        onDismiss: @escaping () -> Void = {}
    ) {
        self.message = message
        self.icon = icon
        self.duration = duration
        self.onDismiss = onDismiss
    }

    public var body: some View {
        if isVisible {
            HStack(spacing: Spacing.md) {
                icon
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Text(message)
                    .font(Typography.bodyMedium)
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    withAnimation {
                        isVisible = false
                        onDismiss()
                    }
                }) {
                    IconAssets.close
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(Spacing.base)
            .background(ColorPalette.success)
            .cornerRadius(BorderStyles.radiusMedium)
            .shadow(Shadows.medium)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation {
                        isVisible = false
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Toast Container
public struct ToastContainer<Content: View>: View {
    let content: Content
    @State private var toastMessage: String?
    @State private var toastType: ToastType = .success

    public enum ToastType {
        case success
        case error
        case info
        case warning

        public var color: Color {
            switch self {
            case .success: return ColorPalette.success
            case .error: return ColorPalette.error
            case .info: return ColorPalette.info
            case .warning: return ColorPalette.warning
            }
        }

        public var icon: Image {
            switch self {
            case .success: return IconAssets.success
            case .error: return IconAssets.error
            case .info: return IconAssets.info
            case .warning: return IconAssets.warning
            }
        }
    }

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ZStack(alignment: .top) {
            content

            if let message = toastMessage {
                SuccessToast(
                    message,
                    icon: toastType.icon,
                    duration: 3.0
                ) {
                    toastMessage = nil
                }
                .padding(Spacing.base)
            }
        }
    }

    public func showToast(
        _ message: String,
        type: ToastType = .success,
        duration: TimeInterval = 3.0
    ) {
        toastType = type
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                toastMessage = nil
            }
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        SuccessToast("Project saved successfully")

        SuccessToast(
            "Analysis complete",
            icon: IconAssets.analysis
        )

        Spacer()
    }
    .screenPadding()
    .background(ColorPalette.background)
}
