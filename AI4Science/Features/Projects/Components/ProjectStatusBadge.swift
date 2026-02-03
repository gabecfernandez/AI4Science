import SwiftUI

/// Badge component for displaying project status
public struct ProjectStatusBadge: View {
    let status: ProjectStatus

    public init(status: ProjectStatus) {
        self.status = status
    }

    public var body: some View {
        Text(displayLabel)
            .font(Typography.labelSmall)
            .fontWeight(.medium)
            .foregroundColor(textColor)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(backgroundColor)
            .cornerRadius(Spacing.radiusSmall)
    }

    // MARK: - Display Properties

    var displayLabel: String {
        switch status {
        case .planning:
            return "Draft"
        case .active:
            return "Active"
        case .onHold:
            return "On Hold"
        case .completed:
            return "Completed"
        case .archived:
            return "Archived"
        }
    }

    var backgroundColor: Color {
        switch status {
        case .planning:
            return ColorPalette.neutral_400.opacity(0.2)
        case .active:
            return ColorPalette.success.opacity(0.15)
        case .onHold:
            return ColorPalette.warning.opacity(0.15)
        case .completed:
            return ColorPalette.utsa_primary.opacity(0.15)
        case .archived:
            return ColorPalette.neutral_500.opacity(0.15)
        }
    }

    var textColor: Color {
        switch status {
        case .planning:
            return ColorPalette.neutral_600
        case .active:
            return ColorPalette.success
        case .onHold:
            return ColorPalette.warning.darker(by: 0.1)
        case .completed:
            return ColorPalette.utsa_primary
        case .archived:
            return ColorPalette.neutral_500
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        ProjectStatusBadge(status: .planning)
        ProjectStatusBadge(status: .active)
        ProjectStatusBadge(status: .onHold)
        ProjectStatusBadge(status: .completed)
        ProjectStatusBadge(status: .archived)
    }
    .padding()
    .background(ColorPalette.background)
}
