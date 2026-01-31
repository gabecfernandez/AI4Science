import SwiftUI

/// Tag/keyword input component
public struct TagInput: View {
    let label: String
    let placeholder: String
    @Binding var tags: [String]

    @Environment(\.theme) var theme
    @State private var inputText = ""
    @FocusState private var isFocused: Bool

    public init(
        _ label: String,
        placeholder: String = "Add tag...",
        tags: Binding<[String]>
    ) {
        self.label = label
        self.placeholder = placeholder
        self._tags = tags
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(Typography.labelMedium)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Tags display
                if !tags.isEmpty {
                    FlexibleView(
                        data: tags,
                        spacing: Spacing.xs,
                        alignment: .leading
                    ) { tag in
                        HStack(spacing: Spacing.xs) {
                            Text(tag)
                                .font(Typography.labelSmall)
                                .foregroundColor(.white)

                            Button(action: {
                                tags.removeAll { $0 == tag }
                            }) {
                                IconAssets.close
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(ColorPalette.utsa_primary)
                        .cornerRadius(BorderStyles.radiusSmall)
                    }
                }

                // Input field
                HStack(spacing: Spacing.sm) {
                    TextField(placeholder, text: $inputText)
                        .focused($isFocused)
                        .onSubmit {
                            addTag()
                        }

                    if !inputText.isEmpty {
                        Button(action: addTag) {
                            IconAssets.add
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(ColorPalette.utsa_primary)
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
            }
        }
    }

    private func addTag() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        inputText = ""
    }
}

// MARK: - FlexibleView for tag layout
struct FlexibleView<Data: RandomAccessCollection, Content: View>: View
where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    var body: some View {
        var width: CGFloat = .zero
        var height: CGFloat = .zero

        return ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
            ForEach(data, id: \.self) { item in
                content(item)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > UIScreen.main.bounds.width - Spacing.base * 2 {
                            width = 0
                            height -= (d.height + spacing)
                        }
                        let result = width
                        width -= d.width + spacing
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        return result
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        TagInput(
            "Keywords",
            placeholder: "Add keyword...",
            tags: .constant(["disease", "classification", "tomato"])
        )

        Spacer()
    }
    .screenPadding()
    .background(ColorPalette.background)
}
