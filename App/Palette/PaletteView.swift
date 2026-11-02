import SwiftUI
import TimeTrackerCore

struct PaletteView: View {
    @Bindable var viewModel: PaletteViewModel
    let model: AppModel
    let onClose: () -> Void
    @FocusState private var focused: Bool

    private static let inputHint = "Категория название #тег -20m"

    var body: some View {
        VStack(spacing: 0) {
            inputRow
            if let entry = model.running {
                Divider()
                runningRow(entry)
            }
            if !viewModel.items.isEmpty {
                Divider()
                ForEach(Array(viewModel.items.enumerated()), id: \.offset) { _, item in
                    itemRow(item)
                }
            }
            if let prompt = viewModel.prompt {
                Divider()
                promptRow(prompt)
            }
        }
        .frame(width: 640)
        // The panel is always light paper, so unstyled text must not follow a dark system theme.
        .foregroundStyle(Color.textPrimary)
        .background(Color.surfaceCard, in: panelShape)
        .clipShape(panelShape)
        .hairlineRing(panelShape, variant: .palette)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            focused = true
        }
        .onAppear { focused = true }
    }

    private var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Radius.panel, style: .continuous)
    }

    private var inputRow: some View {
        HStack(spacing: Space.x3) {
            Image(systemName: "magnifyingglass")
                .typeRole(.paletteInput)
                .fontWeight(.light)
                .foregroundStyle(Color.textTertiary)
                .accessibilityHidden(true)
            TextField(
                "",
                text: $viewModel.input,
                prompt: Text(Self.inputHint).foregroundStyle(Color.textTertiary)
            )
                .textFieldStyle(.plain)
                .typeRole(.paletteInput)
                .foregroundStyle(Color.textPrimary)
                .accessibilityLabel(Self.inputHint)
                .focused($focused)
                .onSubmit { handle(viewModel.enter()) }
                .onKeyPress(.tab) {
                    viewModel.tab()
                    return .handled
                }
                .onKeyPress(.escape) {
                    if !viewModel.cancelPrompt() { onClose() }
                    return .handled
                }
        }
        .padding(.horizontal, Space.x4)
        .frame(height: Space.paletteFieldHeight)
    }

    private func runningRow(_ entry: TimeEntry) -> some View {
        HStack(spacing: 8) {
            CategoryDot(storedHex: entry.category?.colorHex ?? "")
            Text([entry.category?.name, entry.title].compactMap { $0 }.joined(separator: " · "))
                .lineLimit(1)
            Spacer()
            Text(DurationFormat.clock(model.elapsed)).monospacedDigit()
        }
        .font(.callout)
        .foregroundStyle(Color.textSecondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func itemRow(_ item: PaletteItem) -> some View {
        switch item {
        case .stopCurrent:
            row(icon: "stop.fill", text: "Остановить текущую запись", hint: "⏎")
        case .repeatLast(let title, let category):
            let label = [category, title].compactMap { $0 }.joined(separator: " — ")
            row(icon: "arrow.counterclockwise", text: "Повторить: \(label)", hint: "⏎")
        case .createCategory(let name):
            row(icon: "plus.circle", text: "Создать категорию «\(name)»", hint: "⏎")
        case .suggestion(let text):
            Button { viewModel.input = text } label: {
                row(icon: "text.append", text: text, hint: "⇥")
            }
            .buttonStyle(.plain)
        }
    }

    private func row(icon: String, text: String, hint: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).frame(width: 20).foregroundStyle(Color.textSecondary)
            Text(text).lineLimit(1)
            Spacer()
            Text(hint).foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }

    private func promptRow(_ prompt: PalettePrompt) -> some View {
        let text: String
        var isError = false
        switch prompt {
        case .createCategory(let name):
            text = "Категории «\(name)» нет. ⏎ — создать и запустить, Esc — отмена."
        case .overlap(let count):
            text = "Пересекается с записями: \(count). ⏎ — всё равно, Esc — править."
        case .error(let message):
            text = message
            isError = true
        }
        return Text(text)
            .font(.callout)
            .foregroundStyle(isError ? Color.red : Color.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
    }

    private func handle(_ outcome: PaletteOutcome) {
        model.refresh()
        switch outcome {
        case .started, .stopped: onClose()
        default: break
        }
    }
}
