---
title: 'Categories chrome, Settings and remaining errors'
type: 'feature'
created: '2026-11-08'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-5-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Story 5.3 of `_bmad-output/planning-artifacts/epics.md`: the Categories tab, the move-entries sheet and the Settings window still use system `List`/`TextField`/`Form`, `.red`, `.callout` fonts and default-accent buttons, and an export failure opens a modal `NSAlert`, so these screens still look like default SwiftUI.

**Approach:** Rebuild `CategoriesView` (rows, add row, move sheet) and `SettingsView` on tokens and base components: canvas background, `card()`, `InputField`, `typeRole`, ghost buttons, one primary button per screen, `ErrorStrip` for every problem line. The hotkey recorder keeps its system look. The export failure becomes an `ErrorStrip` in the Journal, where export is triggered (the Settings window has no export control), built from a pure tested `ExportProblem`. Behavior (add, rename, reorder, delete, hotkey rollback) does not change. `CategoriesView.swift` and `SettingsView.swift` join the guard list.

## I/O & Edge-Case Matrix

| Scenario | State | Expected |
|----------|-------|----------|
| Category op fails | `problem` set (duplicate name, has entries, ...) | `ErrorStrip` with the Core message, no `.red`, no action |
| Hotkey rejected | `hotkeys.error(for:)` non-nil | `ErrorStrip` under that recorder, shortcut rolled back as before |
| Export write fails | `CSVExporter`/`SQLiteExporter` throws | Journal shows `ErrorStrip` «Не удалось экспортировать: <reason>», no modal alert |
| Export succeeds or user cancels the save panel | after a failed one | strip is removed |

</frozen-after-approval>

## Implementation Notes

- Tests first in `AppTests/ExportProblemTests.swift` (must be seen FAIL): `ExportProblem.message(_:)`.
- Decision (not frozen, recorded): the epic AC says «Settings … the export error is the error strip», but Export is a Journal toolbar menu (`JournalEntriesView`), not a Settings control. The strip goes where the failure occurs (EXPERIENCE.md: «Wherever it occurred»). Moving Export into Settings is not done.
- Decision: the move-entries sheet is its own modal screen: its confirm button is primary, Cancel is ghost; the Categories tab keeps «Добавить» as its only primary.
- Unverified until the running app (retro B6): `onSubmit` reaching the `TextField` inside `InputField`; `List` with `.onMove` drag on a hidden-background list inside a card; native `Picker` in the move sheet looks acceptable (same open risk as 5.2); ghost icon-only trash button; Settings recorder fits the card.
- Swift concepts to explain after the task: `Settings` scene, `LabeledContent`, `onSubmit` propagation through the environment.
- Done: `CategoriesView` is a card-wrapped hidden-background `List` (keeps `onMove`), rows use `ToneSwatchPicker`, `InputField`, caption count and a ghost icon trash; the add row is `InputField` + the only primary «Добавить»; problem line is `ErrorStrip(EntryProblem.message(_:))`. The move sheet is on canvas with `typeRole` text, ghost «Отмена» (Esc), primary «Перенести и удалить» (Return), native `Picker` kept. `SettingsView` is a title plus one card; each hotkey row is `LabeledContent` (token label, system `KeyboardShortcuts.Recorder(for:)` unchanged), `ErrorStrip` for a rejected hotkey, ghost reset button. Export: `ExportActions` returns the problem text (`ExportProblem.message`, new pure helper) instead of an `NSAlert`; `JournalEntriesView` shows it as an `ErrorStrip` under the split and clears it on the next export attempt. `CategoriesView.swift`, `SettingsView.swift` and `App/Export` are in `scripts/token-guard-paths.txt`.
- Seen: `ExportProblemTests` red first (compile: `ExportProblem` missing), then App tests `** TEST SUCCEEDED **`, Core 208 passed, swiftlint 0 violations, `check-tokens.sh` exit 0, `test-check-tokens.sh` ALL TESTS PASSED.
- Running app (B6): NOT inspected. This session has no screen control, and the instance running on the machine is the author's own Xcode debug run started before these edits (not relaunched here). Owed by the author, all unverified: [ ] Categories: card around the list, drag reorder still works, `onSubmit` (Return) in the add and rename `InputField`s, ghost trash button, count text; [ ] one primary only on the tab, no blue/red anywhere; [ ] failed add (duplicate name) shows the strip, no `.red`; [ ] move sheet: native `Picker` look on canvas, Return/Esc; [ ] Settings (⌘,): card, `LabeledContent` row fits 440pt with the system recorder, rejected hotkey shows the strip and rolls back, reset buttons; [ ] export failure (e.g. save to a read-only folder) shows the strip in the Journal and a later successful export or cancel clears it.
- Review not run in this session by the author's rule; status is `review`, review goes to a fresh session.

