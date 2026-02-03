import SwiftUI

struct SampleDetailView: View {
    let sample: SampleDisplayItem
    @State private var viewModel = SampleDetailViewModel()
    @State private var selectedTab: SampleTab = .details
    @Environment(\.dismiss) var dismiss

    enum SampleTab {
        case details
        case images
        case analysis
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
                            Text(sample.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                Label(sample.type, systemImage: "tag.fill")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))

                                Label(sample.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
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
                                Label("Duplicate", systemImage: "doc.on.doc")
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

                    // Tabs
                    HStack(spacing: 0) {
                        ForEach([SampleTab.details, .images, .analysis], id: \.self) { tab in
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
                            .contentShape(.rect)
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
                        case .details:
                            SampleDetailsContent(sample: sample)
                        case .images:
                            SampleImagesContent(sample: sample)
                        case .analysis:
                            SampleAnalysisContent(sample: sample)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSampleDetails(for: sample.id)
        }
    }

    private func tabTitle(_ tab: SampleTab) -> String {
        switch tab {
        case .details:
            return "Details"
        case .images:
            return "Images"
        case .analysis:
            return "Analysis"
        }
    }
}

struct SampleDetailsContent: View {
    let sample: SampleDisplayItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sample Information")
                    .font(.headline)
                    .foregroundColor(.white)

                DetailRow(label: "Sample ID", value: sample.id)
                DetailRow(label: "Type", value: sample.type)
                DetailRow(label: "Created", value: sample.date.formatted(date: .abbreviated, time: .omitted))
                DetailRow(label: "Total Images", value: "\(sample.imageCount)")
                DetailRow(label: "Status", value: sample.analysisStatus.rawValue)
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)

            Button(action: {}) {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                    Text("Edit Metadata")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

struct SampleImagesContent: View {
    let sample: SampleDisplayItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Captured Images")
                .font(.headline)
                .foregroundColor(.white)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(0..<sample.imageCount, id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))

                        VStack(spacing: 8) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)

                            Text("Image \(index + 1)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .frame(height: 100)
                }
            }

            Button(action: {}) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Images")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

struct SampleAnalysisContent: View {
    let sample: SampleDisplayItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if sample.hasAnalysis {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Analysis Results")
                        .font(.headline)
                        .foregroundColor(.white)

                    DetailRow(label: "Status", value: sample.analysisStatus.rawValue)
                    DetailRow(label: "Model Used", value: "ResNet-50")
                    DetailRow(label: "Confidence", value: "94.2%")
                    DetailRow(label: "Analyzed Date", value: Date().formatted(date: .abbreviated, time: .omitted))
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)

                Button(action: {}) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("View Full Analysis")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.3))

                    Text("No Analysis Yet")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Run analysis to get insights about this sample")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    Button(action: {}) {
                        Text("Run Analysis")
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
    }
}

struct DetailRow: View {
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
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        SampleDetailView(sample: SampleDisplayItem(
            id: "1",
            name: "Sample A",
            type: "Material",
            date: Date(),
            imageCount: 5,
            hasAnalysis: true,
            analysisStatus: .completed
        ))
    }
}
