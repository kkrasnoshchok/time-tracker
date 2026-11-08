---
title: 'Window fixes and Journal hotkey'
type: 'feature'
created: '2026-11-01'
status: 'done'
baseline_commit: '638d29a9377bd99732980e23dcca4fc842bc0f81'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/specs/spec-window-fixes-and-journal-hotkey/SPEC.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Journal list changes width when an entry is selected and does not fill the window height; the menu bar popover shows an extra translucent background wider than its content; the Journal has no global hotkey.

**Approach:** Confirm both layout causes by running the app, then fix them. Add a Journal hotkey (default ⌃⌥J) following the palette pattern, configurable in Settings, shown in the popover, and rejected with an inline error when the shortcut is already used by the palette hotkey.

## Boundaries & Constraints

**Always:** TDD, failing test seen first. Logic in `Packages/TimeTrackerCore`, `App/` only renders state. Swift 6 strict concurrency. Code a Swift learner can follow line by line; explain new concepts via TypeScript/React analogies after each task. Hotkey with the Journal already open only brings the window forward (restoring it if minimized); never opens a second window.

**Never:** Restyling (colors, fonts), changing palette behavior, new Journal features. No layout fix before its cause is confirmed. Temporary diagnostics are removed before commit.

**Decisions (from user):** A shortcut "already taken" is rejected: the previous value is restored and the error is shown next to that recorder. "Taken" = the same shortcut as the other in-app hotkey; system-reserved shortcuts stay with the library's own alert. A cleared Journal shortcut shows «не задан» in the popover row.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Free shortcut | Journal recorder gets ⌃⌥K, palette is ⌃⌥T | Accepted, no error | N/A |
| Taken by palette | Journal recorder gets palette's shortcut | Rejected, previous value restored | Error text next to Journal recorder |
| Taken, reverse | Palette recorder gets Journal's shortcut | Rejected, previous value restored | Error text next to palette recorder |
| Clear | Recorder cleared | Accepted, shortcut is nil | Previous error cleared |
| Retry after error | Valid shortcut after a rejection | Accepted | Error cleared |
| Journal open | Hotkey pressed, window visible or minimized | Same window forward, restored if minimized | N/A |

</frozen-after-approval>

## Code Map

- `App/Journal/JournalEntriesView.swift` -- `HSplitView { entryList.frame(minWidth: 400); detail.frame(minWidth: 360) }`; detail switches between `ContentUnavailableView` and `EntryDetailView`. Cause of CAP-1 to confirm here.
- `App/Journal/JournalRootView.swift` -- `TabView` with `.frame(minWidth: 900, minHeight: 560)` hosts the entries view; check it for the height problem.
- `App/TimeTrackerApp.swift` -- `MenuBarExtra { MenuBarContent } .menuBarExtraStyle(.window)`; `Window("Журнал", id: "journal")`.
- `App/MenuBar/MenuBarContent.swift` -- `.padding(16).frame(width: 300)`; palette shortcut row to copy for the Journal.
- `App/Hotkey/HotkeyService.swift` -- `Name.togglePalette`, `onKeyDown`; add `Name.openJournal` (default ⌃⌥J) and a Journal callback.
- `App/AppCoordinator.swift` -- creates `HotkeyService`; wire `AppRouter.shared.openJournal()`.
- `App/AppRouter.swift` -- `openJournal()` calls `openWindow(id:)` then `NSApp.activate`; add restoring a minimized window.
- `App/Settings/SettingsView.swift` -- one `Recorder`, reset button; add a second recorder and inline errors.
- KeyboardShortcuts 1.10.0 `Recorder` saves the shortcut first, then calls `onChange`; it does not reject in-app duplicates, so we restore the old value ourselves. `Shortcut.carbonKeyCode` / `carbonModifiers` give plain Ints.
- `Packages/TimeTrackerCore/.../Palette/PaletteViewModel.swift` -- style reference for `@MainActor @Observable` view models; tests in `Tests/.../PaletteViewModelTests.swift` (Swift Testing).
- Do not touch: `JournalViewModel`, store, palette code paths.

## Tasks & Acceptance

