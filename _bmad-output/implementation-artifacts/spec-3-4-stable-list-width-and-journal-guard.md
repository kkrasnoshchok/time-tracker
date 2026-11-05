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
- Third author feedback: white fill plus ring was not visible enough; the author wants a background colour, not a ring. Added token `surface-selected` `#E1DEE6` (pinned in `DesignTokenTests`, seen FAIL first; added to DESIGN.md). Selected row = that fill, no ring; running = `surface-inset`. Supersedes the ring in the story AC. Tests, guard, swiftlint green; needs the author's look.

### Review Findings

Code review of `78f4c16..HEAD` (2026-11-05), full mode, four layers (Blind Hunter, Edge Case Hunter, Verification Gap, Acceptance Auditor). 3 `decision-needed`, 0 `patch`, 4 `defer`, 11 rejected.

- [x] [Review][Decision] Resolved (c): keep the running fill, recorded in DESIGN.md. Selected and running row shows no selection cue — `rowFill` returns `surfaceInset` before it checks `isSelected`, so a selected running row looks the same as an unselected one (only the VoiceOver trait differs). DESIGN.md says `surface-selected` makes the selected row differ from the running row, and the frozen matrix says "both". Options: (a) selected fill wins over running; (b) keep running fill and add a second cue (e.g. `HairlineRing`) when both; (c) accept as is and say so in DESIGN.md. [App/Journal/JournalEntriesView.swift:rowFill]
- [x] [Review][Patch] Done: `JournalSelection.next` in `TimeTrackerCore` (7 tests, seen FAIL first), the view calls it. Arrow-key selection logic lives in the view and has no test — `moveSelection` flattens, clamps and picks the start row when nothing is selected; no test touches it, it already failed once in the running app, and CLAUDE.md puts logic in Core with TDD. Options: (a) pure `JournalSelection` in `TimeTrackerCore` with tests (new public type); (b) pure internal function in `App/` with tests in `AppTests`; (c) accept, rely on the author's manual check. [App/Journal/JournalEntriesView.swift:moveSelection]
- [x] [Review][Decision] Resolved (b), author confirmed it looks good: no lighter fill reaches 4.5:1 without matching the canvas (`#F3F0F8` is 1.05:1 against `#F7F7F5`), so darkening could not work and the fill is unchanged; a selected row now uses `text-primary` for secondary text. `text-secondary` on `surface-selected` is below AA — measured 3.83:1 (`#766A7C` on `#E1DEE6`) against 5.09:1 on white and 4.31:1 on `surface-inset`; time, category name, «долго» and caption text on the selected row are small text. The author picked the fill colour after two "not visible enough" rounds. Options: (a) darken the fill slightly until secondary text reaches 4.5:1; (b) use `text-primary` for secondary text on the selected row; (c) accept and record the number in DESIGN.md. [App/Design/ColorToken.swift, DESIGN.md]
- [x] [Review][Defer] Closed, author confirmed arrows work. Arrow keys may not work right after a click, or while the search field has focus — nothing sets focus on tap; `.focusable()` is on the `List`. Unverified medium; settle with the author's run: click a row, press ↓/↑; then click into the search field, press ↓. — deferred: needs the running app
- [x] [Review][Defer] VoiceOver may not select a row — `onTapGesture` plus `.isButton` with `children: .ignore` and no `accessibilityAction`. Unverified medium; settle with a VoiceOver check: VO+Space on a row must select it and announce "selected" (same open item as the 3-3 deferral). — deferred: needs the running app
- [x] [Review][Defer] Closed, author confirmed it looks fine. Detail pane content may overflow the fixed 400pt width — the `Form` content is not constrained and the cause of the earlier width change was never confirmed by diagnostics. Unverified medium; settle with the author's width check using a long title, note and tags. — deferred: needs the running app
- [x] [Review][Defer] `epic-3-context.md` (line 24) and the frozen block of this spec still describe `surface-inset` + `HairlineRing`; the shipped rule is `surface-selected`, no ring. Fix edits agent-context files and the frozen block. — deferred: edit on the author's say-so

#### Rejected

- Spec Intent/matrix and Implementation Notes are stale or contradict each other (BH, ECH, AA): fix is to edit the spec under review; the supersession is recorded in the notes.
- Owed manual checks unticked while spec `status` is `done` and sprint status is `review` (AA, BH): process state, not code; fix edits the spec. The checks stay owed to the author.
- Narrow window clips the 400 + 1 + 400 layout (ECH, BH) — false: `JournalRootView.swift:20` sets `minWidth: 900`, above 801.
- Divider no longer draggable (ECH, AA, BH): requested by the author in the first feedback round and recorded in the notes. Low.
- No way to deselect (ECH) — false: the detail view receives a close action that sets `selection = nil`.
- Stale `selection` after a filter or period change (BH, ECH): the detail pane shows the "Выберите запись" placeholder and the arrow keys restart from an end. Low; the fix adds an `onChange` branch.
- Lost native keyboard behaviour: Return/Space, Home/End/PageUp/PageDown, type-select, visible focus ring, modified arrows (BH, ECH, AA): low for a single-selection journal; the selected fill carries the state. Revisit if the author asks.
- `proxy.scrollTo` without an anchor (BH): a nil anchor scrolls the minimum distance; no failure shown. Low.
- No test that `rowFill` picks the token (VG, ECH): visual glue; the author's look settles it. Low.
- Clicks in the row inset margins do not select (ECH): low.
- `detailWidth = 400` is a magic number, no gap between rows after hiding separators (BH): cosmetic.
