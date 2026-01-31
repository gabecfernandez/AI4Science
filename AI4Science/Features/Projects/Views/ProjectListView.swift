import SwiftUI

struct ProjectListView: View {
    @Environment(ServiceContainer.self) private var services
    @State private var viewModel: ProjectsViewModel?
    @State private var localSearchText = ""

    private let statusFilters: [ProjectStatus?] = [nil, .draft, .active, .paused, .completed, .archived]

    var body: some View {
        List {
            if let vm = viewModel {
                statusFilterBar(vm)

                if vm.filteredProjects.isEmpty {
                    emptyState(vm)
                } else {
                    ForEach(vm.filteredProjects) { project in
                        NavigationLink(value: ProjectDestination.detail(project.id)) {
                            projectCard(project)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Projects")
        .searchable(text: $localSearchText, placement: .navigationBarTrailing, prompt: "Search projects…")
        .task(id: localSearchText) {
            if localSearchText.isEmpty {
                viewModel?.searchText = ""
            } else {
                do {
                    try await Task.sleep(for: .milliseconds(300))
                    viewModel?.searchText = localSearchText
                } catch {
                    // Task cancelled — ignore
                }
            }
        }
        .task {
            viewModel = ProjectsViewModel(repository: services.projectRepository)
            await viewModel?.loadProjects()
        }
        .refreshable {
            await viewModel?.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: ProjectDestination.newProject) {
                    Image(systemName: "plus")
                }
            }
        }
    }

    // MARK: - Status Filter Bar

    private func statusFilterBar(_ vm: ProjectsViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(statusFilters, id: \.self) { status in
                    let isSelected = vm.filterStatus == status
                    Button(action: { vm.filterStatus = status }) {
                        Text(status?.displayName ?? "All")
                            .font(.caption)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? ColorPalette.utsa_primary : ColorPalette.surfaceVariant)
                            .foregroundStyle(isSelected ? Color.white : ColorPalette.onSurface)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    // MARK: - Project Card

    private func projectCard(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.name)
                    .font(.headline)
                    .foregroundStyle(ColorPalette.onSurface)
                Spacer()
                statusBadge(project.status)
            }

            if !project.description.isEmpty {
                Text(project.description)
                    .font(.subheadline)
                    .foregroundStyle(ColorPalette.onSurfaceVariant)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                Label("\(project.sampleCount)", systemImage: "beaker.fill")
                    .font(.caption)
                    .foregroundStyle(ColorPalette.utsa_primary)
                Label(project.createdAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(ColorPalette.onSurfaceVariant)
            }
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(_ status: ProjectStatus) -> some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background((status.color ?? ColorPalette.neutral_500).opacity(0.15))
            .foregroundStyle(status.color ?? ColorPalette.neutral_500)
            .clipShape(Capsule())
    }

    // MARK: - Empty State

    private func emptyState(_ vm: ProjectsViewModel) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(ColorPalette.onSurfaceVariant)

            Text("No Projects")
                .font(.headline)
                .foregroundStyle(ColorPalette.onBackground)

            Text("Create a new project to get started")
                .font(.subheadline)
                .foregroundStyle(ColorPalette.onSurfaceVariant)

            NavigationLink(value: ProjectDestination.newProject) {
                Text("Create Project")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .foregroundStyle(ColorPalette.utsa_primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(ColorPalette.utsa_primary, lineWidth: 1)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
