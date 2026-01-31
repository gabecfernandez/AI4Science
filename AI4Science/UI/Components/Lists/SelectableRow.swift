import SwiftUI

/// Selectable list row with checkbox
public struct SelectableRow<Content: View>: View {
    let isSelected: Bool
    let content: Content
    let onToggle: () -> Void

    @Environment(\.theme) var theme

    public init(
        isSelected: Bool,
        onToggle: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isSelected = isSelected
        self.content = content()
        self.onToggle = onToggle
    }

    public var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Spacing.md) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? ColorPalette.utsa_primary : ColorPalette.divider,
                            lineWidth: 2
                        )

                    if isSelected {
                        Circle()
                            .fill(ColorPalette.utsa_primary)

                        IconAssets.checkmark
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 24, height: 24)

                content

                Spacer()
            }
            .contentShape(Rectangle())
            .padding(Spacing.base)
            .background(
                isSelected
                    ? ColorPalette.utsa_primary.opacity(0.05)
                    : ColorPalette.surface
            )
            .cornerRadius(BorderStyles.radiusMedium)
        }
        .foregroundColor(ColorPalette.onBackground)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        SelectableRow(isSelected: false, onToggle: {}) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Sample 1")
                    .font(Typography.labelMedium)
                    .fontWeight(.semibold)
                Text("Captured 2024-01-31")
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            }
        }

        SelectableRow(isSelected: true, onToggle: {}) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Sample 2")
                    .font(Typography.labelMedium)
                    .fontWeight(.semibold)
                Text("Analyzed 2024-01-31")
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            }
        }

        Spacer()
    }
    .screenPadding()
    .background(ColorPalette.background)
}
