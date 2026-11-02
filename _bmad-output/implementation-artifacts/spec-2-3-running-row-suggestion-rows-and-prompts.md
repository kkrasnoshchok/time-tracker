---
title: 'Running row, suggestion rows and prompts'
type: 'feature'
created: '2026-11-02'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-2-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Below the input row, the Palette still uses the old look: a `.callout` running row, 7pt-padded rows with icons and ad-hoc spacing, and red/orange prompt text. Story 2.3 of `_bmad-output/planning-artifacts/epics.md` restyles them in the Epic 1 tokens. The Palette also has no ↑/↓ selection today (Core has none; rows only click, Tab takes the first suggestion), but the story requires a selected row.

**Approach:** Restyle in `App/Palette/PaletteView.swift` only: running row on `surface-canvas` (title in `body`; category dot + name and tabular elapsed time in `micro`); suggestion rows 40px, radius 10, name in `body`, hint at the right in `micro`/`text-secondary`, no icon, selected row on `surface-inset`, hover changes nothing; prompts rendered with `ErrorStrip` (no red/orange), wording and keys unchanged. Author's decision: ↑/↓ selection is added in `App/` (Core untouched) as a pure, tested `PaletteSelection` (↓ from none selects the first row, ↑ from the first row clears the selection, both clamp at the ends, selection resets whenever `items` change); Enter on a selected `.suggestion` puts its text in the field (same as a click), with no selection or on other rows Enter behaves as before. Reduce Motion: the panel uses no show/hide animation (`animationBehavior = .none`) and no gradient, bounce or spring is introduced. Swift concepts (`@ViewBuilder`, `@Environment(\.accessibilityReduceMotion)`/the AppKit equivalent) are explained afterwards via TypeScript/React analogies.

</frozen-after-approval>

## Implementation Notes

- Files: new `App/Palette/PaletteSelection.swift` + `AppTests/PaletteSelectionTests.swift`; changed `App/Palette/PaletteView.swift`, `App/Palette/PalettePanel.swift` (motion preference, tested in `PalettePanelTests`), `App/Palette/PaletteController.swift`, `App/Design/Spacing.swift` (`Radius.row` = 10, `Space.suggestionRowHeight` = 40, pinned in `DesignTokenTests`). Core and `scripts/token-guard-paths.txt` untouched (the guard entry is Story 2.4).
- TDD: selection and token tests seen failing first; the view restyle is checked by build, `swiftlint`, `scripts/check-tokens.sh` (run it on `App/Palette/PaletteView.swift` content even though the path is not listed yet) and the author in the running Palette.
- Deferred items from the 2.2 review (stale `TextSelection`, VoiceOver of the field, tag-layer drift) are Story 2.4 and stay there.

## Review Triage Log

- medium, patched: running row lost the title/category fallback and VoiceOver grouping; now falls back to the category name and combines children.
- low, patched: `.isButton` trait was on every row; now only on suggestions.
- false: highlighted non-suggestion rows ignore Enter. Spec says so explicitly (Enter on other rows behaves as before).
- false: `PaletteController.swift` untouched. No change was needed there; the Files list was an upper bound.
- low, rejected: Enter logic in the view. It only dispatches to the tested `PaletteSelection` index; the fix would add a new public API.
- low, rejected: stale index after items change. `.onChange(of: items)` resets it; guarded by `indices.contains`.
- low, rejected: ErrorStrip for non-error prompts, hint text, scroll-into-view, extra edge-case tests. Specified by the story or not reachable (max few rows).
- false: guard on PaletteView. `check-tokens.sh` run against the file's path exits 0; the path is added in Story 2.4.
