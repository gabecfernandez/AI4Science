import SwiftUI

/// Custom date picker field component
public struct DatePickerField: View {
    let label: String
    let icon: Image?
    @Binding var selectedDate: Date?

    @Environment(\.theme) var theme
    @State private var isShowingPicker = false

    public init(
        _ label: String,
        icon: Image? = nil,
        selection: Binding<Date?>
    ) {
        self.label = label
        self.icon = icon
        self._selectedDate = selection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(Typography.labelMedium)
                .fontWeight(.semibold)

            Button(action: { isShowingPicker.toggle() }) {
                HStack(spacing: Spacing.sm) {
                    if let icon = icon {
                        icon
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(ColorPalette.onSurfaceVariant)
                    }

                    Text(formatDate(selectedDate))
                        .foregroundColor(
                            selectedDate != nil
                                ? ColorPalette.onBackground
                                : ColorPalette.onSurfaceVariant
                        )

                    Spacer()

                    IconAssets.forward
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ColorPalette.onSurfaceVariant)
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

            if isShowingPicker {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { selectedDate ?? Date() },
                        set: { selectedDate = $0 }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding(Spacing.md)
                .background(ColorPalette.surface)
                .cornerRadius(BorderStyles.radiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                        .stroke(ColorPalette.divider, lineWidth: 1)
                )

                HStack(spacing: Spacing.sm) {
                    SecondaryButton("Cancel") {
                        isShowingPicker = false
                    }

                    PrimaryButton("Done") {
                        isShowingPicker = false
                    }
                }
            }
        }
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Select date..." }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        DatePickerField(
            "Analysis Date",
            icon: IconAssets.clock,
            selection: .constant(Date())
        )

        Spacer()
    }
    .screenPadding()
    .background(ColorPalette.background)
}
