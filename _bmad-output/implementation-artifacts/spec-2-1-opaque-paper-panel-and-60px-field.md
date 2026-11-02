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
