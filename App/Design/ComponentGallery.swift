import SwiftUI

/// A row showing one button kind in each state. Pressed and focused are forced
/// through `ButtonShellBody`, since a preview cannot press or focus a button.
private struct StateRow: View {
    let kind: ButtonKind

    var body: some View {
        HStack(spacing: Space.x4) {
            ButtonShellBody(kind: kind, appearance: .resolve(isEnabled: true, isPressed: false, isFocused: false),
                            label: Text("Normal"))
            ButtonShellBody(kind: kind, appearance: .resolve(isEnabled: true, isPressed: true, isFocused: false),
                            label: Text("Pressed"))
            ButtonShellBody(kind: kind, appearance: .resolve(isEnabled: false, isPressed: false, isFocused: false),
                            label: Text("Disabled"))
            ButtonShellBody(kind: kind, appearance: .resolve(isEnabled: true, isPressed: false, isFocused: true),
                            label: Text("Focused"))
        }
    }
}

/// `#Preview` renders in Xcode's canvas without running the app: the
/// equivalent of a Storybook story.
#Preview("Buttons and card") {
    VStack(alignment: .leading, spacing: Space.x6) {
        StateRow(kind: .primary)
        StateRow(kind: .ghost)
        VStack(alignment: .leading, spacing: Space.x3) {
            Text("Card").typeRole(.bodyEmphasis).foregroundStyle(Color.textPrimary)
            HStack(spacing: Space.x2) {
                Button("Save") {}.buttonStyle(.primary)
                Button("Cancel") {}.buttonStyle(.ghost)
            }
        }
        .card()
    }
    .padding(Space.x6)
    .background(Color.surfaceCanvas)
}
