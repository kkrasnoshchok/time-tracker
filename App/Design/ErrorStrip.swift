import SwiftUI

/// Calm one-line failure notice. It has no timer and no dismiss: the owner
/// removes it (like conditionally rendering `{error && <ErrorStrip/>}`).
/// The optional action is a `(label, handler)` pair, like a `{label, onClick}` prop.
struct ErrorStrip: View {
    private let message: String
    private let action: (label: String, handler: () -> Void)?

    init(_ message: String, action: (label: String, handler: () -> Void)? = nil) {
        self.message = message
        self.action = action
    }

    var body: some View {
        HStack(spacing: Space.x2) {
            Image(systemName: "exclamationmark.circle")
                .imageScale(.medium)
                .foregroundStyle(Color.textPrimary)
                .accessibilityHidden(true)
            Text(message)
                .typeRole(.body)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .help(message)
            Spacer(minLength: Space.x2)
            if let action {
                Button(action.label, action: action.handler)
                    .buttonStyle(.ghost)
                    .fixedSize()
            }
        }
        .padding(.horizontal, Space.x3)
        .padding(.vertical, Space.x2)
        .background(Color.surfaceInset, in: RoundedRectangle(cornerRadius: Radius.input))
    }
}
