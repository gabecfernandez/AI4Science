import SwiftUI

/// Progress indicator component
public struct ProgressIndicator: View {
    let progress: Double
    let style: ProgressStyle
    let showLabel: Bool
    let label: String?

    @Environment(\.theme) var theme

    public enum ProgressStyle {
        case linear
        case circular
        case segment
    }

    public init(
        _ progress: Double,
        style: ProgressStyle = .linear,
        showLabel: Bool = true,
        label: String? = nil
    ) {
        self.progress = min(max(progress, 0), 1)
        self.style = style
        self.showLabel = showLabel
        self.label = label
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if showLabel {
                HStack {
                    if let label = label {
                        Text(label)
                            .font(Typography.labelMedium)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    Text(String(format: "%.0f%%", progress * 100))
                        .font(Typography.labelMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorPalette.utsa_primary)
                }
            }

            switch style {
            case .linear:
                linearProgress

            case .circular:
                circularProgress

            case .segment:
                segmentedProgress
            }
        }
    }

    @ViewBuilder
    private var linearProgress: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .fill(ColorPalette.surfaceVariant)

            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .fill(progressColor)
                .frame(width: UIScreen.main.bounds.width * CGFloat(progress) - Spacing.base * 2)
        }
        .frame(height: 8)
    }

    @ViewBuilder
    private var circularProgress: some View {
        ZStack {
            Circle()
                .stroke(ColorPalette.surfaceVariant, lineWidth: 8)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text(String(format: "%.0f%%", progress * 100))
                .font(Typography.titleSmall)
                .fontWeight(.bold)
        }
        .frame(width: 80, height: 80)
    }

    @ViewBuilder
    private var segmentedProgress: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        Double(index) / 10.0 <= progress
                            ? progressColor
                            : ColorPalette.surfaceVariant
                    )
                    .frame(height: 4)
            }
        }
    }

    private var progressColor: Color {
        switch progress {
        case 0..<0.33: return ColorPalette.error
        case 0.33..<0.66: return ColorPalette.warning
        default: return ColorPalette.success
        }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        ProgressIndicator(0.3, label: "Download Progress")
        ProgressIndicator(0.6, label: "Analysis Progress")
        ProgressIndicator(0.95, label: "Upload Progress")

        VStack(spacing: Spacing.md) {
            ProgressIndicator(0.4, style: .circular)
            ProgressIndicator(0.7, style: .circular)
        }
        .frame(maxWidth: .infinity)

        ProgressIndicator(0.5, style: .segment, label: "Completion")

        Spacer()
    }
    .screenPadding()
    .background(ColorPalette.background)
}
