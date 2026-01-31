import SwiftUI

struct ProjectDetailView: View {
    let projectId: UUID
    @Environment(ServiceContainer.self) private var services
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ProjectDetailViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let project = vm.project {
                    projectContent(project, vm)
                } else if vm.showError {
                    errorView(vm.errorMessage)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(viewModel?.project?.name ?? "Project")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    NavigationLink(value: ProjectDestination.edit(projectId)) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { viewModel?.showDeleteConfirmation = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "Delete Project?",
            isPresented: Binding(get: { viewModel?.showDeleteConfirmation ?? false }, set: { viewModel?.showDeleteConfirmation = $0 }),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    if let vm = viewModel, await vm.deleteProject() {
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All samples and captures in this project will be deleted.")
        }
        .task {
            viewModel = ProjectDetailViewModel(repository: services.projectRepository)
            await viewModel?.loadProject(id: projectId)
        }
    }

    // MARK: - Project Content

    private func projectContent(_ project: Project, _ vm: ProjectDetailViewModel) -> some View {
        List {
            // Stats grid
            Section {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    statCard(
                        icon: "beaker.fill",
                        label: "Samples",
                        value: "\(project.sampleIds.count)"
                    )
                    statCard(
                        icon: "circle.fill",
                        label: "Status",
                        value: project.status.displayName
                    )
                    statCard(
                        icon: "calendar",
                        label: "Created",
                        value: project.createdAt.formatted(date: .abbreviated, time: .omitted)
                    )
                    statCard(
                        icon: "person.2.fill",
                        label: "Members",
                        value: "\(project.collaboratorIds.count + 1)"
                    )
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }

            // Description
            if !project.description.isEmpty {
                Section(header: Text("Description")) {
                    Text(project.description)
                        .foregroundStyle(ColorPalette.onSurface)
                }
            }

            // Samples placeholder
            Section(header: Text("Samples")) {
                Text("No samples yet — add samples to begin analysis")
                    .foregroundStyle(ColorPalette.onSurfaceVariant)
                    .font(.subheadline)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Stat Card

    private func statCard(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(ColorPalette.utsa_primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(ColorPalette.onSurfaceVariant)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(ColorPalette.onSurface)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(ColorPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(ColorPalette.error)
            Text(message)
                .foregroundStyle(ColorPalette.onSurface)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
