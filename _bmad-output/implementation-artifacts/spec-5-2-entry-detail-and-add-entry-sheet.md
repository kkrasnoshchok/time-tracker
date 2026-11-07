---
title: 'Entry detail and add-entry sheet'
type: 'feature'
created: '2026-11-07'
status: 'in-review'
route: 'oneshot'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-5-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Story 5.2 of `_bmad-output/planning-artifacts/epics.md`: `EntryDetailView`, `AddEntrySheet` and `EntryFormFields` use a system grouped `Form`, system fonts, `.red` and default-accent buttons, so fixing a forgotten timer does not look like the rest of the app.

**Approach:** Rebuild the three views on tokens and base components: field groups are `card()`s over `surface-canvas`, text inputs are `InputField`/`InputFieldShell`, text uses `typeRole`, the problem line is `ErrorStrip` (Core message, «Всё равно» ghost action for overlap only), the sheet has one primary button («Добавить»), everything else is ghost. Native `Picker` and `DatePicker` stay (the platform cannot restyle them). The ProblemBanner decision (message + optional action) becomes a pure tested helper. Behavior (autosave in detail, overlap rules, draft binding) does not change. The three files join the guard list.

## I/O & Edge-Case Matrix

| Scenario | State | Expected |
|----------|-------|----------|
| Overlap error | `StoreError.overlap([id])` | strip shows Core message, action «Всё равно» |
| Any other error | e.g. `.endBeforeStart` | strip shows Core message, no action |
| No error | `nil` | no strip |
| Long entry, end edited | running or finished entry with end changed, saved | Journal row and day total update after save (flow 3) |
| Running entry | `draft.end == nil` | «Конец» shows «таймер идёт» in `text-secondary`, no picker |

</frozen-after-approval>

## Implementation Notes

- Tests first in `AppTests/EntryProblemTests.swift` (must be seen FAIL): `EntryProblem.message(_:)` and `EntryProblem.actionLabel(_:)`.
- Scope of open items (decided in session, not frozen): epic 3 B1 (doc reconciliation, needs the author's say-so), B3 (record manual checks, VoiceOver row selection needs a human) and epic 2 A5 (`mutingTags`, `PaletteView` split, touches Palette not this area) stay separate `chore` work, NOT in this commit. Taken into 5.2: the detail-pane overflow check at 400pt (epic 3 deferral), since this story rebuilds that pane.
- Unverified until the running app (retro B6): native `DatePicker` (compact) shows the system accent; `Picker` menu look inside a card; `TextEditor` inside an input shell; Tab order; Return in the sheet confirms; Esc cancels.
- Swift concepts to explain after the task: `Form`/`formStyle` (and why it is replaced), sheets (`.sheet` + `@Environment(\.dismiss)`), `Binding` of a draft struct, `@FocusState`.
- Done: `EntryFormFields` is cards (`card()`) of labeled fields on `surface-canvas` (system `Form`/`formStyle` removed); text inputs are `InputField`, notes is a `TextEditor` inside `InputFieldShell`; `ProblemBanner` is gone, replaced by `ErrorStrip` fed by the new pure `EntryProblem` (`App/Journal/EntryProblem.swift`); detail is a scrolling pane on canvas with a ghost «Удалить запись» (no `.red`); the sheet has one primary «Добавить» (Return) and a ghost «Отмена» (Esc). The four files are in `scripts/token-guard-paths.txt`.
- Seen: `EntryProblemTests` red first (compile: `EntryProblem` missing); then App tests succeeded, Core 208 passed, swiftlint 0, `check-tokens.sh` exit 0, `test-check-tokens.sh` passed.
- Running app (B6): the Debug build launches, but this session has no screen control, so the screens were NOT inspected. Owed by the author: [ ] detail and sheet show cards on linen canvas, no system blue/red; [ ] native `DatePicker`/`Picker` look acceptable inside a card (accent color on the date picker is the open risk); [ ] `TextEditor` sits inside the input shell without a white system background; [ ] Tab order is category, title, tags, start, end, notes; [ ] Return confirms and Esc cancels the sheet; [ ] overlap shows the strip with ghost «Всё равно», other errors show no action; [ ] editing the end of a long running/finished entry updates the row and day total (flow 3); [ ] detail pane (400pt) does not overflow with a long title, note and many tags; [ ] delete confirmation still works.
- Review not run in this session by the author's rule; status is `in-review`, review goes to a fresh session.
