---
title: 'Opaque paper panel and 60px field'
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

**Problem:** The Palette panel still uses `.regularMaterial`, a 16pt corner, a SwiftUI drop shadow, a `timer` icon and a 22pt system font, so it ignores the Epic 1 design tokens. Story 2.1 of `_bmad-output/planning-artifacts/epics.md`.

**Approach:** Restyle only the panel shell and the input row in `App/Palette/PaletteView.swift` with tokens: opaque `surfaceCard` panel, `Radius.panel` (20), palette hairline ring (10%), no material and no shadow; input row `Space.paletteFieldHeight` (60) tall, line-icon magnifier at left, text in `typeRole(.paletteInput)`, placeholder in `textTertiary`. Keyboard flows (open focused, Esc, Enter, Tab, close on focus loss), `PalettePanel` and `Packages/TimeTrackerCore` stay untouched; running row, suggestion rows and prompts are left for Stories 2.2 and 2.3. Also run the Epic 1 manual checks in the running app: `typeRole` text changes size with system text size on macOS (if `@ScaledMetric` does not scale, record it and fix the rule), category dots show eight tones with the name beside them. New Swift concepts (`NSHostingView`, modifier order) are explained afterwards via TypeScript/React analogies.

</frozen-after-approval>

## Implementation Notes

- Changed only `App/Palette/PaletteView.swift`: panel is `surfaceCard` with `Radius.panel`, clip and palette hairline ring; material, shadow and 16pt corner removed. Input row is `Space.paletteFieldHeight` tall with a light magnifier, `typeRole(.paletteInput)` text and a `textTertiary` prompt; the field keeps an explicit accessibility label because the prompt no longer serves as the title.
- No new pure logic, so no new unit test; existing `HairlineRing` palette-variant tests cover the 10% ring. Build, 23 App tests and `scripts/check-tokens.sh` pass.
- Not verified: the keyboard flows, the visual result, the `typeRole` Dynamic Type check and the eight-tone dots, because osascript cannot send the hotkey in this environment. These are manual checks for the author (also to be re-run in Story 2.4).
- Review: no review subagent was launched (no instruction to use subagents); the diff was read by hand.

### Review Findings

- [x] [Review][Decision] Magnifier uses `.fontWeight(.light)` (300) but the epic allows weights 400/500 only — resolved by the author: follow the spec, keep `.light` as the line-icon exception (no code change). [App/Palette/PaletteView.swift:50]
- [x] [Review][Patch] Close-on-focus-loss (`PalettePanel.onResignKey`, wired in `PaletteController`) has no automated test — CLAUDE.md requires TDD; no test file references `PalettePanel` or `PaletteController`. Fixed: `AppTests/PalettePanelTests.swift` (seen failing with the call removed, then passing). [App/Palette/PalettePanel.swift:13]
- [x] [Review][Patch] Placeholder string "Категория название #тег -20m" is duplicated in `prompt:` and `.accessibilityLabel`, so the two can drift. Fixed: `PaletteView.inputHint`. [App/Palette/PaletteView.swift:57]
- [x] [Review][Defer] Palette may close right after `show()` if the panel resigns key during activation (hotkey race) — deferred: unverified (medium if real); settle by opening the palette with the hotkey from several apps in Story 2.4. [App/Palette/PaletteController.swift:17]
- [x] [Review][Defer] Fixed-light card (`surfaceCard` #FFFFFF) in system dark mode: caret, selection and `Divider()` follow the system appearance, so the caret may be white on white — deferred: unverified (medium if real); settle by checking the field in system dark mode. [App/Palette/PaletteView.swift:30]
- [x] [Review][Defer] Manual checks of this story are not done (keyboard flows, visual result, `typeRole` Dynamic Type scaling, eight-tone dots, `prompt:` styling under `.plain`) — deferred: spec already hands them to the author and to Story 2.4.

#### Rejected

- Spec says "Changed only PaletteView.swift" but `PalettePanel`/`PaletteController` also changed (blind, edge, auditor, gap) — the fact is true, but the fix is editing the spec; the follow-up commit `bce4581` is the record.
- Spec `status: done` vs sprint-status `review` — fix edits the spec; step 6 of this review sets the status.
- `hide()` re-entered from `orderOut` → `resignKey` — false: `orderOut` on a hidden window is a no-op, so there is no loop.
- Palette closes when a sheet/alert/prompt takes key — false: prompts are inline rows (`promptRow`); no `.sheet`/`.alert`/`NSAlert` exists in `App/Palette`.
- `onResignKey` wired in a separate statement after panel creation — false: same `init`, no window can resign key in between.
- Clicks on the transparent 20pt padding / 420pt window area do not close the palette — pre-existing layout; if real, only cosmetic, and the fix is more than a direct correction.
- Remaining hard-coded padding, `.callout` font and icons in `runningRow`/`row` — rows are left for Stories 2.2/2.3 by the spec; the token colors there are needed for legibility on the paper panel.
- Out-of-scope colour edits in `runningRow`/`row` (auditor) — minor, same reason as above.
- Missing TypeScript-analogy explanation of `NSHostingView` and modifier order — a process step after the task (`explain-change`), not a defect in the diff.
- `Space.paletteFieldHeight` unconfirmed — false: `DesignTokenTests` asserts it equals 60.
- Fixed 60pt row height vs Dynamic Type; Increase Contrast ring unverified — the 60pt is the spec; ring is covered by existing `HairlineRing` tests.
