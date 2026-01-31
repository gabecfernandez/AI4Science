import SwiftUI

/// Custom slider control component
public struct SliderControl: View {
    let label: String
    let value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String?
    let onValueChange: (Double) -> Void

    @Environment(\.theme) var theme

    public init(
        _ label: String,
        value: Double,
        range: ClosedRange<Double>,
        step: Double = 1.0,
        unit: String? = nil,
        onValueChange: @escaping (Double) -> Void
    ) {
        self.label = label
        self.value = value
        self.range = range
        self.step = step
        self.unit = unit
        self.onValueChange = onValueChange
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(label)
                    .font(Typography.labelMedium)
                    .fontWeight(.semibold)

                Spacer()

                HStack(spacing: Spacing.xs) {
                    Text(String(format: "%.1f", value))
                        .font(Typography.labelMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorPalette.utsa_primary)

                    if let unit = unit {
                        Text(unit)
                            .font(Typography.labelSmall)
                            .foregroundColor(ColorPalette.onSurfaceVariant)
                    }
                }
            }

            Slider(
                value: Binding(
                    get: { value },
                    set: { onValueChange($0) }
                ),
                in: range,
                step: step
            )
            .tint(ColorPalette.utsa_primary)

            // Range labels
            HStack {
                Text(String(format: "%.1f", range.lowerBound))
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)

                Spacer()

                Text(String(format: "%.1f", range.upperBound))
                    .font(Typography.labelSmall)
                    .foregroundColor(ColorPalette.onSurfaceVariant)
            }
        }
        .padding(Spacing.base)
        .background(ColorPalette.surface)
        .cornerRadius(BorderStyles.radiusMedium)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        SliderControl(
            "Confidence Threshold",
            value: 0.7,
            range: 0.0 ... 1.0,
            step: 0.05,
            unit: "%"
        ) { _ in }

        SliderControl(
            "Image Quality",
            value: 85,
            range: 0 ... 100,
            step: 5
        ) { _ in }

        Spacer()
    }
    .screenPadding()
    .background(ColorPalette.background)
}
