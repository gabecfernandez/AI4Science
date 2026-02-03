//
//  ProfileView.swift
//  AI4Science
//
//  User profile and settings view
//

import SwiftUI

struct ProfileView: View {
    @Environment(ServiceContainer.self) private var services
    @State private var viewModel: ProfileViewModel?

    var body: some View {
        ZStack {
            ColorPalette.background
                .ignoresSafeArea()

            if let viewModel = viewModel {
                profileContent(viewModel)
            } else {
                LoadingView("Loading profile...")
            }
        }
        .navigationTitle("Profile")
        .task {
            if viewModel == nil {
                viewModel = ProfileViewModel(
                    userRepository: services.userRepository,
                    projectRepository: services.projectRepository,
                    captureRepository: services.captureRepository
                )
            }
            await viewModel?.loadProfile()
        }
    }

    @ViewBuilder
    private func profileContent(_ viewModel: ProfileViewModel) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if viewModel.isLoading && viewModel.user == nil {
                    LoadingView("Loading profile...")
                } else if let user = viewModel.user {
                    profileHeader(user)
                    statsSection(user)
                    settingsSection
                } else {
                    EmptyStateView(
                        icon: IconAssets.profile,
                        title: "No Profile",
                        message: "Unable to load user profile"
                    )
                }
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.md)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private func profileHeader(_ user: ProfileUser) -> some View {
        VStack(spacing: Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(ColorPalette.utsa_primary.opacity(0.1))
                    .frame(width: 100, height: 100)

                Text(user.fullName.prefix(2).uppercased())
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(ColorPalette.utsa_primary)
            }

            // Name and email
            VStack(spacing: Spacing.xs) {
                Text(user.fullName)
                    .font(Typography.titleLarge)
                    .foregroundColor(ColorPalette.onBackground)

                Text(user.email)
                    .font(Typography.bodyMedium)
                    .foregroundColor(ColorPalette.onSurfaceVariant)

                if let institution = user.institution {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "building.2")
                            .font(.caption)
                        Text(institution)
                    }
                    .font(Typography.bodySmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
                }
            }

            // Member since
            Text("Member since \(formatDate(user.memberSince))")
                .font(Typography.labelSmall)
                .foregroundColor(ColorPalette.onSurfaceVariant)
        }
        .padding(.vertical, Spacing.lg)
    }

    @ViewBuilder
    private func statsSection(_ user: ProfileUser) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Activity")
                .font(Typography.titleSmall)
                .foregroundColor(ColorPalette.onBackground)

            HStack(spacing: Spacing.md) {
                StatCard(
                    icon: "folder.fill",
                    value: "\(user.projectCount)",
                    label: "Projects",
                    color: ColorPalette.utsa_primary
                )

                StatCard(
                    icon: "flask.fill",
                    value: "\(user.sampleCount)",
                    label: "Samples",
                    color: ColorPalette.success
                )

                StatCard(
                    icon: "camera.fill",
                    value: "\(user.captureCount)",
                    label: "Captures",
                    color: ColorPalette.info
                )
            }
        }
    }

    @ViewBuilder
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Settings")
                .font(Typography.titleSmall)
                .foregroundColor(ColorPalette.onBackground)

            VStack(spacing: 0) {
                SettingsRow(icon: "gear", title: "App Settings")
                Divider()
                SettingsRow(icon: "building.2", title: "Lab Affiliation")
                Divider()
                SettingsRow(icon: "square.and.arrow.up", title: "Export Data")
                Divider()
                SettingsRow(icon: "questionmark.circle", title: "Help & Support")
                Divider()
                SettingsRow(icon: "info.circle", title: "About AI4Science")
            }
            .background(ColorPalette.surface)
            .cornerRadius(BorderStyles.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                    .stroke(ColorPalette.divider, lineWidth: 1)
            )
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

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

// MARK: - Settings Row

private struct SettingsRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(ColorPalette.onSurfaceVariant)
                .frame(width: 24)

            Text(title)
                .font(Typography.bodyMedium)
                .foregroundColor(ColorPalette.onSurface)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(ColorPalette.onSurfaceVariant)
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.md)
        .contentShape(.rect)
    }
}

#Preview {
    ProfileView()
}
