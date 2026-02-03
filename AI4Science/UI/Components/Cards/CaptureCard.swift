import SwiftUI

/// Card component for displaying capture thumbnails
public struct CaptureCard: View {
    let thumbnail: Image?
    let title: String
    let subtitle: String?
    let isFocus: Bool
    let aspectRatio: CGFloat
    let onTap: () -> Void

    @Environment(\.theme) var theme

    public init(
        thumbnail: Image? = nil,
        title: String,
        subtitle: String? = nil,
        isFocus: Bool = false,
        aspectRatio: CGFloat = 1.0,
        onTap: @escaping () -> Void = {}
    ) {
        self.thumbnail = thumbnail
        self.title = title
        self.subtitle = subtitle
        self.isFocus = isFocus
        self.aspectRatio = aspectRatio
        self.onTap = onTap
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Thumbnail
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: BorderStyles.radiusMedium, style: .continuous)
                    .fill(ColorPalette.surfaceVariant)

                if let thumbnail = thumbnail {
                    thumbnail
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .cornerRadius(BorderStyles.radiusMedium)
                } else {
                    IconAssets.image
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }
            }
            .aspectRatio(aspectRatio, contentMode: .fit)

            // Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.labelMedium)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.labelSmall)
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.sm)
            .background(ColorPalette.surface)
        }
        .cornerRadius(BorderStyles.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .stroke(
                    isFocus ? ColorPalette.utsa_primary : ColorPalette.divider,
                    lineWidth: isFocus ? 2 : 1
                )
        )
        .shadow(Shadows.small)
        .onTapGesture(perform: onTap)
        .contentShape(.rect)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        HStack(spacing: Spacing.md) {
            CaptureCard(
                title: "Capture 01",
                subtitle: "2024-01-31"
            )

            CaptureCard(
                title: "Capture 02",
                subtitle: "2024-01-31",
                isFocus: true
            )
        }

        HStack(spacing: Spacing.md) {
            CaptureCard(
                title: "Capture 03",
                subtitle: "2024-01-31",
                aspectRatio: 16.0 / 9.0
            )
        }
    }
    .screenPadding()
    .background(ColorPalette.background)
}
