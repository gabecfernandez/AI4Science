import SwiftUI

struct MemberProfileView: View {
    let member: LabMember
    let currentLabName: String
    let labRepository: LabRepository

    @State private var viewModel: MemberProfileViewModel?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                if let viewModel = viewModel {
                    if viewModel.isLoading && viewModel.labs.isEmpty {
                        LoadingView("Loading profile...")
                            .padding(.top, Spacing.huge)
                    } else {
                        profileContent(viewModel)
                    }
                } else {
                    LoadingView("Loading...")
                        .padding(.top, Spacing.huge)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = MemberProfileViewModel(
                    member: member,
                    currentLabName: currentLabName,
                    labRepository: labRepository
                )
            }
            await viewModel?.loadProfile()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func profileContent(_ viewModel: MemberProfileViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            headerSection(viewModel)
            contactSection
            labsSection(viewModel)
            projectsSection(viewModel)
        }
        .padding(Spacing.base)
    }

    // MARK: - Header

    @ViewBuilder
    private func headerSection(_ viewModel: MemberProfileViewModel) -> some View {
        VStack(spacing: Spacing.sm) {
            // Large avatar
            ZStack {
                Circle()
                    .fill(avatarColor)
                    .frame(width: 80, height: 80)
                Text(member.initials)
                    .font(Typography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            // Full name (includes academic titles)
            Text(member.fullName)
                .font(Typography.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.onBackground)

            // PI badge — contextual to the lab they were viewed from
            if member.isPI {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(ColorPalette.utsa_secondary)
                    Text("PI — \(currentLabName)")
                        .font(Typography.labelSmall)
                        .foregroundColor(ColorPalette.utsa_secondary)
                }
            }

            // Summary counts
            let labCount     = viewModel.labs.count
            let projectCount = viewModel.projects.count
            Text("Member of \(labCount) lab\(labCount == 1 ? "" : "s") · \(projectCount) project\(projectCount == 1 ? "" : "s")")
                .font(Typography.bodySmall)
                .foregroundColor(ColorPalette.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Contact

    @ViewBuilder
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Email — tappable mailto link
            Button {
                if let url = URL(string: "mailto:\(member.email)") {
                    openURL(url)
                }
            } label: {
                contactRow(icon: "envelope.fill", label: "Email", value: member.email, hasAction: true)
            }
            .buttonStyle(.plain)

            // Institution (static)
            if let institution = member.institution {
                Divider()
                    .padding(.horizontal, Spacing.base)
                contactRow(icon: "building.fill", label: "Institution", value: institution)
            }
        }
        .background(ColorPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: BorderStyles.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .stroke(ColorPalette.divider, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func contactRow(icon: String, label: String, value: String, hasAction: Bool = false) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(ColorPalette.utsa_primary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(label)
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
                Text(value)
                    .font(Typography.bodyMedium)
                    .foregroundColor(ColorPalette.onSurface)
            }

            if hasAction {
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            }
        }
        .padding(Spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Labs

    @ViewBuilder
    private func labsSection(_ viewModel: MemberProfileViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Labs")
                .font(Typography.titleSmall)
                .foregroundColor(ColorPalette.onBackground)

            if viewModel.labs.isEmpty {
                Text("No lab affiliations")
                    .font(Typography.bodyMedium)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(viewModel.labs) { lab in
                        labRow(lab)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func labRow(_ lab: Lab) -> some View {
        HStack(spacing: Spacing.md) {
            // Abbreviation swatch
            ZStack {
                RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                    .fill(swatchColor(for: lab.name))
                    .frame(width: 36, height: 36)
                Text(lab.abbreviation)
                    .font(Typography.labelSmall)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            // Name + institution
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(lab.name)
                    .font(Typography.bodyMedium)
                    .foregroundColor(ColorPalette.onSurface)
                if let institution = lab.institution {
                    Text(institution)
                        .font(Typography.labelSmall)
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }
            }

            Spacer()

            // Member count
            Label("\(lab.memberCount)", systemImage: "person.2.fill")
                .font(Typography.labelSmall)
                .foregroundColor(ColorPalette.onSurfaceVariant)
        }
        .padding(Spacing.base)
        .background(ColorPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: BorderStyles.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .stroke(ColorPalette.divider, lineWidth: 1)
        )
    }

    // MARK: - Projects

    @ViewBuilder
    private func projectsSection(_ viewModel: MemberProfileViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Projects")
                .font(Typography.titleSmall)
                .foregroundColor(ColorPalette.onBackground)

            if viewModel.projects.isEmpty {
                Text("No projects in affiliated labs")
                    .font(Typography.bodyMedium)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(viewModel.projects) { project in
                        projectRow(project)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func projectRow(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(project.title)
                        .font(Typography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorPalette.onSurface)
                    if !project.description.isEmpty {
                        Text(project.description)
                            .font(Typography.labelSmall)
                            .foregroundColor(ColorPalette.onSurfaceVariant)
                            .lineLimit(1)
                    }
                }
                Spacer()
                statusPill(project.status)
            }

            // Lab affiliation chips
            if !project.labAffiliations.isEmpty {
                HStack(spacing: Spacing.xs) {
                    ForEach(project.labAffiliations) { affiliation in
                        Text(affiliation.name)
                            .font(.system(size: 9))
                            .foregroundColor(ColorPalette.onSurfaceVariant)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ColorPalette.divider)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(Spacing.base)
        .background(ColorPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: BorderStyles.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .stroke(ColorPalette.divider, lineWidth: 1)
        )
    }

    // MARK: - Status Pill

    @ViewBuilder
    private func statusPill(_ status: ProjectStatus) -> some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(statusColor(status))
                .frame(width: 7, height: 7)
            Text(statusLabel(status))
                .font(Typography.labelSmall)
                .foregroundColor(ColorPalette.onSurfaceVariant)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 3)
        .background(statusColor(status).opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Helpers

    private var avatarColor: Color {
        swatchColor(for: member.fullName)
    }

    /// Deterministic color from a string — same palette used across avatars and lab swatches.
    private func swatchColor(for name: String) -> Color {
        let palette: [Color] = [
            ColorPalette.utsa_primary,
            ColorPalette.success,
            ColorPalette.chart_purple,
            ColorPalette.chart_orange,
            ColorPalette.chart_red
        ]
        return palette[abs(name.hashValue) % palette.count]
    }

    private func statusColor(_ status: ProjectStatus) -> Color {
        switch status {
        case .active:    return ColorPalette.success
        case .planning:  return ColorPalette.utsa_primary
        case .onHold:    return ColorPalette.chart_orange
        case .completed: return ColorPalette.chart_purple
        case .archived:  return ColorPalette.onSurfaceVariant
        }
    }

    private func statusLabel(_ status: ProjectStatus) -> String {
        switch status {
        case .active:    return "Active"
        case .planning:  return "Planning"
        case .onHold:    return "On Hold"
        case .completed: return "Completed"
        case .archived:  return "Archived"
        }
    }
}
