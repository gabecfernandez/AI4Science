import SwiftUI

/// Card component for displaying project information
public struct ProjectCard: View {
    let title: String
    let description: String?
    let imageURL: URL?
    let sampleCount: Int
    let lastModified: Date?
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: (() -> Void)?

    @Environment(\.theme) var theme
    @State private var showDeleteAlert = false

    public init(
        title: String,
        description: String? = nil,
        imageURL: URL? = nil,
        sampleCount: Int = 0,
        lastModified: Date? = nil,
        isSelected: Bool = false,
        onTap: @escaping () -> Void = {},
        onDelete: (() -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.sampleCount = sampleCount
        self.lastModified = lastModified
        self.isSelected = isSelected
        self.onTap = onTap
        self.onDelete = onDelete
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header with delete button
            HStack {
                Text(title)
                    .font(Typography.titleMedium)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Spacer()

                if let onDelete = onDelete {
                    IconButton(
                        IconAssets.delete,
                        size: .small,
                        tint: ColorPalette.error
                    ) {
                        showDeleteAlert = true
                    }
                }
            }

            // Description
            if let description = description {
                Text(description)
                    .font(Typography.bodySmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
                    .lineLimit(2)
            }

            // Metadata
            HStack(spacing: Spacing.lg) {
                HStack(spacing: Spacing.xs) {
                    IconAssets.image
                        .font(.system(size: 14))
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                    Text("\(sampleCount)")
                        .font(Typography.labelSmall)
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }

                if let lastModified = lastModified {
                    HStack(spacing: Spacing.xs) {
                        IconAssets.clock
                            .font(.system(size: 14))
                            .foregroundColor(ColorPalette.onSurfaceVariant)
                        Text(formatDate(lastModified))
                            .font(Typography.labelSmall)
                            .foregroundColor(ColorPalette.onSurfaceVariant)
                    }
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.base)
        .background(ColorPalette.surface)
        .cornerRadius(BorderStyles.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .stroke(
                    isSelected ? ColorPalette.utsa_primary : ColorPalette.divider,
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(Shadows.small)
        .onTapGesture(perform: onTap)
        .contentShape(.rect)
        .alert("Delete Project", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete '\(title)'? This action cannot be undone.")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        ProjectCard(
            title: "Plant Disease Detection",
            description: "Tomato leaf disease classification",
            sampleCount: 24,
            lastModified: Date(timeIntervalSinceNow: -3600),
            onTap: {}
        )

        ProjectCard(
            title: "Soil Analysis",
            description: nil,
            sampleCount: 15,
            isSelected: true,
            onTap: {},
            onDelete: {}
        )
    }
    .screenPadding()
    .background(ColorPalette.background)
}
