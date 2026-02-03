//
//  AnalysisDashboardViewContent.swift
//  AI4Science
//
//  Main view for the Analysis tab showing analysis results dashboard
//

import SwiftUI

struct AnalysisDashboardViewContent: View {
    @Environment(ServiceContainer.self) private var services
    @State private var viewModel: AnalysisDashboardViewModel?

    var body: some View {
        ZStack {
            ColorPalette.background
                .ignoresSafeArea()

            if let viewModel = viewModel {
                dashboardContent(viewModel)
            } else {
                LoadingView("Loading analysis...")
            }
        }
        .navigationTitle("Analysis")
        .task {
            if viewModel == nil {
                viewModel = AnalysisDashboardViewModel(analysisRepository: services.analysisRepository)
            }
            await viewModel?.loadResults()
        }
    }

    @ViewBuilder
    private func dashboardContent(_ viewModel: AnalysisDashboardViewModel) -> some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.results.isEmpty {
                Spacer()
                LoadingView("Loading analysis results...")
                Spacer()
            } else if viewModel.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Summary cards
                        summarySection(viewModel.summaryStats)

                        // Filter section
                        filterSection(viewModel)

                        // Results list
                        resultsSection(viewModel)
                    }
                    .padding(.horizontal, Spacing.base)
                    .padding(.vertical, Spacing.md)
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private func summarySection(_ stats: AnalysisSummaryStats) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Overview")
                .font(Typography.titleSmall)
                .foregroundColor(ColorPalette.onBackground)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                SummaryCard(
                    title: "Total Analyses",
                    value: "\(stats.totalAnalyses)",
                    icon: "chart.bar.fill",
                    color: ColorPalette.utsa_primary
                )

                SummaryCard(
                    title: "Avg Confidence",
                    value: stats.averageConfidence > 0 ? String(format: "%.0f%%", stats.averageConfidence * 100) : "--",
                    icon: "gauge.with.needle.fill",
                    color: ColorPalette.success
                )

                SummaryCard(
                    title: "Processing",
                    value: "\(stats.processingCount)",
                    icon: "arrow.trianglehead.clockwise",
                    color: ColorPalette.warning
                )

                SummaryCard(
                    title: "Objects Found",
                    value: "\(stats.totalObjectsDetected)",
                    icon: "scope",
                    color: ColorPalette.info
                )
            }
        }
    }

    @ViewBuilder
    private func filterSection(_ viewModel: AnalysisDashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Results")
                    .font(Typography.titleSmall)
                    .foregroundColor(ColorPalette.onBackground)

                Spacer()

                Text("\(viewModel.resultCount) result\(viewModel.resultCount == 1 ? "" : "s")")
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(AnalysisStatusFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isSelected: viewModel.selectedStatus == filter
                        ) {
                            viewModel.selectedStatus = filter
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func resultsSection(_ viewModel: AnalysisDashboardViewModel) -> some View {
        if viewModel.isFilteredEmpty {
            VStack(spacing: Spacing.md) {
                IconAssets.search
                    .font(.system(size: 36))
                    .foregroundColor(ColorPalette.onSurfaceVariant)

                Text("No matching results")
                    .font(Typography.bodyMedium)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
        } else {
            LazyVStack(spacing: Spacing.md) {
                ForEach(viewModel.filteredResults) { result in
                    AnalysisResultCard(result: result)
                }
            }
        }
    }

    private var emptyStateView: some View {
        EmptyStateView(
            icon: IconAssets.analysis,
            title: "No Analysis Results",
            message: "Capture images and run AI analysis to see results here"
        )
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(Typography.titleLarge)
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.onSurface)

            Text(title)
                .font(Typography.labelSmall)
                .foregroundColor(ColorPalette.onSurfaceVariant)
        }
        .padding(Spacing.base)
        .background(ColorPalette.surface)
        .cornerRadius(BorderStyles.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .stroke(ColorPalette.divider, lineWidth: 1)
        )
    }
}

#Preview {
    AnalysisDashboardViewContent()
}
