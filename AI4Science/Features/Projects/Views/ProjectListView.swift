import SwiftUI

struct ProjectListView: View {
    @Environment(ServiceContainer.self) private var services
    @State private var viewModel: ProjectsListViewModel?
    @State private var showCreateProject = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                ColorPalette.background
                    .ignoresSafeArea()

                if let viewModel = viewModel {
                    projectContent(viewModel)
                } else {
                    LoadingView( "Loading...")
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateProject = true
                    } label: {
                        IconAssets.addCircle
                            .font(.system(size: 22))
                            .foregroundColor(ColorPalette.utsa_primary)
                    }
                }
            }
            .sheet(isPresented: $showCreateProject) {
                if let services = services as ServiceContainer? {
                    ProjectCreateView(
                        repository: services.projectRepository,
                        isPresented: $showCreateProject
                    ) {
                        Task { await viewModel?.refresh() }
                    }
                }
            }
            .task {
                if viewModel == nil {
                    viewModel = ProjectsListViewModel(repository: services.projectRepository)
                }
                await viewModel?.loadProjects()
            }
        }
    }

    @ViewBuilder
    private func projectContent(_ viewModel: ProjectsListViewModel) -> some View {
        VStack(spacing: 0) {
            // Header with search and filter
            headerSection(viewModel)

            // Content
            if viewModel.isLoading && viewModel.projects.isEmpty {
                Spacer()
                LoadingView( "Loading projects...")
                Spacer()
            } else if viewModel.isEmpty {
                emptyStateView
            } else if viewModel.isFilteredEmpty {
                filteredEmptyView
            } else {
                projectsList(viewModel)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private func headerSection(_ viewModel: ProjectsListViewModel) -> some View {
        VStack(spacing: Spacing.md) {
            // Search bar
            SearchBar(
                placeholder: "Search projects...",
                text: Binding(
                    get: { viewModel.searchText },
                    set: { viewModel.searchText = $0 }
                )
            )

            // Status filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(ProjectStatusFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isSelected: viewModel.selectedStatus == filter
                        ) {
                            viewModel.selectedStatus = filter
                        }
                    }
                }
            }

            // Project count
            HStack {
                Text("\(viewModel.projectCount) project\(viewModel.projectCount == 1 ? "" : "s")")
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
                Spacer()
            }
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.md)
        .background(ColorPalette.surface)
    }

    @ViewBuilder
    private func projectsList(_ viewModel: ProjectsListViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(viewModel.filteredProjects) { project in
                    NavigationLink(value: project.id) {
                        ProjectListCard(
                            project: project,
                            onDelete: {
                                Task { await viewModel.deleteProject(project.id) }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.md)
        }
        .navigationDestination(for: UUID.self) { projectId in
            ProjectDetailView(
                projectId: projectId,
                repository: services.projectRepository
            )
        }
    }

    private var emptyStateView: some View {
        EmptyStateView(
            icon: IconAssets.projects,
            title: "No Projects Yet",
            message: "Create your first project to get started with AI4Science",
            action: ("Create Project", { showCreateProject = true })
        )
    }

    private var filteredEmptyView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            IconAssets.search
                .font(.system(size: 48))
                .foregroundColor(ColorPalette.onSurfaceVariant)

            Text("No matching projects")
                .font(Typography.titleMedium)
                .foregroundColor(ColorPalette.onBackground)

            Text("Try adjusting your search or filter")
                .font(Typography.bodyMedium)
                .foregroundColor(ColorPalette.onSurfaceVariant)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
    }
}

// MARK: - Project List Card

struct ProjectListCard: View {
    let project: Project
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(project.title)
                        .font(Typography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorPalette.onSurface)
                        .lineLimit(1)

                    if !project.description.isEmpty {
                        Text(project.description)
                            .font(Typography.bodySmall)
                            .foregroundColor(ColorPalette.onSurfaceVariant)
                            .lineLimit(2)
                    }
                }

                Spacer()

                ProjectStatusBadge(status: project.status)
            }

            HStack(spacing: Spacing.lg) {
                Label("\(project.sampleCount)", systemImage: "flask.fill")
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)

                Label("\(project.participantCount)", systemImage: "person.2.fill")
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)

                Spacer()

                Text(formatDate(project.updatedAt))
                    .font(Typography.labelSmall)
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
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.labelMedium)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : ColorPalette.onSurfaceVariant)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? ColorPalette.utsa_primary : ColorPalette.surface)
                .cornerRadius(Spacing.radiusCircle)
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.radiusCircle)
                        .stroke(
                            isSelected ? ColorPalette.utsa_primary : ColorPalette.divider,
                            lineWidth: 1
                        )
                )
        }
    }
}

#Preview {
    ProjectListView()
}
