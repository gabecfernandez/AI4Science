import SwiftUI

/// Custom tab bar component for main navigation
public struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]

    @Environment(\.theme) var theme

    public struct TabItem: Identifiable {
        public let id: Int
        public let icon: Image
        public let label: String
        public let badgeCount: Int?

        public init(id: Int, icon: Image, label: String, badgeCount: Int? = nil) {
            self.id = id
            self.icon = icon
            self.label = label
            self.badgeCount = badgeCount
        }
    }

    public init(selectedTab: Binding<Int>, tabs: [TabItem]) {
        self._selectedTab = selectedTab
        self.tabs = tabs
    }

    public var body: some View {
        VStack(spacing: 0) {
            Divider()
                .foregroundColor(ColorPalette.divider)

            HStack(spacing: 0) {
                ForEach(tabs) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab.id
                        }
                    }) {
                        VStack(spacing: Spacing.xs) {
                            ZStack(alignment: .topTrailing) {
                                tab.icon
                                    .font(.system(size: 24, weight: .semibold, design: .default))
                                    .foregroundColor(
                                        selectedTab == tab.id
                                            ? ColorPalette.utsa_primary
                                            : ColorPalette.onSurfaceVariant
                                    )

                                if let badge = tab.badgeCount, badge > 0 {
                                    Text("\(badge)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 18, height: 18)
                                        .background(ColorPalette.error)
                                        .cornerRadius(9)
                                        .offset(x: 6, y: -6)
                                }
                            }

                            Text(tab.label)
                                .font(Typography.labelSmall)
                                .lineLimit(1)
                                .foregroundColor(
                                    selectedTab == tab.id
                                        ? ColorPalette.utsa_primary
                                        : ColorPalette.onSurfaceVariant
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                }
            }
            .background(ColorPalette.surface)
        }
    }
}

#Preview {
    @State var selectedTab = 0

    return VStack {
        Spacer()

        CustomTabBar(
            selectedTab: $selectedTab,
            tabs: [
                .init(id: 0, icon: IconAssets.homeOutline, label: "Home"),
                .init(id: 1, icon: IconAssets.projectsOutline, label: "Projects"),
                .init(id: 2, icon: IconAssets.captureOutline, label: "Capture"),
                .init(id: 3, icon: IconAssets.analysisOutline, label: "Analysis"),
                .init(id: 4, icon: IconAssets.settings, label: "Settings"),
            ]
        )
    }
    .background(ColorPalette.background)
}
