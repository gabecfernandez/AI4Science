import SwiftUI

/// Specialized search bar component
public struct SearchBar: View {
    let placeholder: String
    let onSearch: (String) -> Void
    let onClear: () -> Void
    @Binding var text: String

    @Environment(\.theme) var theme
    @FocusState private var isFocused: Bool

    public init(
        placeholder: String = "Search",
        text: Binding<String>,
        onSearch: @escaping (String) -> Void = { _ in },
        onClear: @escaping () -> Void = {}
    ) {
        self.placeholder = placeholder
        self._text = text
        self.onSearch = onSearch
        self.onClear = onClear
    }

    public var body: some View {
        HStack(spacing: Spacing.sm) {
            IconAssets.search
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(
                    isFocused ? ColorPalette.utsa_primary : ColorPalette.onSurfaceVariant
                )

            TextField(placeholder, text: $text)
                .textContentType(.none)
                .focused($isFocused)
                .onSubmit {
                    onSearch(text)
                }

            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onClear()
                }) {
                    IconAssets.clear
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(ColorPalette.surface)
        .cornerRadius(BorderStyles.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                .stroke(
                    isFocused ? ColorPalette.utsa_primary : ColorPalette.divider,
                    lineWidth: 1.5
                )
        )
        .accessibilityLabel("Search")
        .accessibilityValue(text)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        SearchBar(text: .constant(""))

        SearchBar(
            placeholder: "Search projects...",
            text: .constant("disease")
        )
    }
    .screenPadding()
    .background(ColorPalette.background)
}
