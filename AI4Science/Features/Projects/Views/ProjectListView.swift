import SwiftUI

struct ProjectListView: View {
    @State private var viewModel = ProjectListViewModel()
    @State private var showCreateProject = false
    @State private var selectedProject: Project?
    @State private var searchText = ""

    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return viewModel.projects
        }
        return viewModel.projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.09, green: 0.17, blue: 0.26),
                        Color(red: 0.12, green: 0.20, blue: 0.30)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Projects")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)

                                Text("\(viewModel.projects.count) projects")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Spacer()

                            Button(action: { showCreateProject = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Search bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.5))

                            TextField("Search projects...", text: $searchText)
                                .textInputAutocapitalization(.words)
                                .foregroundColor(.white)

                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 16)

                    // Projects list
                    if filteredProjects.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()

                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.3))

                            Text("No Projects")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("Create a new project to get started")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))

                            Button(action: { showCreateProject = true }) {
                                Text("Create Project")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                            }
                            .foregroundColor(.blue)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.blue, lineWidth: 1)
                            )

                            Spacer()
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(filteredProjects) { project in
                                    NavigationLink(value: project) {
                                        ProjectCard(project: project)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationDestination(for: Project.self) { project in
                ProjectDetailView(project: project)
            }
            .sheet(isPresented: $showCreateProject) {
                ProjectCreateView(isPresented: $showCreateProject) { newProject in
                    viewModel.projects.append(newProject)
                }
            }
            .task {
                await viewModel.loadProjects()
            }
        }
    }
}

struct ProjectCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(project.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Label("\(project.sampleCount)", systemImage: "beaker.fill")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text(project.status.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(project.status))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }

            HStack(spacing: 16) {
                Label("\(project.memberCount) members", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                Label(project.createdDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                Spacer()
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func statusColor(_ status: Project.Status) -> Color {
        switch status {
        case .active:
            return Color.green.opacity(0.3)
        case .paused:
            return Color.orange.opacity(0.3)
        case .completed:
            return Color.blue.opacity(0.3)
        }
    }
}

#Preview {
    ProjectListView()
}
