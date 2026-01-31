import SwiftUI

struct ProjectExportView: View {
    let project: Project
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var includeImages = true
    @State private var includeSamples = true
    @State private var includeAnalysis = true
    @State private var isExporting = false
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss

    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case csv = "CSV"
        case json = "JSON"
        case excel = "Excel"
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

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Export Project")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text(project.title)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Format selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export Format")
                            .font(.headline)
                            .foregroundColor(.white)

                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            FormatOption(
                                format: format,
                                isSelected: selectedFormat == format,
                                action: { selectedFormat = format }
                            )
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)

                    // Content options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Include in Export")
                            .font(.headline)
                            .foregroundColor(.white)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Images & Media")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                Text("Original capture images")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Spacer()

                            Toggle("", isOn: $includeImages)
                                .tint(.blue)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Samples")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                Text("Sample data and metadata")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Spacer()

                            Toggle("", isOn: $includeSamples)
                                .tint(.blue)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Analysis Results")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                Text("ML analysis and predictions")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Spacer()

                            Toggle("", isOn: $includeAnalysis)
                                .tint(.blue)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)

                    // Export summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export Summary")
                            .font(.headline)
                            .foregroundColor(.white)

                        SummaryRow(
                            label: "Format",
                            value: selectedFormat.rawValue,
                            icon: "doc.fill"
                        )

                        SummaryRow(
                            label: "Size (estimated)",
                            value: "~24 MB",
                            icon: "doc.badge.gearshape.fill"
                        )

                        SummaryRow(
                            label: "Items to export",
                            value: "\(project.sampleCount) samples",
                            icon: "square.and.arrow.down.fill"
                        )
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)

                    // Export button
                    Button(action: { Task { await performExport() } }) {
                        if isExporting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("Export Project")
                                    .font(.headline)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(isExporting)

                    // Cancel button
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .foregroundColor(.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 1)
                    )

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Export Complete", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Project exported successfully as \(selectedFormat.rawValue)")
        }
    }

    private func performExport() async {
        isExporting = true
        defer { isExporting = false }

        // Simulate export process
        try? await Task.sleep(nanoseconds: 3_000_000_000)

        showSuccess = true
    }
}

struct FormatOption: View {
    let format: ProjectExportView.ExportFormat
    let isSelected: Bool
    let action: () -> Void

    var description: String {
        switch format {
        case .pdf:
            return "Portable Document Format with formatting"
        case .csv:
            return "Comma-separated values for spreadsheets"
        case .json:
            return "JavaScript Object Notation for processing"
        case .excel:
            return "Microsoft Excel spreadsheet format"
        }
    }

    var icon: String {
        switch format {
        case .pdf:
            return "doc.pdf.fill"
        case .csv:
            return "tablecells.fill"
        case .json:
            return "curlybraces.fill"
        case .excel:
            return "tablecells.badge.ellipsis.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(format.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.3))
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.transparent, lineWidth: 1)
            )
        }
    }
}

struct SummaryRow: View {
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

// Preview disabled - Project constructor mismatch
// #Preview {
//     ProjectExportView(...)
// }
