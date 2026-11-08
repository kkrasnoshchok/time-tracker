---
id: SPEC-window-fixes-and-journal-hotkey
companions: []
sources:
  - ../../../docs/superpowers/specs/2026-11-01-bmad-and-ui-roadmap-design.md
---

> **Canonical contract.** This SPEC and the files in `companions:` are the complete, preservation-validated contract for what to build, test, and validate. Source documents listed in frontmatter are for traceability — consult them only if you need narrative rationale or prose color this contract intentionally omits.

# Window fixes and Journal hotkey

## Why

Three small pains in the macOS menu bar app, all about windows: the Journal list changes width when an entry is selected, the menu bar popover shows an extra translucent background wider than its content, and the Journal can only be opened from the popover or the Dock. The author (sole user) wants these fixed before the design-system stage so UI is not redone twice.

## Capabilities

- **CAP-1**
  - **intent:** The Journal entry list fills the full window height and keeps its width when an entry is selected or deselected.
  - **success:** Measured list width is identical with no selection and with a selection; the list spans the window height. Verified by running the app and by screenshots.

- **CAP-2**
  - **intent:** The menu bar popover shows no extra translucent background wider than its content.
  - **success:** Popover screenshot shows only the content card, with no visible area beyond it.

- **CAP-3**
  - **intent:** The user can open the Journal with a global hotkey, default ⌃⌥J, changeable in Settings next to the palette hotkey and shown in a popover row.
  - **success:** Pressing the hotkey opens the Journal; with the Journal already open it only brings that window forward (no second window), restoring it first if it is minimized. Settings has a second recorder; popover shows a row with the current shortcut, like the palette row. Assigning a shortcut that is already taken shows an error next to the input saying so. Behavior that can be tested lives in `Packages/TimeTrackerCore` and is covered by tests that were seen failing first.

## Constraints

- Root causes for CAP-1 and CAP-2 are confirmed by running the app before any fix is written.
- Hotkey follows the palette pattern: `KeyboardShortcuts.Name.openJournal` next to `togglePalette`, wired through `HotkeyService`; the action is `AppRouter.openJournal()`.
- TDD: a failing test is seen before code. Logic goes in `Packages/TimeTrackerCore`; `App/` only displays state.
- Swift 6 with strict concurrency; "now" only via `TimeProvider`.
- Every line must be understandable to a Swift learner with JS/TS/React background; new concepts are explained through TypeScript/React analogies after each task.

## Non-goals

- Design-system, colors, fonts or any visual restyling (stage 3).
- Changing palette hotkey behavior.
- New Journal features beyond layout (filters, columns, detail redesign).

## Success signal

The author presses ⌃⌥J from any app and the Journal comes forward; clicking entries never shifts the list; the popover looks clean. All checked by running the app, with tests green.

## Assumptions

- A cleared Journal shortcut shows "не задан" in the popover row and "Изменить…" opens Settings, same as the palette row (roadmap says only "row in popover").
- "Already taken" means: the same shortcut is already assigned to the other in-app hotkey (palette vs Journal), checked in both recorders. System-reserved shortcuts are not specified; the library recorder has its own alert for those.
- Cause of CAP-1 is likely content-driven pane widths in `HSplitView` (`ContentUnavailableView` vs `EntryDetailView`). Unconfirmed.
- Cause of CAP-2 is unknown (suspects: `MenuBarExtra` `.window` style with `padding(16)` and `frame(width: 300)`). The author's screenshot was not provided. Unconfirmed.
- This agent cannot take screenshots or control windows, so root causes are confirmed in `bmad-build` with the author's help.
