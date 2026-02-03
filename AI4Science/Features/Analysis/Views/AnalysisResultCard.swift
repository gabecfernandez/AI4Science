//
//  AnalysisResultCard.swift
//  AI4Science
//
//  Reusable card component for displaying analysis results
//

import SwiftUI

struct AnalysisResultCard: View {
    let result: AnalysisResultDisplayModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header row
            HStack(alignment: .top) {
                // Model info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: result.analysisTypeIcon)
                            .foregroundColor(ColorPalette.utsa_primary)
                        Text(result.modelName)
                            .font(Typography.titleSmall)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorPalette.onSurface)
                    }

                    Text("v\(result.modelVersion) • \(formatAnalysisType(result.analysisType))")
                        .font(Typography.labelSmall)
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }

                Spacer()

                // Status badge
                statusBadge
            }

            // Sample info
            if let sampleName = result.captureSampleName {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "flask.fill")
                        .font(.caption)
                    Text(sampleName)

                    if let captureType = result.captureType {
                        Text("•")
                        Text(captureType.capitalized)
                    }
                }
                .font(Typography.bodySmall)
                .foregroundColor(ColorPalette.onSurfaceVariant)
            }

            Divider()

            // Metrics row
            HStack(spacing: Spacing.lg) {
                // Confidence score
                if let confidence = result.confidenceScore {
                    MetricView(
                        label: "Confidence",
                        value: String(format: "%.0f%%", confidence * 100),
                        icon: "gauge.with.needle",
                        color: confidenceColor(confidence)
                    )
                }

                // Objects detected
                if result.objectCount > 0 {
                    MetricView(
                        label: "Detected",
                        value: "\(result.objectCount)",
                        icon: "scope",
                        color: ColorPalette.info
                    )
                }

                // Duration
                if let duration = result.duration {
                    MetricView(
                        label: "Duration",
                        value: formatDuration(duration),
                        icon: "clock",
                        color: ColorPalette.onSurfaceVariant
                    )
                }

                Spacer()

                // Review status
                if result.isReviewed {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(ColorPalette.success)
                        Text("Reviewed")
                            .font(Typography.labelSmall)
                            .foregroundColor(ColorPalette.success)
                    }
                }
            }

            // Review notes if available
            if let notes = result.reviewNotes {
                Text(notes)
                    .font(Typography.bodySmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
                    .padding(.top, Spacing.xs)
            }

            // Footer with date
            HStack {
                Spacer()
                Text(formatDate(result.completedAt ?? result.startedAt))
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            }
        }
        .padding(Spacing.base)
        .background(ColorPalette.surface)
        .cornerRadius(BorderStyles.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .stroke(ColorPalette.divider, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: Spacing.xs) {
            if result.status == "processing" {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Image(systemName: result.statusIcon)
            }
            Text(result.status.capitalized)
        }
        .font(Typography.labelSmall)
        .fontWeight(.medium)
        .foregroundColor(statusTextColor)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(statusBackgroundColor.opacity(0.15))
        .cornerRadius(Spacing.radiusCircle)
    }

    private var statusTextColor: Color {
        switch result.status {
        case "completed": return ColorPalette.success
        case "processing": return ColorPalette.warning
        case "failed": return ColorPalette.error
        default: return ColorPalette.onSurfaceVariant
        }
    }

    private var statusBackgroundColor: Color {
        switch result.status {
        case "completed": return ColorPalette.success
        case "processing": return ColorPalette.warning
        case "failed": return ColorPalette.error
        default: return ColorPalette.onSurfaceVariant
        }
    }

    private func confidenceColor(_ score: Double) -> Color {
        if score >= 0.9 { return ColorPalette.success }
        if score >= 0.7 { return ColorPalette.warning }
        return ColorPalette.error
    }

    private func formatAnalysisType(_ type: String) -> String {
        type.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func formatDuration(_ seconds: Double) -> String {
        if seconds < 60 {
            return String(format: "%.1fs", seconds)
        } else {
            return String(format: "%.1fm", seconds / 60)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Metric View

private struct MetricView: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(value)
                    .fontWeight(.semibold)
            }
            .font(Typography.labelMedium)
            .foregroundColor(color)

            Text(label)
                .font(Typography.labelSmall)
                .foregroundColor(ColorPalette.onSurfaceVariant)
        }
    }
}

#Preview {
    VStack {
        AnalysisResultCard(
            result: AnalysisResultDisplayModel(
                id: "1",
                modelName: "DefectDetectionV2",
                modelVersion: "2.1.0",
                analysisType: "defect_detection",
                status: "completed",
                startedAt: Date().addingTimeInterval(-86400 * 5),
                completedAt: Date().addingTimeInterval(-86400 * 5 + 120),
                duration: 120,
                confidenceScore: 0.92,
                objectCount: 3,
                isReviewed: true,
                reviewNotes: "Confirmed 2 of 3 detections",
                captureSampleName: "CF-001-A",
                captureType: "microscopy"
            )
        )

        AnalysisResultCard(
            result: AnalysisResultDisplayModel(
                id: "2",
                modelName: "MaterialClassifier",
                modelVersion: "1.3.0",
                analysisType: "classification",
                status: "processing",
                startedAt: Date().addingTimeInterval(-300),
                completedAt: nil,
                duration: nil,
                confidenceScore: nil,
                objectCount: 0,
                isReviewed: false,
                reviewNotes: nil,
                captureSampleName: "CF-001-B",
                captureType: "photo"
            )
        )
    }
    .padding()
    .background(ColorPalette.background)
}
