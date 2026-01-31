import SwiftUI

/// Card component for displaying analysis results
public struct AnalysisCard: View {
    let title: String
    let resultType: ResultType
    let primaryValue: String
    let secondaryValue: String?
    let details: [(label: String, value: String)]?
    let timestamp: Date?
    let onTap: () -> Void

    @Environment(\.theme) var theme

    public enum ResultType {
        case classification
        case detection
        case segmentation
        case custom(Color)

        public var color: Color {
            switch self {
            case .classification: return ColorPalette.info
            case .detection: return ColorPalette.warning
            case .segmentation: return ColorPalette.success
            case .custom(let color): return color
            }
        }

        public var label: String {
            switch self {
            case .classification: return "Classification"
            case .detection: return "Detection"
            case .segmentation: return "Segmentation"
            case .custom: return "Analysis"
            }
        }
    }

    public init(
        title: String,
        resultType: ResultType = .classification,
        primaryValue: String,
        secondaryValue: String? = nil,
        details: [(label: String, value: String)]? = nil,
        timestamp: Date? = nil,
        onTap: @escaping () -> Void = {}
    ) {
        self.title = title
        self.resultType = resultType
        self.primaryValue = primaryValue
        self.secondaryValue = secondaryValue
        self.details = details
        self.timestamp = timestamp
        self.onTap = onTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(title)
                        .font(Typography.titleSmall)
                        .fontWeight(.semibold)

                    Spacer()

                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(resultType.color)
                            .frame(width: 8, height: 8)

                        Text(resultType.label)
                            .font(Typography.labelSmall)
                            .foregroundColor(resultType.color)
                    }
                }

                if let timestamp = timestamp {
                    Text(formatTime(timestamp))
                        .font(Typography.labelSmall)
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }
            }

            // Main Result
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(primaryValue)
                    .font(Typography.headlineSmall)
                    .fontWeight(.bold)
                    .foregroundColor(resultType.color)

                if let secondary = secondaryValue {
                    Text(secondary)
                        .font(Typography.labelMedium)
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }
            }

            // Details
            if let details = details, !details.isEmpty {
                VStack(spacing: Spacing.sm) {
                    ForEach(details, id: \.label) { detail in
                        HStack {
                            Text(detail.label)
                                .font(Typography.labelSmall)
                                .foregroundColor(ColorPalette.onSurfaceVariant)

                            Spacer()

                            Text(detail.value)
                                .font(Typography.labelSmall)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(Spacing.sm)
                .background(ColorPalette.surfaceVariant.opacity(0.5))
                .cornerRadius(BorderStyles.radiusSmall)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.base)
        .background(ColorPalette.surface)
        .cornerRadius(BorderStyles.radiusMedium)
        .shadow(Shadows.small)
        .onTapGesture(perform: onTap)
        .contentShape(Rectangle())
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        AnalysisCard(
            title: "Leaf Disease Classification",
            resultType: .classification,
            primaryValue: "Early Blight",
            secondaryValue: "Confidence: 92%",
            details: [
                ("Severity", "Moderate"),
                ("Treatment", "Fungicide"),
            ],
            timestamp: Date()
        )

        AnalysisCard(
            title: "Object Detection",
            resultType: .detection,
            primaryValue: "5 Objects Detected",
            secondaryValue: "Average confidence: 88%",
            timestamp: Date(timeIntervalSinceNow: -3600)
        )
    }
    .screenPadding()
    .background(ColorPalette.background)
}
