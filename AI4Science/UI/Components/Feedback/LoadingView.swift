import SwiftUI

/// Loading indicators and spinner views
public struct LoadingView: View {
    let message: String?
    let style: LoadingStyle

    @Environment(\.theme) var theme

    public enum LoadingStyle {
        case spinner
        case dots
        case pulse
        case bar
    }

    public init(
        _ message: String? = nil,
        style: LoadingStyle = .spinner
    ) {
        self.message = message
        self.style = style
    }

    public var body: some View {
        VStack(spacing: Spacing.md) {
            loadingIndicator
                .frame(width: 48, height: 48)

            if let message = message {
                Text(message)
                    .font(Typography.bodyMedium)
                    .foregroundColor(ColorPalette.onBackground)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorPalette.background)
    }

    @ViewBuilder
    private var loadingIndicator: some View {
        switch style {
        case .spinner:
            ProgressView()
                .tint(ColorPalette.utsa_primary)
                .scaleEffect(1.5)

        case .dots:
            HStack(spacing: Spacing.sm) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(ColorPalette.utsa_primary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(
                            1 + sin(Double(index) * 0.33 * .pi) * 0.3
                        )
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                            value: Double(index)
                        )
                }
            }

        case .pulse:
            Circle()
                .fill(ColorPalette.utsa_primary)
                .scaleEffect(1.0)
                .opacity(1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: true
                )

        case .bar:
            ProgressView()
                .tint(ColorPalette.utsa_primary)
        }
    }
}

// MARK: - Loading Skeleton
public struct SkeletonView: View {
    let lines: Int
    let spacing: CGFloat

    @Environment(\.theme) var theme

    public init(lines: Int = 3, spacing: CGFloat = Spacing.md) {
        self.lines = lines
        self.spacing = spacing
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<lines, id: \.self) { _ in
                RoundedRectangle(cornerRadius: BorderStyles.radiusSmall)
                    .fill(ColorPalette.surfaceVariant)
                    .frame(height: 16)
                    .shimmer()
            }
        }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        LoadingView("Loading projects...")

        LoadingView("Processing...", style: .dots)

        LoadingView("Analyzing...", style: .pulse)

        LoadingView(style: .bar)

        SkeletonView(lines: 2)
    }
    .screenPadding()
    .background(ColorPalette.background)
}
