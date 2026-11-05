---
title: 'Menu bar item as plain text'
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

**Problem:** Story 4.1 of `_bmad-output/planning-artifacts/epics.md`: the menu bar label is built inline in `TimeTrackerApp.swift` and `AppModel.menuBarTitle` (an empty category name gives a leading space, nothing is tested), and the item has no VoiceOver label that announces category and elapsed time.

**Approach:** Move the label text into a pure, tested helper in `App/MenuBar/` (category name + `DurationFormat.clock`, with a fallback name, plus a VoiceOver sentence for running and idle). The `MenuBarExtra` label renders plain `Text` with tabular figures, no color, no animation, and sets the accessibility label from the helper. Idle keeps the existing clock image, with no color.

## I/O & Edge-Case Matrix

| Scenario | State | Expected |
|----------|-------|----------|
| Running | category «Работа», 12:05 | text «Работа 12:05», tabular figures, no color |
| Running, over an hour | category «Работа», 1:02:05 | «Работа 1:02:05» |
| Running, no category | category nil or empty | «Без категории 12:05» |
| Idle | no running entry | existing `clock` image, no color |
| VoiceOver running | category «Работа», 12:05 | «Работа, 12 минут 5 секунд» style sentence naming category and elapsed time |
| VoiceOver idle | no running entry | «Таймер не запущен» |

</frozen-after-approval>

## Implementation Notes

- Pure helper `MenuBarLabel` (text, accessibility label) in `App/MenuBar/`, tests first in `AppTests` (seen FAIL).
- `AppModel.menuBarTitle` delegates to the helper (or is replaced by it); `App/MenuBar` joins the guard list in Story 4.3, but the guard is run now.
- Unverified: how `MenuBarExtra` renders a `Text` label with `.monospacedDigit()` and whether `.accessibilityLabel` on the label is announced. Check in the running app before review (retro B6); author-reported tick is enough.
- Swift concepts owed: `MenuBarExtra` label closure (a render prop), `@Observable` `AppModel` observation (a store hook that re-renders on read fields), pure helper vs view (a util function vs a component).
- Done: `App/MenuBar/MenuBarLabel.swift` (text, accessibilityLabel), `AppModel.menuBarTitle` delegates to it, new `AppModel.menuBarAccessibilityLabel`, `.accessibilityLabel` on the `MenuBarExtra` label. Visible text and `.monospacedDigit()` unchanged apart from the «Без категории» fallback.
- VoiceOver elapsed time uses `DurationFormat.short` («1 ч 30 мин», seconds dropped) so it does not re-announce every second; the matrix wording «12 минут 5 секунд» was read as a style example.
- Seen: `MenuBarLabelTests` red first (compile: `MenuBarLabel` missing); then App 72 passed, Core 208 passed, swiftlint 0, `check-tokens.sh` exit 0.
- Owed by the author in the running app (retro A6/B6; assumptions unverified): [ ] item shows «Категория m:ss» in plain text, no color, digits do not jitter; [ ] VoiceOver on the item reads category and elapsed time; idle shows the clock image.
- Review layers skipped (no explicit instruction to spawn subagents).
