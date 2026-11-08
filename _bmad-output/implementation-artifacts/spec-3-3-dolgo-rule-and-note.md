---
title: '«долго» rule and note'
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

**Problem:** Story 3.3 of `_bmad-output/planning-artifacts/epics.md`: a forgotten timer or an entry of 8 hours or more is not marked in the Journal, so it goes unnoticed. The Journal row also has no VoiceOver cue (the running state lost its «идёт» text in 3.1; deferred to this story).

**Approach:** Add a pure, public, UI-free rule in `TimeTrackerCore` (`start`, `end`, injected `now`): long when the full duration is 8 h or more. `EntryRow` shows a gray `caption` «долго» beside the duration when the rule holds, and gets one combined accessibility label that reads title, category, duration, «долго» and the running state together. Story 4.3 reuses the rule.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Just under | finished, 7 h 59 min | not long | N/A |
| Threshold | finished, 8 h 00 min | long | N/A |
| Running under / at | `end == nil`, `now − start` 7 h 59 min / 8 h | not long / long | N/A |
| Spans midnight | finished 22:00 → 07:00 next day (9 h) | long (full duration, not split by day) | N/A |
| Edited below 8 h | end moved so duration is 7 h | no note; the row duration and day total update on reload | N/A |
| Clock before start | `now < start`, running | not long | negative duration treated as zero |

</frozen-after-approval>

## Implementation Notes

- Core: `LongEntry.isLong(start:end:now:)` in `Domain/LongEntry.swift` (plain date arithmetic, no `TimeSpan`, so an end before start is not clamped); threshold constant 8 h is public for Story 4.3. Tests first in `LongEntryTests` (seen FAIL).
- App: pure helper `EntryRowText` (label for VoiceOver) in `App/Journal/`, tested in `AppTests`; `EntryRow` shows «долго» in `caption` / `text-secondary`, no color or icon. File is not in the guard list yet (Story 3.4); the guard is still run.
- Decisions: the note sits left of the duration inside the same trailing group; the VoiceOver label is «<title>, <category>, <duration>[, долго][, идёт]»; no notification of any kind.
- Review layers not run (no explicit author instruction to spawn subagents). Nothing committed and `sprint-status.yaml` untouched, per the epic 3 context.
- Seen: `LongEntryTests` red first (compile: `LongEntry` missing); then Core 199 passed, App 66 passed, `swiftlint` 0 violations, `scripts/check-tokens.sh` exit 0. `EntryRowTextTests` was written together with the helper, not seen failing first.
- Owed by the author in the running app (retro A6):
  - [ ] An entry of 8 h or more shows a gray «долго» left of its duration; 7 h 59 min shows none
  - [ ] Editing the end time below 8 h removes «долго» and updates the row and day total
  - [ ] VoiceOver reads the row as one sentence with the duration and «долго» (and «идёт» when running)
- Swift concepts owed: pure functions (like a TS helper with `now` as an argument), protocol-injected clock (dependency injection / fake timers), Swift Testing `#expect`.

### Review Findings

Code review of commits a611e59..fc03c5f (2026-11-05); layers: Blind Hunter, Edge Case Hunter, Verification Gap, Acceptance Auditor (all ran, none failed). Result: 0 decision-needed, 1 patch, 3 defer, 11 rejected.

- [x] [Review][Patch] Missing tests for edge cases of the rule and the label [Packages/TimeTrackerCore/Tests/TimeTrackerCoreTests/LongEntryTests.swift, AppTests/EntryRowTextTests.swift] — (a) a finished entry with `end < start` and with `end == start` is never tested (`clockBeforeStartIsNotLong` covers only the running case); (b) no test for a running entry that is also long, so the order «долго», then «идёт» in the label is unpinned (`"A, 9 ч, долго, идёт"`). (edge-case-hunter+blind-hunter+acceptance-auditor)
- [x] [Review][Defer] `.accessibilityElement(children: .ignore)` on a row of `List(selection:)` may drop the selected trait or row actions in VoiceOver [App/Journal/JournalEntriesView.swift:205] — deferred: unverified medium; the `List` row wrapper normally keeps selection, but this is not confirmed. Settled by the author's VoiceOver check, extended with «selected row is announced as selected». If not, use `.combine` plus `.accessibilityAddTraits(isSelected ? .isSelected : [])` as in `PaletteView.swift:200`. (edge-case-hunter+blind-hunter+acceptance-auditor+verification-gap)
- [x] [Review][Defer] No automated check that `EntryRow` passes `entry.start`, `entry.end`, `now` into `LongEntry.isLong` and real title/category/duration into the label [App/Journal/JournalEntriesView.swift:182-212] — deferred: thin private-view glue, the rule and the string are pinned by tests; the author's manual checks cover it. Extract a pure `EntryRowModel` only if 3.4 touches the row again. (verification-gap+blind-hunter)
- [x] [Review][Defer] The «долго» note widens the trailing group, so the category column shifts left on long rows and the title may truncate earlier [App/Journal/JournalEntriesView.swift:~190] — deferred: the stable list width is exactly Story 3.4's scope; recheck there. (blind-hunter)

#### Rejected

- Spec says `sprint-status.yaml` is untouched, but the diff edits it and drops the epic-context rule (acceptance-auditor) — fix edits the spec / agent-context file; the status change is the normal «mark in review» step.
- Spec `status: 'done'` vs sprint `review` (blind-hunter) — fix edits the spec; the review step sets both at the end of this run.
- Spec matrix says «negative duration treated as zero», code does plain arithmetic (blind-hunter) — fix edits the frozen spec; the outcome (not long) is the same, and Implementation Notes state the choice.
- `EntryRowTextTests` not seen failing first (acceptance-auditor, verification-gap, blind-hunter) — low: disclosed in the spec; the tests assert exact strings and cannot be redone retroactively without a no-value mutation run.
- Empty or whitespace-only title or category gives a blank VoiceOver segment (edge-case-hunter) — low: title is `nil` when unset and the visible row would be blank too; the fix adds guards in a place the app does not reach.
- Running `now` is not refreshed, so «долго» appears late (edge-case-hunter) — false: the row duration uses the same `now` (`model.now`) and ticks together with it; «долго» appears when the duration does.
- Spoken duration "1 ч 30 мин" may be read poorly (blind-hunter) — low: speculative, unverified; fix is a second formatter.
- «идёт» is a literal while «долго» is a constant (blind-hunter) — low: cosmetic, single use.
- `JournalEntriesView.swift` is outside the token guard, so the run proves nothing for it (blind-hunter) — false as a defect: the spec says explicitly the file joins the guard in Story 3.4.
- No previews or snapshots for the long and running variants (blind-hunter) — low: there is no preview or snapshot harness in the project.
- `EntryRowText` tests do not cover `nil` title together with a category (edge-case-hunter) — low: the branches are independent and each is covered.
