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

### Review Findings

Code review 2026-11-02, commit `ea9aea8`, layers: blind-hunter, edge-case-hunter, verification-gap, acceptance-auditor.

- [x] [Review][Decision] (resolved: option a, applied as a patch) Tab ignores the highlighted suggestion — each suggestion row shows the `⇥` hint, but `.onKeyPress(.tab) { viewModel.tab() }` still completes the category or takes the first suggestion. With the 2nd row highlighted, Tab fills the 1st. Options: (a) Tab fills the highlighted suggestion when one is selected, otherwise as before; (b) leave as is and record that Tab is independent of the highlight. [App/Palette/PaletteView.swift:118]
- [x] [Review][Decision] (resolved: option b, applied) Untitled running entry shows the category twice — `Text(entry.title ?? entry.category?.name ?? "")` in the title slot plus the dot+name group on the right (and VoiceOver `.combine` reads both). Options: (a) leave the title slot empty when `title == nil`; (b) keep the fallback and hide the right-hand name in that case; (c) accept. [App/Palette/PaletteView.swift:155]
- [x] [Review][Patch] Enter-on-selected-suggestion rule has no test — the branch lives in `PaletteView.submit()`; `PaletteSelectionTests` cover only index moves. Move the rule into `PaletteSelection` (e.g. `fillText(in items:) -> String?`, App-internal), test: selected suggestion → its text, no selection, out-of-range index, `.stopCurrent`/`.repeatLast`/`.createCategory` → nil; TDD, FAIL first. [App/Palette/PaletteView.swift:240]
- [x] [Review][Patch] `moveUp`/`moveDown` with a shrunk `count` is untested — the `min(current, count)` branch is never exercised; add a test (index 2, `moveUp(count: 1)` → 0; `moveDown(count: 1)` from index 2 → 0). [App/Palette/PaletteSelection.swift:15]

#### Rejected

- false: Enter on a highlighted `.stopCurrent` / `.repeatLast` / `.createCategory` does something other than the row says. `computeItems` returns `.stopCurrent` or `.repeatLast` only with empty input, where `enter()` runs exactly that action; `.createCategory` is only shown for an unknown word, where `enter()` raises the create-category prompt the row names.
- false: `.onChange(of: items)` needs `Equatable`. `PaletteItem` is `Equatable`.
- low, rejected: Enter fills a suggestion while a prompt is visible. Needs an arrow press after the prompt; filling clears the prompt and the user chose the row.
- low, rejected: stale highlight when `items` stay equal. Same items means the same rows; suggestions only exist for non-empty input, and after `reset()` the empty-input rows fall through to `enter()`.
- low, rejected: ↑/↓ always `.handled` (caret and IME). Rare in a single-line field, the fix adds a guard.
- low, rejected: no scroll-into-view. Rows are at most 5 titles or the matching category names, the panel grows with its content.
- low, rejected: nil category or empty title in the running row, long title/category squeezing the clock. A started entry always has a category; long-name squeeze is cosmetic.
- low, rejected: `ErrorStrip` for non-error prompts. The spec asks for it.
- low, rejected: VoiceOver announcement of the highlight, Dynamic Type at a fixed 40px, Reduce Motion read from the environment, hover not tested, `onChange` wiring untested, removed dividers, 20pt vs 16pt text inset. Covered by spec choices or Story 2.4 manual checks; no named harm.
- rejected (edits the spec): `PaletteController.swift` listed in Files but not changed.
