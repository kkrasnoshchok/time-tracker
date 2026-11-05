# Epic 4 Context: Menu bar and popover in the new style

<!-- Compiled from planning artifacts, epic-3-context.md, the epic 3 retro and deferred-work.md. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

The menu bar item shows the running category and elapsed time as quiet plain text; the popover says «Таймер не запущен» with the Palette hotkey hint when idle, uses the design tokens and base components, and marks a timer running 8 hours or more with a gray «долго». Behavior (stop, notes, open Palette/Journal, hotkeys) does not change; this is a restyle plus reuse of the existing «долго» rule.

## Stories

- Story 4.1: Menu bar item as plain text
- Story 4.2: Popover in the design language
- Story 4.3: «долго» in the popover and menu bar guard

## Requirements & Constraints

- Menu bar item: running = category name and elapsed time as plain text, tabular figures, no color, no animation; idle = existing idle form, no color. The item stays system-drawn (native menu bar chrome is not restyled).
- VoiceOver on the item announces category and elapsed time; color is never the only carrier.
- Popover idle: «Таймер не запущен» plus a hint with the Palette hotkey (from `HotkeyService.shortcutDescription`) on `surface-canvas`, no extra translucent background.
- Popover running: category dot and name, elapsed time in `timer-display` (32/400, tabular), title in `body`, notes in the input field style, «Остановить» is the only primary button; other buttons ghost.
- Errors in the popover use the error strip, never `.red`. No system fonts (`.headline`, `.title3` rounded).
- «долго» in the popover: gray `caption` beside the elapsed time when running ≥ 8h (7h59m none); no color, alarm or notification. Uses `LongEntry.isLong` from Core.
- Banned: gradients, bounce/spring animation, sound, Dock badge counts, nagging notifications.
- TDD with red first; "now" from `TimeProvider`/`AppModel.now`, never `Date()`; no `sleep`. Weights 400/500 only; negative tracking only on `timer-display` and `day-total`.

## Technical Decisions

- Menu bar title logic lives in `AppModel.menuBarTitle` (`"<category> <DurationFormat.clock(elapsed)>"`), rendered by the `MenuBarExtra` label in `App/TimeTrackerApp.swift` with `.monospacedDigit()`. `AppModel` is `@Observable` and ticks once a second.
- `App/MenuBar` (`MenuBarContent`, `RunningTimerView`) is not yet in `scripts/token-guard-paths.txt`; Story 4.3 adds it. Run `scripts/check-tokens.sh` at the end of every UI task.
- Tokens and components come from `App/Design` (`ColorToken`, `typeRole`, `tabularFigures`, `Spacing`, `Buttons`, `InputField`, `ErrorStrip`, `CategoryDot`).
- Story 4.2 must first extract a pure `EntryRowModel` and move `EntryRow`/`DayHeader` out of `JournalEntriesView.swift` as its own `chore(4-2)` commit (retro B4/B5).
- App tests: `xcodebuild test -scheme TimeTracker -destination 'platform=macOS'`; Core tests via `swift test --package-path Packages/TimeTrackerCore`. New `App/` files need `xcodegen generate`.
- Commit subjects name the story (`feat(4-1): …`); preparatory work gets its own `chore(...)` commit.

## UX & Interaction Patterns

- Menu bar item and popover are priority 3 of 4 surfaces; the item is always present. Popover offers: read running category and time, stop, open Palette or Journal.
- Category colors appear only as an 8px dot in lists/popover; the menu bar item itself carries no color.
- Process lessons (retro B6): when a story depends on a native control's look or keys (e.g. `MenuBarExtra` label rendering), write the assumption as unverified and plan a running-app check before review.

## Cross-Story Dependencies

- 4.1 and 4.2 depend only on Epic 1. 4.2 carries the Epic 1 manual checks (focus rings, `InputField` caret/placeholder) and the `EntryRowModel` refactor.
- 4.3 reuses the «долго» rule from Story 3.3 and adds `App/MenuBar` to the guard list; it follows 4.2.
