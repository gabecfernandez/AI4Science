import SwiftUI

/// Card component for displaying annotation summaries
public struct AnnotationCard: View {
    let title: String
    let annotationType: AnnotationType
    let count: Int
    let timestamp: Date?
    let isActive: Bool
    let onTap: () -> Void

    @Environment(\.theme) var theme

    public enum AnnotationType {
        case boundingBox
        case polygon
        case freehand
        case point
        case segmentation

        public var icon: Image {
            switch self {
            case .boundingBox: return IconAssets.box
            case .polygon: return IconAssets.polygon
            case .freehand: return IconAssets.paintbrush
            case .point: return IconAssets.circle
            case .segmentation: return IconAssets.chart
            }
        }

        public var label: String {
            switch self {
            case .boundingBox: return "Bounding Boxes"
            case .polygon: return "Polygons"
            case .freehand: return "Freehand"
            case .point: return "Points"
            case .segmentation: return "Segmentation"
            }
        }

        public var color: Color {
            switch self {
            case .boundingBox: return ColorPalette.chart_blue
            case .polygon: return ColorPalette.chart_purple
            case .freehand: return ColorPalette.chart_orange
            case .point: return ColorPalette.chart_red
            case .segmentation: return ColorPalette.chart_green
            }
        }
    }

    public init(
        title: String,
        annotationType: AnnotationType,
        count: Int = 0,
        timestamp: Date? = nil,
        isActive: Bool = false,
        onTap: @escaping () -> Void = {}
    ) {
        self.title = title
        self.annotationType = annotationType
        self.count = count
        self.timestamp = timestamp
        self.isActive = isActive
        self.onTap = onTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(Typography.titleSmall)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(annotationType.label)
                        .font(Typography.labelSmall)
                        .foregroundColor(annotationType.color)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        annotationType.icon
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(annotationType.color)

                        Text("\(count)")
                            .font(Typography.titleSmall)
                            .fontWeight(.bold)
                            .foregroundColor(annotationType.color)
                    }

                    if let timestamp = timestamp {
                        Text(formatTime(timestamp))
                            .font(Typography.labelSmall)
                            .foregroundColor(ColorPalette.onSurfaceVariant)
                    }
                }
            }

            // Progress bar
            ProgressView(value: min(Double(count) / 10.0, 1.0))
                .tint(annotationType.color)
                .frame(height: 6)
                .cornerRadius(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.base)
        .background(ColorPalette.surface)
        .cornerRadius(BorderStyles.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .stroke(
                    isActive ? annotationType.color : ColorPalette.divider,
                    lineWidth: isActive ? 2 : 1
                )
        )
        .shadow(Shadows.small)
        .onTapGesture(perform: onTap)
        .contentShape(.rect)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        AnnotationCard(
            title: "Plant Sample 01",
            annotationType: .boundingBox,
            count: 3,
            timestamp: Date()
        )

        AnnotationCard(
            title: "Leaf Disease",
            annotationType: .polygon,
            count: 7,
            timestamp: Date(timeIntervalSinceNow: -3600),
            isActive: true
        )

        AnnotationCard(
            title: "Segmentation Mask",
            annotationType: .segmentation,
            count: 1,
            timestamp: Date(timeIntervalSinceNow: -86400)
        )
    }
    .screenPadding()
    .background(ColorPalette.background)
}
