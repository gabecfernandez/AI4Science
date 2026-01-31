import SwiftUI

/// Custom dropdown/picker component
public struct DropdownPicker<T: Identifiable & Hashable>: View {
    let label: String
    let options: [T]
    let optionLabel: (T) -> String
    @Binding var selectedOption: T?

    @Environment(\.theme) var theme
    @State private var isExpanded = false

    public init(
        _ label: String,
        options: [T],
        optionLabel: @escaping (T) -> String,
        selection: Binding<T?>
    ) {
        self.label = label
        self.options = options
        self.optionLabel = optionLabel
        self._selectedOption = selection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(Typography.labelMedium)
                .fontWeight(.semibold)

            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack {
                    Text(selectedOption.map(optionLabel) ?? "Select...")
                        .foregroundColor(
                            selectedOption != nil
                                ? ColorPalette.onBackground
                                : ColorPalette.onSurfaceVariant
                        )

                    Spacer()

                    IconAssets.forward
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(ColorPalette.surface)
                .cornerRadius(BorderStyles.radiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                        .stroke(ColorPalette.divider, lineWidth: 1)
                )
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(options) { option in
                        Button(action: {
                            selectedOption = option
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = false
                            }
                        }) {
                            HStack {
                                Text(optionLabel(option))
                                    .foregroundColor(ColorPalette.onBackground)

                                Spacer()

                                if selectedOption == option {
                                    IconAssets.checkmark
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(ColorPalette.utsa_primary)
                                }
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                        }

                        if option != options.last {
                            Divider()
                                .padding(.horizontal, Spacing.sm)
                        }
                    }
                }
                .background(ColorPalette.surface)
                .cornerRadius(BorderStyles.radiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                        .stroke(ColorPalette.divider, lineWidth: 1)
                )
            }
        }
    }
}

#Preview {
    struct Option: Identifiable, Hashable {
        let id = UUID()
        let name: String
    }

    @State var selected: Option? = nil

    return VStack(spacing: Spacing.md) {
        DropdownPicker(
            "Select Project",
            options: [
                Option(name: "Disease Detection"),
                Option(name: "Soil Analysis"),
                Option(name: "Crop Monitoring"),
            ],
            optionLabel: { $0.name },
            selection: $selected
        )

        Spacer()
    }
    .screenPadding()
    .background(ColorPalette.background)
}
