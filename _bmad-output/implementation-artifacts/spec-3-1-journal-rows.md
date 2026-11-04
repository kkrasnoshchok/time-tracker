---
title: 'Journal rows'
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

**Problem:** Story 3.1 of `_bmad-output/planning-artifacts/epics.md`: Journal rows still use system styles (`.secondary`, accent «идёт», `.font(.caption)`), carry a two-line subtitle with tags and the start–end range, and have no fixed height, so the list is noisy.

**Approach:** Restyle `EntryRow` in `App/Journal/JournalEntriesView.swift` into a 44px single-line row in design tokens: time of day, name, category dot plus category name, right-aligned tabular duration. The running row sits on `surface-inset` with a `body-emphasis` duration instead of «идёт». The empty state becomes one `text-secondary` sentence. Selection, the 30-second refresh, the day header and the detail pane are not changed; no new Core logic.

Decisions made while planning (the author can renegotiate): an entry without a title shows «Без названия» in the name slot (the category name already appears beside the dot, so it is not repeated as the name); the empty state has two sentences depending on whether a filter is active («Записей пока нет.» / «Ничего не найдено.»), only one shown at a time; the running duration uses `DurationFormat.short(now − start)` through the existing injected `model.now`.

## Boundaries & Constraints

**Always:** tokens only (`typeRole`, `Color.text*`/`surfaceInset`, `Space`, `CategoryDot`), weights 400/500, `tabularFigures()` for time and duration; row height `Space.rowHeight`; hit target stays the whole row; `.tag(entry.id)` and `List(selection:)` unchanged; time via `model.now`, no `Date()`; the guard script is run and the file is not yet in the guard list (Story 3.4 adds it).

**Never:** tags or start–end range in the row; icons; a row fill in a category tone; changes to `DayHeader`, `HSplitView` width code, `EntryDetailView`, or `Packages/TimeTrackerCore`; editing `sprint-status.yaml` or committing (the author decides).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Finished entry | start 09:05, end 10:35, title, category | 44px: `09:05` caption secondary, title body, dot + category name secondary, `1:30` right-aligned tabular | N/A |
| Running entry | `end == nil` | row on `surface-inset`, duration `body-emphasis`, no «идёт», no accent | N/A |
| No title | `title == nil` | name «Без названия» | N/A |
| No category | `category == nil` | dot in the fallback tone, empty name | N/A |
| Empty, no filter | no entries | one sentence «Записей пока нет.» in `text-secondary`, no icon | N/A |
| Empty, filter active | `filter != EntryFilter()` and no groups | «Ничего не найдено.» | N/A |

</frozen-after-approval>

## Implementation Notes

- Changed: `App/Journal/JournalEntriesView.swift` only. `EntryRow` is one 44px line (`Space.rowHeight`) in tokens; running row on `surface-inset` (`Radius.row`) with a `body-emphasis` duration; empty state is one `text-secondary` sentence chosen by `journal.filter == EntryFilter()`. Core untouched, no new logic, so no new test (nothing pure to pin); the row is visual.
- Seen: build succeeded; `swiftlint` 0 violations in 75 files; `scripts/check-tokens.sh` exit 0 (file not yet in the guard list, Story 3.4 adds it); App tests 62 passed; Core 187 passed.
- Review layers were not run: spawning subagents needs an explicit author instruction and none was given.
- Not done by the agent (no Accessibility or Screen Recording access): manual checks in the running app, owed by the author before review (retro A6):
  - [ ] Finished and running rows look as specified; dots in their tones with the category name beside them, no row filled with a tone
  - [ ] Click and ↑/↓ selection work; the detail pane opens; list width does not jump
  - [ ] Running row duration updates every 30 s
  - [ ] Empty list and empty filter show one short sentence, no illustration
- Nothing committed, per the epic 3 context.

### Review Findings

- [x] [Review][Decision] Running state is visual only, VoiceOver has no «идёт» cue — decided: defer to Story 3.3 (rebuilds the row's accessibility together with «долго»)
- [x] [Review][Patch] Time and duration `Text` could truncate in a narrow row — `.lineLimit(1).fixedSize()` added [App/Journal/JournalEntriesView.swift]
- [x] [Review][Patch] Guard missed `Color.secondary`/`.primary`, implicit `.custom(`, `.weight(.bold)` — patterns plus fixture `bad-spellings` (seen FAIL, then PASS) [scripts/check-tokens.sh]
- [x] [Review][Patch] Stale "Still open" guard line — updated [_bmad-output/implementation-artifacts/deferred-work.md]
- [x] [Review][Defer] No automated check for row/empty-state logic — deferred: UI-only story; extract a pure row-state helper and test it in `AppTests` when 3.3/3.4 touch the row
- [x] [Review][Defer] Four manual checks above still unticked (retro A6) — deferred: author-owed, run before closing the story
