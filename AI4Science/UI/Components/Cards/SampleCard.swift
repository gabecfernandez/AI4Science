import SwiftUI

/// Card component for displaying sample/image information
public struct SampleCard: View {
    let title: String
    let status: SampleStatus
    let confidenceScore: Double?
    let imageURL: URL?
    let timestamp: Date?
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.theme) var theme

    public enum SampleStatus {
        case captured
        case processing
        case analyzed
        case failed

        public var color: Color {
            switch self {
            case .captured: return ColorPalette.info
            case .processing: return ColorPalette.warning
            case .analyzed: return ColorPalette.success
            case .failed: return ColorPalette.error
            }
        }

        public var label: String {
            switch self {
            case .captured: return "Captured"
            case .processing: return "Processing"
            case .analyzed: return "Analyzed"
            case .failed: return "Failed"
            }
        }
    }

    public init(
        title: String,
        status: SampleStatus = .captured,
        confidenceScore: Double? = nil,
        imageURL: URL? = nil,
        timestamp: Date? = nil,
        isSelected: Bool = false,
        onTap: @escaping () -> Void = {}
    ) {
        self.title = title
        self.status = status
        self.confidenceScore = confidenceScore
        self.imageURL = imageURL
        self.timestamp = timestamp
        self.isSelected = isSelected
        self.onTap = onTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Image Placeholder
            ZStack {
                RoundedRectangle(cornerRadius: BorderStyles.radiusSmall)
                    .fill(ColorPalette.surfaceVariant)
                    .frame(height: 120)

                if imageURL == nil {
                    IconAssets.image
                        .font(.system(size: 32))
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.titleSmall)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                // Status and Score
                HStack(spacing: Spacing.sm) {
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(status.color)
                            .frame(width: 8, height: 8)

                        Text(status.label)
                            .font(Typography.labelSmall)
                            .foregroundColor(status.color)
                    }

                    if let score = confidenceScore {
                        Spacer()

                        HStack(spacing: Spacing.xs) {
                            Text(String(format: "%.0f%%", score * 100))
                                .font(Typography.labelSmall)
                                .fontWeight(.semibold)
                                .foregroundColor(
                                    score > 0.7 ? ColorPalette.success :
                                    score > 0.5 ? ColorPalette.warning :
                                    ColorPalette.error
                                )
                        }
                    }
                }

                // Timestamp
                if let timestamp = timestamp {
                    Text(formatTime(timestamp))
                        .font(Typography.labelSmall)
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(ColorPalette.surface)
        .cornerRadius(BorderStyles.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .stroke(
                    isSelected ? ColorPalette.utsa_primary : ColorPalette.divider,
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(Shadows.small)
        .onTapGesture(perform: onTap)
        .contentShape(.rect)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        SampleCard(
            title: "Leaf Sample 01",
            status: .analyzed,
            confidenceScore: 0.92,
            timestamp: Date()
        )

        SampleCard(
            title: "Processing...",
            status: .processing,
            timestamp: Date(timeIntervalSinceNow: -1800)
        )

        SampleCard(
            title: "Failed Sample",
            status: .failed,
            timestamp: Date(timeIntervalSinceNow: -3600)
        )
    }
    .screenPadding()
    .background(ColorPalette.background)
}
