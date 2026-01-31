import SwiftUI

/// Custom segmented control component
public struct SegmentedControl: View {
    let options: [String]
    @Binding var selectedIndex: Int

    @Environment(\.theme) var theme

    public init(_ options: [String], selection: Binding<Int>) {
        self.options = options
        self._selectedIndex = selection
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<options.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedIndex = index
                    }
                }) {
                    Text(options[index])
                        .font(Typography.labelMedium)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .foregroundColor(
                            selectedIndex == index
                                ? .white
                                : ColorPalette.onSurfaceVariant
                        )
                        .background(
                            selectedIndex == index
                                ? ColorPalette.utsa_primary
                                : Color.clear
                        )
                }
            }
        }
        .background(ColorPalette.surfaceVariant)
        .cornerRadius(BorderStyles.radiusMedium)
        .padding(2)
        .background(ColorPalette.surface)
        .cornerRadius(BorderStyles.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .stroke(ColorPalette.divider, lineWidth: 1)
        )
    }
}

#Preview {
    @State var selected = 0

    return VStack(spacing: Spacing.md) {
        SegmentedControl(
            ["All", "Captured", "Analyzed"],
            selection: $selected
        )

        SegmentedControl(
            ["List", "Grid", "Map"],
            selection: .constant(1)
        )

        Spacer()
    }
    .screenPadding()
    .background(ColorPalette.background)
}
