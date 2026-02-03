//
//  CaptureListCard.swift
//  AI4Science
//
//  Card component for displaying capture information in a list
//

import SwiftUI

struct CaptureListCard: View {
    let capture: CaptureDisplayModel
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top, spacing: Spacing.md) {
                // Thumbnail placeholder
                thumbnailView

                // Content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Type and sample
                    HStack {
                        Label(capture.captureType.capitalized, systemImage: capture.captureTypeIcon)
                            .font(Typography.labelMedium)
                            .foregroundColor(ColorPalette.utsa_primary)

                        Spacer()

                        statusBadge
                    }

                    // Sample name
                    if let sampleName = capture.sampleName {
                        Text(sampleName)
                            .font(Typography.titleSmall)
                            .fontWeight(.medium)
                            .foregroundColor(ColorPalette.onSurface)
                    }

                    // Notes
                    if let notes = capture.notes {
                        Text(notes)
                            .font(Typography.bodySmall)
                            .foregroundColor(ColorPalette.onSurfaceVariant)
                            .lineLimit(2)
                    }
                }
            }

            // Bottom row with metadata
            HStack(spacing: Spacing.lg) {
                // Quality score
                if let quality = capture.qualityScore {
                    Label(String(format: "%.0f%%", quality * 100), systemImage: "sparkles")
                        .font(Typography.labelSmall)
                        .foregroundColor(qualityColor(quality))
                }

                // Device
                if let device = capture.deviceInfo {
                    Label(device, systemImage: "camera")
                        .font(Typography.labelSmall)
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                        .lineLimit(1)
                }

                Spacer()

                // Date
                Text(formatDate(capture.capturedAt))
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
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BorderStyles.radiusSmall)
                .fill(ColorPalette.surfaceVariant)
                .frame(width: 72, height: 72)

            Image(systemName: capture.captureTypeIcon)
                .font(.title)
                .foregroundColor(ColorPalette.onSurfaceVariant.opacity(0.6))
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        Text(capture.processingStatus.capitalized)
            .font(Typography.labelSmall)
            .fontWeight(.medium)
            .foregroundColor(statusTextColor)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(statusBackgroundColor.opacity(0.15))
            .cornerRadius(Spacing.radiusCircle)
    }

    private var statusTextColor: Color {
        switch capture.processingStatus {
        case "completed": return ColorPalette.success
        case "processing": return ColorPalette.warning
        case "failed": return ColorPalette.error
        default: return ColorPalette.onSurfaceVariant
        }
    }

    private var statusBackgroundColor: Color {
        switch capture.processingStatus {
        case "completed": return ColorPalette.success
        case "processing": return ColorPalette.warning
        case "failed": return ColorPalette.error
        default: return ColorPalette.onSurfaceVariant
        }
    }

    private func qualityColor(_ score: Double) -> Color {
        if score >= 0.9 { return ColorPalette.success }
        if score >= 0.7 { return ColorPalette.warning }
        return ColorPalette.error
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack {
        CaptureListCard(
            capture: CaptureDisplayModel(
                id: "1",
                captureType: "microscopy",
                fileURL: "file:///test.jpg",
                capturedAt: Date().addingTimeInterval(-86400 * 5),
                processingStatus: "completed",
                qualityScore: 0.95,
                notes: "4K microscopy capture at 100x magnification",
                sampleName: "CF-001-A",
                deviceInfo: "Zeiss Axio Observer",
                isProcessed: true
            ),
            onDelete: {}
        )

        CaptureListCard(
            capture: CaptureDisplayModel(
                id: "2",
                captureType: "video",
                fileURL: "file:///test.mov",
                capturedAt: Date().addingTimeInterval(-3600),
                processingStatus: "processing",
                qualityScore: 0.78,
                notes: "Time-lapse recording",
                sampleName: "CF-001-B",
                deviceInfo: "iPhone 15 Pro",
                isProcessed: false
            ),
            onDelete: {}
        )
    }
    .padding()
    .background(ColorPalette.background)
}
