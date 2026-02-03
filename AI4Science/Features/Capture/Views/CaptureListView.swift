//
//  CaptureListView.swift
//  AI4Science
//
//  Main view for the Capture tab showing all captures
//

import SwiftUI

struct CaptureListView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(NavigationCoordinator.self) private var navigation
    @State private var viewModel: CaptureListViewModel?

    var body: some View {
        ZStack {
            ColorPalette.background
                .ignoresSafeArea()

            if let viewModel = viewModel {
                captureContent(viewModel)
            } else {
                LoadingView("Loading captures...")
            }
        }
        .navigationTitle("Captures")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    navigation.showCamera()
                } label: {
                    IconAssets.addCircle
                        .font(.system(size: 22))
                        .foregroundColor(ColorPalette.utsa_primary)
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = CaptureListViewModel(captureRepository: services.captureRepository)
            }
            await viewModel?.loadCaptures()
        }
    }

    @ViewBuilder
    private func captureContent(_ viewModel: CaptureListViewModel) -> some View {
        VStack(spacing: 0) {
            // Header with search and filters
            headerSection(viewModel)

            // Content
            if viewModel.isLoading && viewModel.captures.isEmpty {
                Spacer()
                LoadingView("Loading captures...")
                Spacer()
            } else if viewModel.isEmpty {
                emptyStateView
            } else if viewModel.isFilteredEmpty {
                filteredEmptyView
            } else {
                capturesList(viewModel)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private func headerSection(_ viewModel: CaptureListViewModel) -> some View {
        VStack(spacing: Spacing.md) {
            // Search bar
            SearchBar(
                placeholder: "Search captures...",
                text: Binding(
                    get: { viewModel.searchText },
                    set: { viewModel.searchText = $0 }
                )
            )

            // Type filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(CaptureTypeFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isSelected: viewModel.selectedType == filter
                        ) {
                            viewModel.selectedType = filter
                        }
                    }
                }
            }

            // Status filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(CaptureStatusFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isSelected: viewModel.selectedStatus == filter
                        ) {
                            viewModel.selectedStatus = filter
                        }
                    }
                }
            }

            // Capture count
            HStack {
                Text("\(viewModel.captureCount) capture\(viewModel.captureCount == 1 ? "" : "s")")
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
    private func capturesList(_ viewModel: CaptureListViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(viewModel.filteredCaptures) { capture in
                    CaptureListCard(
                        capture: capture,
                        onDelete: {
                            Task { await viewModel.deleteCapture(capture.id) }
                        }
                    )
                }
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.md)
        }
    }

    private var emptyStateView: some View {
        EmptyStateView(
            icon: IconAssets.capture,
            title: "No Captures Yet",
            message: "Start by capturing images or videos of your samples",
            action: ("New Capture", { navigation.showCamera() })
        )
    }

    private var filteredEmptyView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            IconAssets.search
                .font(.system(size: 48))
                .foregroundColor(ColorPalette.onSurfaceVariant)

            Text("No matching captures")
                .font(Typography.titleMedium)
                .foregroundColor(ColorPalette.onBackground)

            Text("Try adjusting your search or filters")
                .font(Typography.bodyMedium)
                .foregroundColor(ColorPalette.onSurfaceVariant)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
    }
}

#Preview {
    CaptureListView()
}
