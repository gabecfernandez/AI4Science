import SwiftUI

struct SampleListView: View {
    let projectID: String
    @State private var viewModel = SampleListViewModel()
    @State private var searchText = ""
    @State private var selectedSample: SampleDisplayItem?
    @State private var showCreateSample = false

    var filteredSamples: [SampleDisplayItem] {
        if searchText.isEmpty {
            return viewModel.samples
        }
        return viewModel.samples.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Samples")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)

                            Text("\(viewModel.samples.count) samples")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()

                        Button(action: { showCreateSample = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Search
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.5))

                        TextField("Search samples...", text: $searchText)
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

                // Samples list
                if filteredSamples.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "beaker")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No Samples")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Create a new sample to get started")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredSamples) { sample in
                                NavigationLink(value: sample) {
                                    SampleListItemCard(sample: sample)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationDestination(for: SampleDisplayItem.self) { sample in
            SampleDetailView(sample: sample)
        }
        .sheet(isPresented: $showCreateSample) {
            SampleCreateView(isPresented: $showCreateSample, projectID: projectID) { newSample in
                viewModel.samples.append(newSample)
            }
        }
        .task {
            await viewModel.loadSamples(for: projectID)
        }
    }
}

struct SampleListItemCard: View {
    let sample: SampleDisplayItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(sample.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        Label(sample.type, systemImage: "tag.fill")
                            .font(.caption)
                            .foregroundColor(.blue)

                        Spacer()

                        Text(sample.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: statusIcon(sample.analysisStatus))
                        .foregroundColor(statusColor(sample.analysisStatus))

                    Text(sample.analysisStatus.rawValue)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            HStack(spacing: 12) {
                Label("\(sample.imageCount) images", systemImage: "photo.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                if sample.hasAnalysis {
                    Label("Analyzed", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }

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

    private func statusIcon(_ status: SampleDisplayItem.AnalysisStatus) -> String {
        switch status {
        case .pending:
            return "hourglass"
        case .processing:
            return "gear"
        case .completed:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }

    private func statusColor(_ status: SampleDisplayItem.AnalysisStatus) -> Color {
        switch status {
        case .pending:
            return .gray
        case .processing:
            return .orange
        case .completed:
            return .green
        case .error:
            return .red
        }
    }
}

// SampleDisplayItem is defined in SampleDisplayModels.swift

#Preview {
    NavigationStack {
        SampleListView(projectID: "1")
    }
}
