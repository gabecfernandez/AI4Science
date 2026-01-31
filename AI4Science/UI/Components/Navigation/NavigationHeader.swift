import SwiftUI

/// Custom navigation header component
public struct NavigationHeader: View {
    let title: String
    let subtitle: String?
    let leftAction: (icon: Image, handler: () -> Void)?
    let rightActions: [(icon: Image, handler: () -> Void)]?
    let backgroundColor: Color

    @Environment(\.theme) var theme

    public init(
        _ title: String,
        subtitle: String? = nil,
        leftAction: (icon: Image, handler: () -> Void)? = nil,
        rightActions: [(icon: Image, handler: () -> Void)]? = nil,
        backgroundColor: Color = ColorPalette.surface
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leftAction = leftAction
        self.rightActions = rightActions
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.md) {
                if let action = leftAction {
                    Button(action: action.handler) {
                        action.icon
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(ColorPalette.utsa_primary)
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(Typography.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(ColorPalette.onBackground)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Typography.bodySmall)
                            .foregroundColor(ColorPalette.onSurfaceVariant)
                    }
                }

                Spacer()

                HStack(spacing: Spacing.md) {
                    if let rightActions = rightActions {
                        ForEach(0..<rightActions.count, id: \.self) { index in
                            Button(action: rightActions[index].handler) {
                                rightActions[index].icon
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(ColorPalette.utsa_primary)
                            }
                        }
                    }
                }
            }
            .padding(Spacing.base)

            Divider()
                .foregroundColor(ColorPalette.divider)
        }
        .background(backgroundColor)
    }
}

#Preview {
    VStack {
        NavigationHeader(
            "Projects",
            subtitle: "12 projects",
            leftAction: (IconAssets.back, {}),
            rightActions: [
                (IconAssets.add, {}),
                (IconAssets.search, {}),
            ]
        )

        Spacer()
    }
    .background(ColorPalette.background)
}