### Review Findings

Code review 2026-11-08, diff `3171a73^..3171a73`, four layers (Blind Hunter, Edge Case Hunter, Verification Gap, Acceptance Auditor), all completed. Running app not inspected by the reviewers; the B6 items stay owed by the author.

- [x] [Review][Patch] Author decision 2026-11-08: export control also goes into Settings, with its own `ErrorStrip` (the Journal menu and strip stay). `SettingsView` needs the journal view model injected from `TimeTrackerApp.swift:44`; reuse `ExportActions` and `ExportProblem`; add `SettingsView` export section tests only for pure parts. [App/Settings/SettingsView.swift, App/TimeTrackerApp.swift]
- [x] [Review][Patch] Low: `problem` goes stale after a later successful action: `CategoryRow.select` and `CategoriesView.move` set it on failure but never clear it on success, unlike `add`/`rename`/`requestDelete` [App/Journal/CategoriesView.swift:49-58, 117-123]
- [x] [Review][Defer] Unverified medium: B6 items are unchecked in the running app (Return/`onSubmit` reaching the `TextField` in `InputField` for add and rename; `onMove` drag and drag highlight on a hidden-background `List` inside a card; `InputField` fills the row after `Spacer()` was dropped from `CategoryRow`; native `Picker` look in the sheet; Settings recorder inside `LabeledContent` fits 440pt; rejected hotkey strip and rollback; export-failure strip shows and later success/cancel clears it) — deferred: author's running-app pass
- [x] [Review][Defer] Unverified medium: VoiceOver — `KeyboardShortcuts.Recorder(for:)` has no title of its own inside `LabeledContent`, and the new `ErrorStrip` may not be announced when it appears [App/Settings/SettingsView.swift:41] — deferred: settle with a VoiceOver pass over Settings and a forced export failure; add `.accessibilityLabel(title)` on the recorder if it is read unlabeled
- [x] [Review][Defer] Verification gap: no test observes `ExportActions.exportCSV/exportSQLite` returning the problem text on a failed write and `nil` on success/cancel, nor `JournalEntriesView` clearing the strip; `ExportProblemTests` covers only the pure string — deferred: `NSSavePanel.runModal` blocks unit tests and the repo has no SwiftUI view tests (same line as the 5.2 and 4.3 deferrals); if it ever regresses, split the write step into `write(rows, to:) -> String?` and test it
- [x] [Review][Defer] Low: `MoveEntriesSheet` with a single category that has entries shows an empty `Picker` and a permanently disabled primary button (Cancel/Esc works) [App/Journal/CategoriesView.swift:144-173] — deferred: pre-existing sheet logic, only restyled in 5.3; add an explanatory line or hide the move action if touched again

#### Rejected

- «Two primary buttons (Categories tab plus move sheet) vs AC 1» — accepted by the author 2026-11-08: the sheet is its own modal screen.
- «Return on the destructive default action deletes the category without confirmation» — low; the sheet is itself the confirmation (text states the consequence, Cancel is Esc), and `.defaultAction` on it predates 5.3.
- «`exportCSV`/`exportSQLite` need `@discardableResult`, other callers may drop errors» — false: the only callers are the two toolbar buttons (`JournalEntriesView.swift:124-125`), both assign the result.
- «Export problem lives in view `@State`, lost if the view is recreated» — false: the save panel is modal and the assignment is synchronous on the same view; the state is transient presentation state, not business logic.
- «Strip has no dismiss/timeout, `String?` cannot tell cancel from success» — low; spec says "no action" and the matrix requires cancel/success to clear it; an enum or dismiss control adds surface for no named harm.
- «`App/Export` directory in the guard list may not be supported» — false: `check-tokens.sh` walks each entry with `find "$entry" -type f -name '*.swift'`.
- «Icon-only trash button has no accessibility label» — false: `Button("Удалить", systemImage:)` with `.labelStyle(.iconOnly)` keeps "Удалить" as its label.
- «Stale doc comment on `SettingsView.recorder`», «`sprint-status.yaml` timestamp has no timezone», «`List` has no explicit height or empty state» — cosmetic/negligible.
