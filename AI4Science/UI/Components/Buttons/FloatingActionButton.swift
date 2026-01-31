import SwiftUI

/// Floating Action Button for primary capture action
public struct FloatingActionButton: View {
    let icon: Image
    let label: String?
    let isLoading: Bool
    let isEnabled: Bool
    let size: CGFloat
    let action: () -> Void

    @Environment(\.theme) var theme

    public init(
        _ icon: Image,
        label: String? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        size: CGFloat = 56,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = label
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    icon
                        .font(.system(size: 24, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                }

                if let label = label {
                    Text(label)
                        .font(Typography.labelSmall)
                        .foregroundColor(.white)
                }
            }
            .frame(width: size, height: size)
            .background(
                isEnabled
                    ? ColorPalette.utsa_primary
                    : ColorPalette.disabled
            )
            .cornerRadius(size / 2)
            .shadow(Shadows.large)
        }
        .disabled(!isEnabled || isLoading)
        .contentShape(.rect)
        .scaleEffect(isLoading ? 0.95 : 1.0)
        .opacity(isLoading ? 0.9 : 1.0)
        .accessibilityLabel(label ?? "Action")
    }
}

#Preview {
    ZStack(alignment: .bottomTrailing) {
        VStack {
            ScrollView {
                Text("Content area")
                    .font(Typography.bodyLarge)
                    .screenPadding()
            }
            .background(ColorPalette.background)
        }

        VStack(spacing: Spacing.md) {
            FloatingActionButton(
                IconAssets.capture,
                label: "Capture",
                action: {}
            )

            FloatingActionButton(
                IconAssets.add,
                isLoading: true,
                action: {}
            )

            FloatingActionButton(
                IconAssets.refresh,
                isEnabled: false,
                action: {}
            )
        }
        .padding(Spacing.lg)
    }
}
