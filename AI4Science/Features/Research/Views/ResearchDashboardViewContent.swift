//
//  ResearchDashboardViewContent.swift
//  AI4Science
//
//  Main view for the Research tab showing surveys and consent flows
//

import SwiftUI

struct ResearchDashboardViewContent: View {
    @Environment(NavigationCoordinator.self) private var navigation

    var body: some View {
        ZStack {
            ColorPalette.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header section
                    headerSection

                    // Active Studies section
                    activeStudiesSection

                    // Available Surveys section
                    surveysSection

                    // Participation Stats
                    participationSection
                }
                .padding(.horizontal, Spacing.base)
                .padding(.vertical, Spacing.md)
            }
        }
        .navigationTitle("Research")
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "testtube.2")
                    .font(.system(size: 40))
                    .foregroundColor(ColorPalette.utsa_primary)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Citizen Science Program")
                        .font(Typography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorPalette.onSurface)

                    Text("Contribute to materials science research")
                        .font(Typography.bodySmall)
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.base)
        .background(ColorPalette.surface)
        .cornerRadius(BorderStyles.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .stroke(ColorPalette.divider, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var activeStudiesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Active Studies")
                .font(Typography.titleSmall)
                .foregroundColor(ColorPalette.onBackground)

            StudyCard(
                title: "Materials Defect Analysis Study",
                description: "Help train AI models to identify defects in composite materials",
                progress: 0.65,
                status: "In Progress",
                icon: "magnifyingglass.circle.fill"
            )

            StudyCard(
                title: "Surface Texture Classification",
                description: "Contribute to improving texture classification accuracy",
                progress: 0.25,
                status: "Enrolling",
                icon: "square.grid.3x3.fill"
            )
        }
    }

    @ViewBuilder
    private var surveysSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Surveys & Forms")
                    .font(Typography.titleSmall)
                    .foregroundColor(ColorPalette.onBackground)

                Spacer()

                Text("2 Available")
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.utsa_primary)
            }

            SurveyCard(
                title: "Initial Demographics",
                description: "Basic background information for research purposes",
                estimatedTime: "5 min",
                isCompleted: true
            )

            SurveyCard(
                title: "Weekly Activity Log",
                description: "Track your data collection activities",
                estimatedTime: "3 min",
                isCompleted: false
            ) {
                navigation.showSurvey("weekly-activity")
            }

            // Consent flow card
            ConsentCard {
                navigation.showConsentFlow()
            }
        }
    }

    @ViewBuilder
    private var participationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Your Participation")
                .font(Typography.titleSmall)
                .foregroundColor(ColorPalette.onBackground)

            HStack(spacing: Spacing.md) {
                ParticipationStat(
                    value: "12",
                    label: "Submissions",
                    icon: "doc.text.fill"
                )

                ParticipationStat(
                    value: "85%",
                    label: "Quality Score",
                    icon: "star.fill"
                )

                ParticipationStat(
                    value: "3",
                    label: "Studies",
                    icon: "book.fill"
                )
            }
        }
    }
}

// MARK: - Study Card

private struct StudyCard: View {
    let title: String
    let description: String
    let progress: Double
    let status: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(ColorPalette.utsa_primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.titleSmall)
                        .fontWeight(.medium)
                        .foregroundColor(ColorPalette.onSurface)

                    Text(description)
                        .font(Typography.bodySmall)
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }

                Spacer()
            }

            HStack {
                ProgressView(value: progress)
                    .tint(ColorPalette.utsa_primary)

                Text(status)
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.utsa_primary)
            }
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

// MARK: - Survey Card

private struct SurveyCard: View {
    let title: String
    let description: String
    let estimatedTime: String
    let isCompleted: Bool
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(ColorPalette.onSurface)

                    Text(description)
                        .font(Typography.bodySmall)
                        .foregroundColor(ColorPalette.onSurfaceVariant)

                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(estimatedTime)
                    }
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
                }

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ColorPalette.success)
                        .font(.title2)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }
            }
            .padding(Spacing.base)
            .background(ColorPalette.surface)
            .cornerRadius(BorderStyles.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                    .stroke(ColorPalette.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isCompleted)
    }
}

// MARK: - Consent Card

private struct ConsentCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                    .foregroundColor(ColorPalette.info)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Review Consent Form")
                        .font(Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(ColorPalette.onSurface)

                    Text("View or update your research consent")
                        .font(Typography.bodySmall)
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            }
            .padding(Spacing.base)
            .background(ColorPalette.info.opacity(0.1))
            .cornerRadius(BorderStyles.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                    .stroke(ColorPalette.info.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Participation Stat

private struct ParticipationStat: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(ColorPalette.utsa_primary)

            Text(value)
                .font(Typography.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.onSurface)

            Text(label)
                .font(Typography.labelSmall)
                .foregroundColor(ColorPalette.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.base)
        .background(ColorPalette.surface)
        .cornerRadius(BorderStyles.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .stroke(ColorPalette.divider, lineWidth: 1)
        )
    }
}

#Preview {
    ResearchDashboardViewContent()
}
