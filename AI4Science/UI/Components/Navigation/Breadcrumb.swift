import SwiftUI

/// Breadcrumb navigation component
public struct Breadcrumb: View {
    let items: [BreadcrumbItem]
    let onItemTap: (Int) -> Void

    @Environment(\.theme) var theme

    public struct BreadcrumbItem: Identifiable {
        public let id: Int
        public let label: String
        public let isLast: Bool

        public init(id: Int, label: String, isLast: Bool = false) {
            self.id = id
            self.label = label
            self.isLast = isLast
        }
    }

    public init(items: [String], onItemTap: @escaping (Int) -> Void) {
        self.items = items.enumerated().map { index, label in
            BreadcrumbItem(id: index, label: label, isLast: index == items.count - 1)
        }
        self.onItemTap = onItemTap
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(items) { item in
                    if item.id > 0 {
                        IconAssets.forward
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ColorPalette.onSurfaceVariant)
                    }

                    Button(action: {
                        onItemTap(item.id)
                    }) {
                        Text(item.label)
                            .font(Typography.labelSmall)
                            .lineLimit(1)
                            .foregroundColor(
                                item.isLast
                                    ? ColorPalette.utsa_primary
                                    : ColorPalette.onSurfaceVariant
                            )
                            .fontWeight(item.isLast ? .semibold : .regular)
                    }
                    .disabled(item.isLast)
                }
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.sm)
        }
        .background(ColorPalette.surface)
    }
}

#Preview {
    VStack {
        Breadcrumb(
            items: ["Projects", "Disease Detection", "Samples"],
            onItemTap: { _ in }
        )

        Spacer()
    }
    .background(ColorPalette.background)
}
