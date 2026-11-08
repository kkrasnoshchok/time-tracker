---
title: '«долго» in the popover and menu bar guard'
type: 'feature'
created: '2026-11-05'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-4-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Story 4.3 of `_bmad-output/planning-artifacts/epics.md`: the popover does not mark a running timer that has lasted 8 hours or more, so a forgotten timer goes unnoticed when the author opens it. `App/MenuBar` is also not yet in the token guard list.

**Approach:** Add a pure helper in `App/MenuBar/PopoverText.swift` that returns the «долго» note for a running entry, reusing `LongEntry.isLong` from Core (no new rule). `RunningTimerView` shows it as a gray `caption` beside the elapsed time, with no color, alarm or notification. Add `App/MenuBar` to `scripts/token-guard-paths.txt` and make the guard pass.

## I/O & Edge-Case Matrix

| Scenario | State | Expected |
|----------|-------|----------|
| Under threshold | running 7h59m (injected `now`) | no note |
| At threshold | running 8h00m | «долго» beside the elapsed time |
| Over threshold | running 26h | «долго» (spans midnight, full duration) |
| Idle | no running entry | no note, idle view unchanged |
| Guard | `App/MenuBar` listed | `scripts/check-tokens.sh` exits 0 |

</frozen-after-approval>

## Implementation Notes

- Tests first in `AppTests/PopoverTextTests.swift` (seen FAIL), fixed dates only: no `Date()`, no `sleep`.
- Note text comes from `EntryRowText.longNote` so the word lives in one place. Style: `typeRole(.caption)` + `Color.textSecondary`, baseline-aligned with the timer digits; added to the elapsed text's VoiceOver reading.
- Swift concepts from Story 3.3 (pure functions, injected clock) are only cross-referenced.
- Unverified until the running app: baseline alignment of the caption next to the 32pt timer in the 340pt popover.
- Done: `PopoverText.longNote(start:now:)` and `elapsedAccessibilityLabel(elapsed:isLong:)`, `RunningTimerView.elapsedRow` (baseline-aligned caption, VoiceOver reads time plus «долго»), `App/MenuBar` added to `scripts/token-guard-paths.txt`.
- Seen: `PopoverTextTests` red first (compile: members missing); then App tests succeeded, Core 208 passed, swiftlint 0, `check-tokens.sh` exit 0, `test-check-tokens.sh` passed.
- Review layers skipped (no explicit instruction to spawn subagents). Owed by the author in the running app: [ ] with a timer running 8h+ (shift start in a debug store) the gray «долго» sits beside the 32pt timer on the baseline and fits the 340pt popover.
