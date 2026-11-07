import SwiftUI

/// Pure facts about a swatch, kept out of the view so tests can pin them.
enum ToneSwatch {
    /// Russian name read by VoiceOver and shown in the tooltip.
    static func displayName(_ tone: CategoryTone) -> String {
        switch tone {
        case .clay: "Глина"
        case .ochre: "Охра"
        case .moss: "Мох"
        case .lagoon: "Лагуна"
        case .slate: "Сланец"
        case .plum: "Слива"
        case .rose: "Роза"
        case .taupe: "Тауп"
        }
    }

    /// A stored hex (even an old bright one) selects the tone it maps to.
    static func isSelected(_ tone: CategoryTone, storedHex: String) -> Bool {
        CategoryTone(storedHex: storedHex) == tone
    }

    static func accessibilityName(_ tone: CategoryTone, isSelected: Bool) -> String {
        isSelected ? "\(displayName(tone)), выбран" : displayName(tone)
    }
}

/// Row of eight tone swatches. The chosen one is marked by a ring and a check,
/// so color is never the only carrier. Like a `<RadioGroup>` of colored buttons:
/// `ForEach(CategoryTone.allCases)` is `tones.map(...)`, and `onSelect` is the
/// `onChange` callback prop. The parent owns the value (a controlled component).
struct ToneSwatchPicker: View {
    let storedHex: String
    let onSelect: (CategoryTone) -> Void

    static let swatchSize: CGFloat = 24

    var body: some View {
        HStack(spacing: Space.x1) {
            ForEach(CategoryTone.tieBreakOrder, id: \.self) { tone in
                swatch(tone)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Цвет категории")
    }

    private func swatch(_ tone: CategoryTone) -> some View {
        let selected = ToneSwatch.isSelected(tone, storedHex: storedHex)
        return Button { onSelect(tone) } label: {
            ZStack {
                Circle().fill(ColorToken.category(tone).color)
                if selected {
                    Image(systemName: "checkmark")
                        .typeRole(.micro)
                        .foregroundStyle(Color.onActionPrimary)
                }
            }
            .frame(width: Self.swatchSize - 8, height: Self.swatchSize - 8)
            .padding(4)
            .overlay {
                if selected {
                    Circle().strokeBorder(Color.textPrimary, lineWidth: 1.5)
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(ToneSwatch.displayName(tone))
        .accessibilityLabel(ToneSwatch.accessibilityName(tone, isSelected: selected))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
