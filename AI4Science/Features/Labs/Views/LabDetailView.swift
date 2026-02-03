import SwiftUI

struct LabDetailView: View {
    let labId: String
    let labRepository: LabRepository
    let projectRepository: ProjectRepository

    @State private var viewModel: LabDetailViewModel?
    @State private var showIdeaSheet = false
    @State private var selectedMember: LabMember?

    /// Deterministic color from lab name
    private func cardColor(for name: String) -> Color {
        let palette: [Color] = [
            ColorPalette.utsa_primary,
            ColorPalette.success,
            ColorPalette.chart_purple,
            ColorPalette.chart_orange,
            ColorPalette.chart_red
        ]
        let index = abs(name.hashValue) % palette.count
        return palette[index]
    }

    var body: some View {
        ZStack {
            ColorPalette.background
                .ignoresSafeArea()

            if let viewModel = viewModel {
                if viewModel.isLoading && viewModel.lab == nil {
                    LoadingView("Loading lab...")
                } else if let lab = viewModel.lab {
                    labContent(lab: lab, viewModel: viewModel)
                } else {
                    EmptyStateView(
                        icon: Image(systemName: "building.2"),
                        title: "Lab Not Found",
                        message: "This lab could not be loaded."
                    )
                }
            } else {
                LoadingView("Loading...")
            }
        }
        .navigationTitle("Lab")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = LabDetailViewModel(
                    labRepository: labRepository,
                    projectRepository: projectRepository,
                    labId: labId
                )
            }
            await viewModel?.loadLab()
        }
    }

    // MARK: - Lab Content

    @ViewBuilder
    private func labContent(lab: Lab, viewModel: LabDetailViewModel) -> some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    headerSection(lab: lab)

                    Divider()
                        .background(ColorPalette.divider)

                    membersSection(viewModel: viewModel)

                    Divider()
                        .background(ColorPalette.divider)

                    activeProjectsSection(viewModel: viewModel)

                    if !viewModel.pastProjects.isEmpty {
                        Divider()
                            .background(ColorPalette.divider)

                        pastProjectsSection(viewModel: viewModel)
                    }
                }
                .padding(.horizontal, Spacing.base)
                .padding(.vertical, Spacing.md)
                .padding(.bottom, 72)   // clearance for floating action button
            }
            .refreshable {
                await viewModel.refresh()
            }

            // Floating action button — sits above the scroll content
            submitIdeaButton()
        }
        .sheet(isPresented: $showIdeaSheet) {
            IdeaSubmissionView(labName: lab.name)
        }
        .sheet(item: $selectedMember) { member in
            MemberProfileView(
                member: member,
                currentLabName: lab.name,
                labRepository: labRepository
            )
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func headerSection(lab: Lab) -> some View {
        VStack(spacing: Spacing.md) {
            // Large color swatch with abbreviation
            ZStack {
                RoundedRectangle(cornerRadius: BorderStyles.radiusLarge)
                    .fill(cardColor(for: lab.name))
                    .frame(width: 64, height: 64)

                Text(lab.abbreviation)
                    .font(Typography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            // Lab name
            Text(lab.name)
                .font(Typography.titleLarge)
                .foregroundColor(ColorPalette.onBackground)

            // Institution
            if let institution = lab.institution {
                Text(institution)
                    .font(Typography.bodyMedium)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            }

            // Stats badges
            HStack(spacing: Spacing.lg) {
                Label("\(lab.memberCount) members", systemImage: "person.2.fill")
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)

                Label("\(lab.projectCount) projects", systemImage: "folder.fill")
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Members Carousel

    @ViewBuilder
    private func membersSection(viewModel: LabDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Members")
                .font(Typography.titleSmall)
                .foregroundColor(ColorPalette.onBackground)

            if viewModel.members.isEmpty {
                Text("No members listed")
                    .font(Typography.bodyMedium)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.lg) {
                        ForEach(viewModel.members) { member in
                            Button {
                                selectedMember = member
                            } label: {
                                MemberAvatar(member: member)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
        }
    }

    // MARK: - Active Projects

    @ViewBuilder
    private func activeProjectsSection(viewModel: LabDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Active Projects")
                    .font(Typography.titleSmall)
                    .foregroundColor(ColorPalette.onBackground)

                Text("(\(viewModel.activeProjects.count))")
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            }

            if viewModel.activeProjects.isEmpty {
                Text("No active projects in this lab")
                    .font(Typography.bodyMedium)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
                    .padding(.vertical, Spacing.md)
            } else {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(viewModel.activeProjects) { project in
                        NavigationLink(value: LabDestination.project(project.id)) {
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
            }
        }
    }

    // MARK: - Past Projects

    @ViewBuilder
    private func pastProjectsSection(viewModel: LabDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Past Projects")
                    .font(Typography.titleSmall)
                    .foregroundColor(ColorPalette.onBackground)

                Text("(\(viewModel.pastProjects.count))")
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            }

            LazyVStack(spacing: Spacing.md) {
                ForEach(viewModel.pastProjects) { project in
                    NavigationLink(value: LabDestination.project(project.id)) {
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
        }
    }

    // MARK: - Floating Action Button

    @ViewBuilder
    private func submitIdeaButton() -> some View {
        Button {
            showIdeaSheet = true
        } label: {
            Label("Submit an Idea", systemImage: "lightbulb.fill")
                .font(Typography.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(ColorPalette.utsa_primary)
                .clipShape(Capsule())
                .shadow(color: ColorPalette.utsa_primary.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .padding(.bottom, Spacing.xl)
    }
}

// MARK: - Member Avatar

private struct MemberAvatar: View {
    let member: LabMember

    private var avatarColor: Color {
        let palette: [Color] = [
            ColorPalette.utsa_primary,
            ColorPalette.success,
            ColorPalette.chart_purple,
            ColorPalette.chart_orange,
            ColorPalette.chart_red
        ]
        return palette[abs(member.fullName.hashValue) % palette.count]
    }

    /// First name with academic titles stripped
    private var displayName: String {
        let titles: Set<String> = ["Dr.", "Prof.", "Dr", "Prof"]
        let parts = member.fullName.split(separator: " ").map(String.init)
        let filtered = parts.filter { !titles.contains($0) }
        return filtered.first ?? parts.first ?? "?"
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                // PI ring — drawn behind the avatar so the gap is visible
                if member.isPI {
                    Circle()
                        .stroke(ColorPalette.utsa_secondary, lineWidth: 3)
                        .frame(width: 56, height: 56)
                }

                // Avatar circle
                Circle()
                    .fill(avatarColor)
                    .frame(width: 48, height: 48)

                // Initials
                Text(member.initials)
                    .font(Typography.titleSmall)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 56, height: 56) // consistent size for alignment

            // Name
            Text(displayName)
                .font(Typography.labelSmall)
                .foregroundColor(ColorPalette.onSurface)
                .lineLimit(1)

            // PI indicator — placeholder keeps non-PI items the same height
            if member.isPI {
                Text("PI")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(ColorPalette.utsa_secondary)
            } else {
                Color.clear.frame(height: 14)
            }
        }
        .frame(width: 68)
    }
}

// MARK: - Idea Submission Sheet

private struct IdeaSubmissionView: View {
    let labName: String
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var description = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Idea") {
                    TextField("Title", text: $title)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                        if description.isEmpty {
                            Text("Describe your idea...")
                                .foregroundColor(ColorPalette.onSurfaceVariant)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                    }
                }

                Section {
                    Text("Your idea will be submitted to \(labName) for review by the lab team.")
                        .font(Typography.bodySmall)
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }
            }
            .navigationTitle("Submit an Idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        // Placeholder: idea submission would be persisted / sent here
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
