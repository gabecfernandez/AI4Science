import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @State private var viewModel = ProjectDetailViewModel()
    @State private var selectedTab: ProjectDetailTab = .overview
    @Environment(\.dismiss) var dismiss

    enum ProjectDetailTab {
        case overview
        case samples
        case settings
    }

    var body: some View {
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
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(project.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                Label(project.status.rawValue, systemImage: "circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))

                                Label(project.createdDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }

                        Spacer()

                        Menu {
                            Button(action: {}) {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button(action: {}) {
                                Label("Export", systemImage: "arrow.up.doc")
                            }

                            Button(action: {}) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }

                            Divider()

                            Button(role: .destructive, action: {}) {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 20)

                    // Tab selector
                    HStack(spacing: 0) {
                        ForEach([ProjectDetailTab.overview, .samples, .settings], id: \.self) { tab in
                            VStack(spacing: 4) {
                                Text(tabTitle(tab))
                                    .font(.subheadline)
                                    .fontWeight(selectedTab == tab ? .semibold : .regular)
                                    .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))

                                if selectedTab == tab {
                                    Capsule()
                                        .fill(Color.blue)
                                        .frame(height: 3)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedTab = tab }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .padding(.vertical, 16)

                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case .overview:
                            ProjectOverviewContent(project: project)
                        case .samples:
                            ProjectSamplesContent(project: project)
                        case .settings:
                            ProjectSettingsContent(project: project)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .task {
            await viewModel.loadProjectDetails(for: project.id)
        }
    }

    private func tabTitle(_ tab: ProjectDetailTab) -> String {
        switch tab {
        case .overview:
            return "Overview"
        case .samples:
            return "Samples"
        case .settings:
            return "Settings"
        }
    }
}

struct ProjectOverviewContent: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(.white)

                Text(project.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Stats
            VStack(spacing: 12) {
                StatRow(label: "Total Samples", value: "\(project.sampleCount)", icon: "beaker.fill")
                StatRow(label: "Team Members", value: "\(project.memberCount)", icon: "person.2.fill")
                StatRow(label: "Created Date", value: project.createdDate.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                StatRow(label: "Last Updated", value: Date().formatted(date: .abbreviated, time: .omitted), icon: "clock.fill")
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Quick actions
            VStack(spacing: 10) {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Sample")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button(action: {}) {
                    HStack {
                        Image(systemName: "person.badge.plus.fill")
                        Text("Invite Member")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .background(Color.white.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
        }
    }
}

struct ProjectSamplesContent: View {
    let project: Project

    var body: some View {
        VStack(spacing: 16) {
            Text("Samples in this project")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            if project.sampleCount > 0 {
                ForEach(0..<min(3, project.sampleCount), id: \.self) { index in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sample \(index + 1)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)

                            Text("Added \(Date().formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                }
            } else {
                Text("No samples yet")
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

struct ProjectSettingsContent: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Project Settings")
                .font(.headline)
                .foregroundColor(.white)

            SettingRow(label: "Project Name", value: project.name)
            SettingRow(label: "Status", value: project.status.rawValue)
            SettingRow(label: "Members", value: "\(project.memberCount)")

            Divider()
                .background(Color.white.opacity(0.1))

            Button(role: .destructive, action: {}) {
                Text("Delete Project")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .background(Color.red.opacity(0.2))
            .foregroundColor(.red)
            .cornerRadius(8)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }

            Spacer()
        }
    }
}

struct SettingRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct Project: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let status: Status
    let sampleCount: Int
    let memberCount: Int
    let createdDate: Date

    enum Status: String {
        case active = "Active"
        case paused = "Paused"
        case completed = "Completed"
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(project: Project(
            id: "1",
            name: "Sample Project",
            description: "A test project for demonstration",
            status: .active,
            sampleCount: 10,
            memberCount: 3,
            createdDate: Date()
        ))
    }
}
