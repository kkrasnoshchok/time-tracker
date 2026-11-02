import SwiftUI

/// Draws the input shell for a given focus state. Split out so the gallery can
/// force the focused look, which a preview cannot trigger.
struct InputFieldShell<Content: View>: View {
    let isFocused: Bool
    let content: Content

    var body: some View {
        content
            .typeRole(.body)
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, Space.x3)
            .padding(.vertical, Space.x2)
            .frame(minHeight: 24)
            .background(Color.surfaceInput, in: RoundedRectangle(cornerRadius: Radius.input))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.input)
                    .strokeBorder(InputAppearance.borderToken(isFocused: isFocused).color, lineWidth: 1)
            }
    }
}

/// A text input wrapping the native `TextField`.
///
/// Why a view and not a `TextFieldStyle`: the public `TextFieldStyle` cannot
/// restyle a field on macOS, so we wrap it, like a `<Input>` component around
/// `<input>` in React.
///
/// `@Binding` is a two-way reference to state owned by the parent, like
/// passing `value` and `onChange` as one prop. `@FocusState` tracks whether
/// this field has keyboard focus, like `onFocus`/`onBlur` toggling a
/// `useState` flag.
struct InputField: View {
    private let placeholder: String
    @Binding private var text: String
    @FocusState private var isFocused: Bool

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        InputFieldShell(
            isFocused: isFocused,
            content: TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(Color.textTertiary)
            )
            .textFieldStyle(.plain)
            .focused($isFocused)
            .accessibilityLabel(placeholder)
        )
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
    }
}
