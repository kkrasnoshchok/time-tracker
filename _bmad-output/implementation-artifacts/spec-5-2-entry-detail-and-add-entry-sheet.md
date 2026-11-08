---
title: 'Entry detail and add-entry sheet'
type: 'feature'
created: '2026-11-07'
status: 'done'
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
- Running app (B6): the Debug build launches, but this session has no screen control, so the screens were NOT inspected. Owed by the author: [x] detail and sheet show cards on linen canvas, no system blue/red; [x] native `DatePicker`/`Picker` look acceptable inside a card (accent color on the date picker is the open risk); [x] `TextEditor` sits inside the input shell without a white system background; [x] Tab order is category, title, tags, start, end, notes; [x] Return confirms and Esc cancels the sheet; [x] overlap shows the strip with ghost «Всё равно», other errors show no action; [x] editing the end of a long running/finished entry updates the row and day total (flow 3); [x] detail pane (400pt) does not overflow with a long title, note and many tags; [x] delete confirmation still works.
- Review not run in this session by the author's rule; status is `in-review`, review goes to a fresh session.
- Author feedback after the running-app look (2026-11-07): overall look is fine; a separate design session will collect everything else. Known now: (1) native `Picker` (category) and native `DatePicker` (start/end) look poor next to the tokens; (2) by default the form is taller than the default window, so the detail pane and the sheet both show a scroll bar (double scroll). Not fixed in this commit.

### Review Findings

Code review 2026-11-08, diff `06c2f68..e4fc517`, four layers (Blind Hunter, Edge Case Hunter, Verification Gap, Acceptance Auditor), all completed. Native `Picker`/`DatePicker` look and the double scroll are excluded (already in deferred-work.md).

- [x] [Review][Patch] Medium: the `ErrorStrip` in the detail pane sits inside the `ScrollView`, so an autosave failure can be scrolled out of view; pin it outside the scroll area as `AddEntrySheet` does [App/Journal/EntryDetailView.swift:26-34]
- [x] [Review][Patch] Medium: the notes editor is hard-wired to `InputFieldShell(isFocused: false)`, so keyboard focus is invisible there (AC1 keyboard reachability); drive it from a `@FocusState` [App/Journal/EntryFormFields.swift:48-55]
- [x] [Review][Patch] Low: «Удалить запись» and «Отмена» lost `role: .destructive` / `role: .cancel`; restore the roles (the ghost style does not read the role, so the look stays token-only) [App/Journal/EntryDetailView.swift:40, App/Journal/AddEntrySheet.swift:37]
- [x] [Review][Patch] Low: `otherErrorsOfferNoAction` omits `.duplicateName`, `.categoryHasEntries`, `.noRunningTimer`; list every non-overlap case [AppTests/EntryProblemTests.swift:19-22]
- [x] [Review][Defer] Unverified medium: `ErrorStrip` is `lineLimit(1)`; a long `saveFailed(reason)` may be cut in the 400pt pane — deferred: settle by forcing a long error in the running app; the component is shared and predates 5.2 Author checked in the running app on 2026-11-08: passed.
- [x] [Review][Defer] Unverified medium: B6 items still unchecked (Tab order incl. notes editor, Return in notes vs `.defaultAction`, overlap strip + «Всё равно», 400pt overflow, delete confirmation) — deferred: author's running-app pass, only the look was reported on 2026-11-07 Author checked all of them in the running app on 2026-11-08: all passed.
- [x] [Review][Defer] Verification gap: no automated test that «Всё равно» passes `allowOverlap: true`, and none for flow 3 (row and day total update after end edit) — deferred: thin SwiftUI glue is checked by hand (retro C5); extract into a Core method if it regresses

#### Rejected

- «Stale error strip after a fixed form» — false: `save` sets `problem = nil` on success (`EntryDetailView.swift:46`).
- «No test for the nil case» — false: `EntryProblem` takes a non-optional `StoreError`; the strip is simply absent when `problem == nil`.
- «Category Picker blank when `categoryID` is nil/deleted», «end `DatePicker` binding captures `end`» — low, lines are unchanged from before 5.2.
- «Guard list says three files, diff adds four», «red-first claim unprovable» — fixing means editing the spec/frozen text; not a code defect.
- «ScrollView padding/background placement», «no dark mode / Dynamic Type check», «`labelsHidden()` loses VoiceOver label» — low/cosmetic (the `DatePicker`/`Picker` titles are kept), design session territory.
- «`messageIsTheCoreMessage` is tautological» — low; the helper is a pass-through by design.
