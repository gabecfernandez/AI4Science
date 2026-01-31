import SwiftUI

/// Swipeable list row with trailing actions
public struct SwipeableRow<Content: View>: View {
    let content: Content
    let actions: [SwipeAction]
    let onAction: (SwipeAction) -> Void

    @Environment(\.theme) var theme
    @State private var offset: CGFloat = 0

    public struct SwipeAction: Identifiable {
        public let id: String
        public let title: String
        public let color: Color
        public let icon: Image?

        public init(
            id: String,
            title: String,
            color: Color,
            icon: Image? = nil
        ) {
            self.id = id
            self.title = title
            self.color = color
            self.icon = icon
        }
    }

    public init(
        @ViewBuilder content: @escaping () -> Content,
        actions: [SwipeAction],
        onAction: @escaping (SwipeAction) -> Void
    ) {
        self.content = content()
        self.actions = actions
        self.onAction = onAction
    }

    public var body: some View {
        ZStack(alignment: .trailing) {
            // Actions
            HStack(spacing: 0) {
                ForEach(actions) { action in
                    Button(action: {
                        onAction(action)
                        withAnimation {
                            offset = 0
                        }
                    }) {
                        VStack {
                            if let icon = action.icon {
                                icon
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            Text(action.title)
                                .font(Typography.labelSmall)
                        }
                        .foregroundColor(.white)
                        .frame(maxHeight: .infinity)
                        .frame(width: 80)
                        .background(action.color)
                    }
                }
            }

            // Content
            content
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = min(0, value.translation.width)
                        }
                        .onEnded { value in
                            let threshold = -50.0
                            if value.translation.width < threshold {
                                offset = -CGFloat(actions.count) * 80
                            } else {
                                offset = 0
                            }
                        }
                )
        }
        .frame(maxHeight: .infinity)
        .clipped()
    }
}

#Preview {
    VStack(spacing: 0) {
        SwipeableRow(
            content: {
                HStack {
                    Text("Sample 1")
                        .font(Typography.labelMedium)
                    Spacer()
                    Text("2024-01-31")
                        .font(Typography.labelSmall)
                }
                .padding(Spacing.base)
                .background(ColorPalette.surface)
            },
            actions: [
                .init(id: "edit", title: "Edit", color: ColorPalette.info, icon: IconAssets.edit),
                .init(id: "delete", title: "Delete", color: ColorPalette.error, icon: IconAssets.delete),
            ],
            onAction: { _ in }
        )

        Divider()

        SwipeableRow(
            content: {
                HStack {
                    Text("Sample 2")
                        .font(Typography.labelMedium)
                    Spacer()
                    Text("2024-01-30")
                        .font(Typography.labelSmall)
                }
                .padding(Spacing.base)
                .background(ColorPalette.surface)
            },
            actions: [
                .init(id: "delete", title: "Delete", color: ColorPalette.error, icon: IconAssets.delete),
            ],
            onAction: { _ in }
        )
    }
    .background(ColorPalette.background)
}
