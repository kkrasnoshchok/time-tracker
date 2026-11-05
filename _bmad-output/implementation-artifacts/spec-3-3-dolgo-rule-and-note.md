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
