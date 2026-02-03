import SwiftUI

struct MyLabsView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(AppState.self) private var appState
    @State private var viewModel: MyLabsViewModel?

    var body: some View {
        ZStack {
            ColorPalette.background
                .ignoresSafeArea()

            if let viewModel = viewModel {
                labsContent(viewModel)
            } else {
                LoadingView("Loading labs...")
            }
        }
        .navigationTitle("Labs")
        .task {
            if viewModel == nil {
                viewModel = MyLabsViewModel(
                    labRepository: services.labRepository,
                    userId: appState.currentUser?.id.uuidString
                )
            }
            await viewModel?.loadLabs()
        }
    }

    @ViewBuilder
    private func labsContent(_ viewModel: MyLabsViewModel) -> some View {
        if viewModel.isLoading && viewModel.myLabs.isEmpty && viewModel.exploreLabs.isEmpty {
            LoadingView("Loading labs...")
        } else if viewModel.myLabs.isEmpty && viewModel.exploreLabs.isEmpty {
            EmptyStateView(
                icon: Image(systemName: "building.2"),
                title: "No Labs Yet",
                message: "No labs are available. Contact a lab administrator to get started."
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // My Labs section
                    if !viewModel.myLabs.isEmpty {
                        myLabsSection(viewModel)
                    }

                    // Explore section
                    if !viewModel.exploreLabs.isEmpty {
                        exploreSection(viewModel)
                    }
                }
                .padding(.horizontal, Spacing.base)
                .padding(.vertical, Spacing.md)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    // MARK: - My Labs Section

    @ViewBuilder
    private func myLabsSection(_ viewModel: MyLabsViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("My Labs")
                .font(Typography.titleSmall)
                .foregroundColor(ColorPalette.onBackground)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                ForEach(viewModel.myLabs) { lab in
                    NavigationLink(value: LabDestination.detail(lab.id)) {
                        LabGridCard(lab: lab)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Explore Section

    @ViewBuilder
    private func exploreSection(_ viewModel: MyLabsViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Explore")
                .font(Typography.titleSmall)
                .foregroundColor(ColorPalette.onBackground)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                ForEach(viewModel.exploreLabs) { lab in
                    NavigationLink(value: LabDestination.detail(lab.id)) {
                        LabGridCard(lab: lab, onJoin: { await viewModel.joinLab(lab.id) })
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Lab Card

private struct LabGridCard: View {
    let lab: Lab
    /// When non-nil a "Join" pill is rendered at the trailing end of the stats row.
    var onJoin: (() async -> Void)?

    /// Deterministic color from lab name
    private var cardColor: Color {
        let palette: [Color] = [
            ColorPalette.utsa_primary,
            ColorPalette.success,
            ColorPalette.chart_purple,
            ColorPalette.chart_orange,
            ColorPalette.chart_red
        ]
        let index = abs(lab.name.hashValue) % palette.count
        return palette[index]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Color swatch with abbreviation
            ZStack {
                RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                    .fill(cardColor)
                    .frame(width: 44, height: 44)

                Text(lab.abbreviation)
                    .font(Typography.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            // Lab name
            Text(lab.name)
                .font(Typography.titleSmall)
                .foregroundColor(ColorPalette.onSurface)
                .lineLimit(2)

            // Institution
            if let institution = lab.institution {
                Text(institution)
                    .font(Typography.bodySmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            }

            // Stats row
            HStack(spacing: Spacing.md) {
                Label("\(lab.projectCount)", systemImage: "folder.fill")
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)

                Label("\(lab.memberCount)", systemImage: "person.2.fill")
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            }

            // Join row — always present so all cards share the same height
            HStack {
                Spacer()
                if let onJoin = onJoin {
                    Button {
                        Task { await onJoin() }
                    } label: {
                        Text("Join")
                            .font(Typography.labelSmall)
                            .foregroundColor(ColorPalette.utsa_primary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xs)
                            .cornerRadius(BorderStyles.radiusCircle)
                            .overlay(
                                RoundedRectangle(cornerRadius: BorderStyles.radiusCircle)
                                    .stroke(ColorPalette.utsa_primary, lineWidth: 1)
                            )
                    }
                }
            }
            .frame(minHeight: 28)
        }
        .padding(Spacing.base)
        .background(ColorPalette.surface)
        .cornerRadius(BorderStyles.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .stroke(ColorPalette.divider, lineWidth: 1)
        )
        .shadow(Shadows.small)
        .contentShape(.rect)
    }
}

#Preview {
    MyLabsView()
}
