import SwiftUI

struct ProjectDetailView: View {
    let projectId: UUID
    let repository: ProjectRepository

    @State private var viewModel: ProjectDetailViewModel?
    @State private var selectedTab: ProjectDetailTab = .overview
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) var dismiss

    enum ProjectDetailTab: String, CaseIterable {
        case overview = "Overview"
        case samples = "Samples"
        case settings = "Settings"
    }

    init(projectId: UUID, repository: ProjectRepository) {
        self.projectId = projectId
        self.repository = repository
    }

    var body: some View {
        ZStack {
            ColorPalette.background
                .ignoresSafeArea()

            if let viewModel = viewModel {
                if viewModel.isLoading && viewModel.project == nil {
                    LoadingView(message: "Loading project...")
                } else if let project = viewModel.project {
                    projectContent(project: project, viewModel: viewModel)
                } else {
                    errorView(viewModel)
                }
            } else {
                LoadingView(message: "Loading...")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let project = viewModel?.project {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(project.title)
                            .font(Typography.titleMedium)
                            .fontWeight(.semibold)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        IconAssets.menu
                            .foregroundColor(ColorPalette.onBackground)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let project = viewModel?.project {
                ProjectEditView(
                    project: project,
                    repository: repository,
                    isPresented: $showEditSheet
                ) {
                    Task { await viewModel?.refresh() }
                }
            }
        }
        .alert("Delete Project?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel?.deleteProject()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this project? This action cannot be undone.")
        }
        .task {
            if viewModel == nil {
                viewModel = ProjectDetailViewModel(projectId: projectId, repository: repository)
            }
            await viewModel?.loadProject()
        }
    }

    @ViewBuilder
    private func projectContent(project: Project, viewModel: ProjectDetailViewModel) -> some View {
        VStack(spacing: 0) {
            // Header
            headerSection(project: project)

            // Tab selector
            tabSelector

            // Content
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    switch selectedTab {
                    case .overview:
                        overviewContent(project: project, viewModel: viewModel)
                    case .samples:
                        samplesContent(project: project)
                    case .settings:
                        settingsContent(project: project, viewModel: viewModel)
                    }
                }
                .padding(Spacing.base)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    @ViewBuilder
    private func headerSection(project: Project) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                ProjectStatusBadge(status: project.status)
                Spacer()
            }

            if !project.description.isEmpty {
                Text(project.description)
                    .font(Typography.bodyMedium)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
                    .lineLimit(3)
            }

            HStack(spacing: Spacing.lg) {
                Label(
                    "Started \(project.startDate.formatted(date: .abbreviated, time: .omitted))",
                    systemImage: "calendar"
                )
                .font(Typography.labelSmall)
                .foregroundColor(ColorPalette.onSurfaceVariant)

                if !project.tags.isEmpty {
                    Label("\(project.tags.count) tags", systemImage: "tag")
                        .font(Typography.labelSmall)
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }
            }
        }
        .padding(Spacing.base)
        .background(ColorPalette.surface)
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ProjectDetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: Spacing.xs) {
                        Text(tab.rawValue)
                            .font(Typography.labelMedium)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? ColorPalette.utsa_primary : ColorPalette.onSurfaceVariant)

                        Rectangle()
                            .fill(selectedTab == tab ? ColorPalette.utsa_primary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Spacing.base)
        .background(ColorPalette.surface)
    }

    @ViewBuilder
    private func overviewContent(project: Project, viewModel: ProjectDetailViewModel) -> some View {
        VStack(spacing: Spacing.lg) {
            // Statistics
            ProjectStatisticsGrid(
                sampleCount: project.sampleCount,
                participantCount: project.participantCount,
                startDate: project.startDate,
                lastUpdated: project.updatedAt
            )

            // Tags
            if !project.tags.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Tags")
                        .font(Typography.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorPalette.onBackground)

                    FlowLayout(spacing: Spacing.sm) {
                        ForEach(project.tags, id: \.self) { tag in
                            TagChip(text: tag)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Quick Actions
            VStack(spacing: Spacing.md) {
                PrimaryButton("Add Sample") {
                    // Navigate to sample capture
                }

                SecondaryButton("Invite Participant") {
                    // Show invite sheet
                }
            }
        }
    }

    @ViewBuilder
    private func samplesContent(project: Project) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Samples")
                .font(Typography.titleSmall)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.onBackground)

            if project.sampleCount == 0 {
                EmptyStateView(
                    icon: IconAssets.flask,
                    title: "No Samples Yet",
                    message: "Start capturing samples for this project",
                    action: ("Add Sample", {})
                )
            } else {
                Text("Sample list placeholder - \(project.sampleCount) samples")
                    .font(Typography.bodyMedium)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            }
        }
    }

    @ViewBuilder
    private func settingsContent(project: Project, viewModel: ProjectDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Project Info
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Project Information")
                    .font(Typography.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorPalette.onBackground)

                SettingsRow(label: "Title", value: project.title)
                SettingsRow(label: "Status", value: viewModel.statusDisplayName)
                SettingsRow(label: "Created", value: viewModel.formattedCreatedDate)
                SettingsRow(label: "Last Updated", value: viewModel.formattedUpdatedDate)
            }

            Divider()
                .background(ColorPalette.divider)

            // Status Actions
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Status Actions")
                    .font(Typography.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorPalette.onBackground)

                if viewModel.isArchived {
                    SecondaryButton("Unarchive Project") {
                        Task { await viewModel.unarchiveProject() }
                    }
                } else {
                    SecondaryButton("Archive Project") {
                        Task { await viewModel.archiveProject() }
                    }
                }
            }

            Divider()
                .background(ColorPalette.divider)

            // Danger Zone
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Danger Zone")
                    .font(Typography.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorPalette.error)

                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        IconAssets.delete
                        Text("Delete Project")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.md)
                    .background(ColorPalette.error.opacity(0.1))
                    .foregroundColor(ColorPalette.error)
                    .cornerRadius(BorderStyles.radiusMedium)
                }
            }
        }
    }

    @ViewBuilder
    private func errorView(_ viewModel: ProjectDetailViewModel) -> some View {
        VStack(spacing: Spacing.lg) {
            IconAssets.error
                .font(.system(size: 48))
                .foregroundColor(ColorPalette.error)

            Text("Failed to load project")
                .font(Typography.titleMedium)
                .foregroundColor(ColorPalette.onBackground)

            if let message = viewModel.errorMessage {
                Text(message)
                    .font(Typography.bodyMedium)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            }

            PrimaryButton("Try Again") {
                Task { await viewModel.loadProject() }
            }
        }
        .padding(Spacing.lg)
    }
}

// MARK: - Supporting Views

struct SettingsRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(Typography.bodyMedium)
                .foregroundColor(ColorPalette.onSurfaceVariant)

            Spacer()

            Text(value)
                .font(Typography.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(ColorPalette.onBackground)
        }
        .padding(.vertical, Spacing.sm)
    }
}

struct TagChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Typography.labelSmall)
            .foregroundColor(ColorPalette.utsa_primary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(ColorPalette.utsa_primary.opacity(0.1))
            .cornerRadius(Spacing.radiusSmall)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                if x + subviewSize.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, subviewSize.height)
                x += subviewSize.width + spacing
            }
            size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(
            projectId: UUID(),
            repository: ProjectRepositoryFactory.makeRepository(
                modelContainer: try! ModelContainer(for: ProjectEntity.self)
            )
        )
    }
}
