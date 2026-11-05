---
title: 'Stable list width and Journal guard'
type: 'feature'
created: '2026-11-05'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-3-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Story 3.4 of `_bmad-output/planning-artifacts/epics.md`: a selected Journal row still uses the system blue selection, and the Journal screen is not under the token guard. The list width fix from `spec-window-fixes-and-journal-hotkey.md` has not been re-checked after the 3.1–3.3 restyle (the «долго» note widened the trailing group).

**Approach:** Draw selection ourselves: selected row = `surface-inset` fill plus `HairlineRing` at `Radius.row`; running row = `surface-inset` without a ring; selected and running shows both. Hide the native `List` highlight. Add `App/Journal/JournalEntriesView.swift` to `scripts/token-guard-paths.txt` and run the guard. Verify list width in the running app; change split-view layout code only if a regression is seen.

## I/O & Edge-Case Matrix

| Scenario | State | Expected |
|----------|-------|----------|
| Finished, selected | click or arrow | `surface-inset` + ring, no blue |
| Running, not selected | — | `surface-inset`, no ring |
| Running and selected | — | `surface-inset` + ring |
| Select / deselect / detail appears | repeated | list width unchanged |

</frozen-after-approval>

## Implementation Notes

- Selection is read from the parent (`selection == entry.id`) and passed to `EntryRow` as `isSelected`.
- Owed by the author in the running app (retro A6; an author-reported tick is enough):
  - [ ] List width does not change on select, deselect, or when the detail pane appears
  - [ ] No system blue on a selected row; ring visible; click and arrow keys still select
  - [ ] Populated, running, long and empty states match the row and day-header spec
- Changed `JournalEntriesView.swift`: `EntryRow` takes `isSelected`; fill is `surface-inset` when running or selected; ring only when selected; `listRowBackground(Color.clear)` and `scrollContentBackground(.hidden)` on the list. No split-view layout code touched (no regression seen yet; needs the author's run).
- Added the file to `scripts/token-guard-paths.txt`. Seen: guard exit 0, guard fixtures green, swiftlint 0 violations, App tests 67 passed.
- Not verified: that `listRowBackground` removes the native macOS blue highlight. If blue still shows in the running app, the next step is `.tint(Color.clear)` or a custom selection. Review layers skipped (no explicit instruction to spawn subagents).
- Swift concepts owed: `HSplitView` and `frame(minWidth:idealWidth:maxWidth:)` (flex-basis, min/max-width), `overlay` with a conditional, passing derived state as a prop.
- Author feedback after the first run (renegotiated; supersedes the matrix row "running and selected shows both"): (1) list width still changed; (2) arrow keys did not move selection; (3) running row = fill only, selected non-running row = ring only. Fixes: `HSplitView` replaced by `HStack` with a fixed 400pt detail pane (list width depends only on the window; the divider is no longer draggable); explicit `onKeyPress` up/down arrows over the flattened entries; fill only when running, ring only when selected and not running. Causes for (1) and (2) were not confirmed by diagnostics, only reasoned (detail Form intrinsic width; unknown for arrows). Guard 0, swiftlint 0, build succeeded; needs the author's run again.
- Second author feedback: the native blue still filled the selected row. Fix: dropped `List(selection:)`; selection is our own state (tap sets it, arrow keys move it, `ScrollViewReader` keeps it visible, `.focusable()` for key focus, `isSelected`/`isButton` traits for VoiceOver). Selected = `surface-card` (white) + ring; running = `surface-inset`; no new token. Build and guard green; needs the author's run.