**Execution:**
- [x] `App/Journal/JournalEntriesView.swift`, `App/MenuBar/MenuBarContent.swift` -- temporary diagnostics (log list/detail widths, popover window and view frames) and run the built binary from the shell to read the log while the user clicks -- confirm both causes before any fix
- [x] `Packages/TimeTrackerCore/Tests/.../HotkeySettingsViewModelTests.swift` -- failing tests for the matrix rows -- TDD red
- [x] `Packages/TimeTrackerCore/Sources/.../Hotkey/HotkeySettingsViewModel.swift` -- `KeyCombo` (key code + modifiers Ints), `HotkeyAction`, `assign(_:to:) -> Bool`, per-action error text -- TDD green
- [x] `App/Hotkey/HotkeyService.swift`, `App/AppCoordinator.swift` -- `Name.openJournal`, second `onKeyDown` -> `AppRouter.shared.openJournal()` -- CAP-3
- [x] `App/AppRouter.swift` -- deminiaturize the Journal window before activating -- CAP-3
- [x] `App/Settings/SettingsView.swift` -- second recorder, reset to ⌃⌥J, `onChange` -> view model; on rejection restore the old shortcut; error text under the recorder -- CAP-3
- [x] `App/MenuBar/MenuBarContent.swift` -- Journal shortcut row -- CAP-3
- [x] `App/Journal/JournalEntriesView.swift` -- fix per confirmed cause (width independent of selection, full height) -- CAP-1
- [x] `App/MenuBar/MenuBarContent.swift` / `App/TimeTrackerApp.swift` -- fix per confirmed cause -- CAP-2
- [x] Remove diagnostics

**Acceptance Criteria:**
- Given the Journal is open, when an entry is selected then deselected, then the list width is identical in all three states and the list spans the window height.
- Given the popover is open, then no translucent area extends beyond the 300 pt content.
- Given any app is frontmost, when ⌃⌥J is pressed, then one Journal window is in front, restored if it was minimized.
- Given Settings is open, when the Journal recorder gets the palette's shortcut, then it reverts and an error appears beside it.

## Implementation Notes

## Spec Change Log

## Review Triage Log

| Finding | Verdict | Route | Evidence |
|---|---|---|---|
| Startup: stored palette equals new Journal default, both fire | low | rejected | Needs the palette customised to exactly ⌃⌥J earlier; fix needs a policy choice and extra branches. |
| Stale error beside the other recorder after its conflict is gone | low | rejected | Cosmetic; cleared on the next action for that recorder; fix adds a loop in `assign`. |
| Reset into a clash appears to do nothing | false | rejected | `apply` restores the old value and the error text is shown beside the recorder. |
| Rollback re-enters `apply` / Recorder shows stale value | false | rejected | User ran the app: the rejected shortcut reverts and stays reverted. |
| Popover shortcut row not refreshed after a change in Settings | low | rejected | Same pattern as the pre-existing palette row; user saw shortcuts update. |
| Window match by literal title "Журнал" | low | rejected | Title matches the `Window("Журнал")` declaration today; rename is a future, visible break. |
| `openWindowAction` nil before first capture | low | rejected | Captured when the menu bar label appears at launch. |
| CAP-2 not fixed in diff | false | rejected | Logs: popover window is 300x196, equal to its content; user confirmed no extra background, with and without diagnostics. No defect to fix. |
| List may still shift width / TabView height cap | false | rejected | User verified width stable and full height after the fix. |
| No App-layer test for KeyCombo<->Shortcut mapping and rollback | medium (unverified) | defer | There is no App test target; Core tests cover only the rule. |
| Cosmetic: hard-coded reset titles, duplicate «Изменить…», test names, system-shortcut collisions | low | rejected | No named harm; system shortcuts are out of scope per spec decisions. |

## Design Notes

Why a Core view model for hotkeys: the "is this taken" rule is pure logic and needs no AppKit, so it is unit-testable; the App only converts `KeyboardShortcuts.Shortcut` to `KeyCombo` and renders `errors` (like a React component rendering state from a reducer).

## Verification

**Commands:**
- `swift test --package-path Packages/TimeTrackerCore` -- expected: all pass, new tests seen failing first
- `xcodegen generate && xcodebuild -scheme TimeTracker -destination 'platform=macOS' build | xcbeautify` -- expected: BUILD SUCCEEDED
- `swiftlint` -- expected: no new violations

**Manual checks (if no CLI):**
- Run the app: list width and height, popover background, ⌃⌥J with window closed/open/minimized, duplicate-shortcut error in Settings.
