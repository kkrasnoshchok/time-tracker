---
title: 'Day header with total'
type: 'feature'
created: '2026-11-04'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-3-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Story 3.2 of `_bmad-output/planning-artifacts/epics.md`: the Journal `DayHeader` is one line with a system-styled title and a short total, with no date and no «в фокусе» label. The total is computed only on reload (every 30 s), while rows update every second from `model.now`, so for a running entry header and rows disagree.

**Approach:** Restyle `DayHeader` in `App/Journal/JournalEntriesView.swift` in tokens: day name (`body-emphasis`: «Сегодня», «Вчера», weekday) with the date below in `caption` `text-secondary`; on the right the total in `day-total` with tabular figures and the label «в фокусе». Add a small pure Core function on `DayGroup` so the total of the day that holds the running entry is recomputed at the current `now`, keeping it in step with the rows.

Decisions made while planning: the total keeps its existing meaning, the time that falls inside the day (author decision), so an entry crossing midnight is split between days while its row shows the full duration; this is the one documented exception to "total equals the sum of rows". Total text uses `DurationFormat.short`, like rows. The label «в фокусе» sits under the total in `caption` `text-secondary`.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Today with a finished entry | day = today, 1 ч 30 мин | «Сегодня», date below, `1 ч 30 мин` in `day-total`, «в фокусе» | N/A |
| Yesterday / older | day = yesterday / 3 days ago | «Вчера» / weekday name; date in `caption` below | N/A |
| Running entry | group is today and has a running entry | total = reload-time total + (`now` − reload `now`), equals the sum of row durations | N/A |
| Reload and render `now` equal | `now` == reload `now` | total unchanged | N/A |
| `now` earlier than reload `now` | clock skew | no negative growth: total unchanged | N/A |
| Past day with no running entry | not live | total never changes with `now` | N/A |

</frozen-after-approval>

## Implementation Notes

- Core: `DayGroup` gets `asOf` (the `now` used for grouping) and `isLive` (true for the group of `startOfDay(now)` when a running entry is in the input); `liveTotal(at:)` returns `total + max(0, now − asOf)` when live, else `total`. Tests in `DayGroupingTests` first (seen FAIL).
- App: `DayHeader` takes `now` from `model.now` and calls `group.liveTotal(at:)`. Tokens only, no system styles; the file is not in the guard list yet (Story 3.4 adds it), the guard is still run.
- Rounding: `DurationFormat.short` floors to minutes, so the header and the sum of floored row durations can differ by up to one minute per row. Accepted, not changed.
- Seen: 4 new `DayGroupingTests` were red (compile: `liveTotal` missing) before the code; Core 191 passed; App 62 passed; build succeeded; `swiftlint` 0 violations; `scripts/check-tokens.sh` exit 0 and `scripts/test-check-tokens.sh` green. Named `liveTotal(at:)`, not `total(at:)`, because it clashed with the `total` property in `#expect`.
- Review layers were not run: spawning subagents needs an explicit author instruction and none was given. Nothing committed; `sprint-status.yaml` untouched (epic 3 context).
- Owed by the author in the running app (no Accessibility access for the agent, retro A6):
  - [x] Header shows day name + date below, total in `day-total` with «в фокусе» under it, in tokens
  - [x] With a running entry, the header total moves together with the running row
  - [x] Header still looks right in the list (sticky section header, no overlap with rows)
- Swift concepts owed after the story: `DayGroup` as a value type (like a readonly TS interface), `Text` formatting, computed value from props.

### Review Findings

Code review of the uncommitted 3-2 diff (2026-11-04); layers: Blind Hunter, Edge Case Hunter, Verification Gap, Acceptance Auditor (all ran, none failed). Result: 0 decision-needed, 1 patch, 2 defer, 10 rejected.

- [x] [Review][Patch] No tests for a running entry that started on an earlier day or with `start > now` [Packages/TimeTrackerCore/Tests/TimeTrackerCoreTests/DayGroupingTests.swift:123-160] — all four new tests start the running entry on the same day as `now`. Changing `day == today` to "the start day of the running entry" keeps them green, yet an overnight timer would freeze today's header and grow yesterday's. Add (a) a timer started day 2 23:00, grouped at day 3 01:00: today's group `isLive` and grows, day 2's stays fixed; (b) a running entry with `start > now`: `isLive == false`, total fixed. (verification-gap+edge-case-hunter+blind-hunter+acceptance-auditor)
- [x] [Review][Defer] No automated check that `DayHeader` feeds the ticking `model.now` into `liveTotal` [App/Journal/JournalEntriesView.swift:59] — deferred: thin presentational glue, App tests are kept minimal; settled by the author's manual check "total moves with the running row" (still unticked above).
- [x] [Review][Defer] The three manual checks of 3-2 are unticked (header look, total moves with the running row, sticky header without overlap) [spec Implementation Notes] — deferred: author-owed (retro A6); the author already gave feedback from the running app (see deferred-work).

#### Rejected

- Midnight rollover: the old «today» group keeps growing, the title flips to «Вчера» while the total still ticks (blind-hunter, edge-case-hunter, acceptance-auditor) — low: lasts until the next reload (≤30 s, once a day, only with the Journal open at midnight); the fix (clamp to end of day or a regroup trigger) adds a guard for a negligible effect.
- `asOf` and `isLive` enter the synthesized `Equatable` (blind-hunter, edge-case-hunter, verification-gap) — low: nothing compares `DayGroup` values (`ForEach(id: \.day)`, no `==` in App or Core); fix adds a custom `==`.
- Title uses `Calendar.current` while grouping takes an injected calendar (blind-hunter, edge-case-hunter) — low: `JournalViewModel` defaults to `.current`, so they agree in the app; a parameter would be added for no visible harm.
- Hardcoded «в фокусе», «Сегодня», «Вчера» (blind-hunter) — low: the app is Russian-only in v1, same as the rest of the UI.
- Accessibility: `.combine` order, no explicit label, `.isHeader` (blind-hunter, edge-case-hunter) — low: the combined element reads day, date, total, «в фокусе» in visual order; `Section` headers in a `List` carry the header trait; VoiceOver does not re-announce a changing value without a live region. Row-level VoiceOver work is already planned in 3.3.
- Layout: no `lineLimit` on the title column, `minimumScaleFactor`, no year in the date (blind-hunter, edge-case-hunter) — low: Journal has a fixed minimum width and month names are short; a year is not in the spec.
- `.dayTotal` role, `tabularFigures`, `Space.x2` not shown in the diff (blind-hunter, acceptance-auditor) — false: `Typography.swift` defines `.dayTotal` at size 28, tracking -0.03; `tabularFigures()` exists at `Typography.swift:71`; `check-tokens.sh` exit 0 is recorded in the spec.
- `isLive` never true if day keys are built differently, e.g. DST (edge-case-hunter) — false: keys and `today` both come from `calendar.startOfDay(for:)` of the same calendar.
- New stored properties break other `DayGroup(...)` call sites (edge-case-hunter) — false: no other call sites exist in App, Core or tests.
- «Model is awkward», Swift concepts explanation owed, review layers not run (blind-hunter, acceptance-auditor) — false: not defects; the explanation is a post-story step and the layers have now run.
