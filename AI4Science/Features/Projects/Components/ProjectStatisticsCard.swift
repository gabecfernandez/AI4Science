import SwiftUI

/// A card displaying project statistics
public struct ProjectStatisticsCard: View {
    let title: String
    let value: String
    let icon: Image
    let iconColor: Color

    public init(
        title: String,
        value: String,
        icon: Image,
        iconColor: Color = ColorPalette.utsa_primary
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.iconColor = iconColor
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            icon
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1))
                .cornerRadius(Spacing.radiusMedium)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)

                Text(value)
                    .font(Typography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorPalette.onSurface)
            }

            Spacer()
        }
        .padding(Spacing.base)
        .background(ColorPalette.surface)
        .cornerRadius(BorderStyles.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .stroke(ColorPalette.divider, lineWidth: 1)
        )
    }
}

/// A grid of statistics cards
public struct ProjectStatisticsGrid: View {
    let sampleCount: Int
    let participantCount: Int
    let startDate: Date
    let lastUpdated: Date

    public init(
        sampleCount: Int,
        participantCount: Int,
        startDate: Date,
        lastUpdated: Date
    ) {
        self.sampleCount = sampleCount
        self.participantCount = participantCount
        self.startDate = startDate
        self.lastUpdated = lastUpdated
    }

    public var body: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                ProjectStatisticsCard(
                    title: "Samples",
                    value: "\(sampleCount)",
                    icon: IconAssets.flask,
                    iconColor: ColorPalette.utsa_primary
                )

                ProjectStatisticsCard(
                    title: "Participants",
                    value: "\(participantCount)",
                    icon: IconAssets.users,
                    iconColor: ColorPalette.utsa_secondary
                )
            }

            HStack(spacing: Spacing.md) {
                ProjectStatisticsCard(
                    title: "Start Date",
                    value: formatDate(startDate),
                    icon: IconAssets.pending,
                    iconColor: ColorPalette.success
                )

                ProjectStatisticsCard(
                    title: "Last Updated",
                    value: formatRelativeDate(lastUpdated),
                    icon: IconAssets.refresh,
                    iconColor: ColorPalette.info
                )
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        ProjectStatisticsCard(
            title: "Total Samples",
            value: "24",
            icon: IconAssets.flask
        )

        ProjectStatisticsGrid(
            sampleCount: 24,
            participantCount: 5,
            startDate: Date().addingTimeInterval(-86400 * 30),
            lastUpdated: Date().addingTimeInterval(-3600)
        )
    }
    .padding()
    .background(ColorPalette.background)
}
