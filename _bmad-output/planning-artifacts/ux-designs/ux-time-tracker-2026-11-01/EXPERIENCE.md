---
name: Time Tracker
status: final
sources:
  - docs/application-design.md
  - DESIGN.md
updated: 2026-11-01
---

# Time Tracker — Experience Spine

> Paired with `DESIGN.md`. Single-user native macOS app, keyboard-first, quiet. Scope: the visual and behavioral layer only; business logic stays in `Packages/TimeTrackerCore` and is not changed here.

## Foundation

Desktop, macOS 26+, SwiftUI. Menu bar app that also has a Dock icon; closing the Journal window does not quit the app. Native window chrome, menu bar item and system dialogs follow the platform. `DESIGN.md` is the visual identity; this spine adds behavior. Light theme only in v1.

Priority of surfaces: 1 Palette, 2 Journal, 3 Menu bar, 4 everything else.

## Information Architecture

| Surface | Reached from | Purpose |
|---|---|---|
| Palette | Global hotkey ⌘⌥I; menu bar item | Start, switch or backdate an entry in a typed line |
| Journal | Global hotkey ⌘⌥J; menu bar item; Dock icon | Day-by-day list, totals, edit an entry, search, filters |
| Entry detail | Journal row selection | Edit title, category, tags, notes, times |
| Add entry sheet | Journal toolbar | Add a past entry manually |
| Categories | Journal tab | Rename, reorder, choose a color from the fixed set |
| Menu bar item + popover | Always present in menu bar | Read running category and elapsed time; stop; open Palette or Journal |
| Settings | App menu | Hotkeys, export |

Journal is a split view: list on the left, detail on the right.

## Voice and Tone

Microcopy is Russian, short, plain, no exclamation marks, no emoji. Brand voice lives in `DESIGN.md.Brand & Style`.

| Do | Don't |
|---|---|
| «Таймер не запущен» | «Упс! Ничего не запущено 🙈» |
| «Не удалось сохранить запись. Попробуйте ещё раз.» | «Ошибка 500» |
| «в фокусе» | «Вы молодец!» |
| «долго» (next to an unusually long duration) | Warnings in red or alarms |

## Component Patterns

Behavioral. Visual specs live in `DESIGN.md.Components`.

| Component | Use | Behavioral rules |
|---|---|---|
| Palette panel | Global hotkey | Opens focused on the field, closes on Esc or Enter or focus loss. The panel never takes the keyboard from the typed line. |
| Category token | Palette input | Appears as soon as the typed first word resolves to an existing category; Backspace at the start of the name removes the token and returns its text to the line. |
| Suggestion row | Palette | ↑/↓ moves selection, Tab accepts the suggestion into the line, Enter submits. Mouse hover does not move selection. |
| Running row | Palette (when running) | Read-only context: current title, category, elapsed time. |
| Journal row | Journal list | Click selects and fills the detail pane. The running entry's duration updates every 30 seconds. |
| Category color picker | Categories tab | Choose one of the eight fixed tones; no free color input. |
| Primary button | Detail, sheets | One per surface. |

## State Patterns

| State | Surface | Treatment |
|---|---|---|
| Timer running | Menu bar item | Category and elapsed time as text. No color, no animation. |
| Timer running | Journal | Row on `surface-inset`, duration in `body-emphasis`. |
| Timer not running | Popover | «Таймер не запущен» and a hint with the Palette hotkey. |
| Timer running unusually long | Journal row, popover | Gray text «долго» next to the duration. Informational only. [Threshold and wording to be set in the spec; the owner often forgets to stop and fixes it by hand in the Journal.] |
| Empty Journal / filter returns nothing | Journal list | One short sentence in `text-secondary`; no illustration. |
| Palette: no match for the first word | Palette | Offers to create the category in place; the token appears on confirm. |
| Error (save, export, invalid input) | Wherever it occurred | One line of `text-primary` text on a `surface-inset` strip with a line icon; stays until dismissed or the cause is fixed. No red. |
| Focus | Inputs, palette | Border shifts to `action-primary`; no glow. |

## Interaction Primitives

- Keyboard first. ⌘⌥I toggles the Palette, ⌘⌥J opens the Journal; both are configurable in Settings.
- Palette grammar is unchanged: `category title #tag -20m`.
- Selection by click in the Journal; standard macOS list behavior (arrow keys, type-select).
- **Banned:** gradients, bounce or spring animation, sound, badge counts on the Dock icon, celebratory confetti, streaks, notifications that nag.
- Motion: only functional (panel appear and dismiss, selection change). Short and linear-feeling; none that draws attention.

## Accessibility Floor

Behavioral. Visual contrast lives in `DESIGN.md`.

- Every control reachable by keyboard; Tab order follows reading order.
- VoiceOver: running timer announces category and elapsed time; the category token is announced with its category name (color is never the only carrier of meaning).
- Reduce Motion: remove panel transitions entirely.
- Dynamic type: use text styles mapped to the `DESIGN.md` scale so they scale with the system setting.
- Hit targets ≥ 24pt in dense lists, ≥ 44pt row height in the Journal.
- Increase Contrast: keep hairline rings visible (raise opacity).

## Inspiration & Anti-patterns

- **Lifted from Spotlight:** a tall single-field panel, a list below, a token for the resolved part of the query.
- **Lifted from Duna (web reference):** paper tones, pills, hairline depth, no accent color.
- **Rejected — Liquid Glass inside our own surfaces:** translucency changes the surface color with whatever is behind it; the warm paper tone would be lost.
- **Rejected — colored status badges (Toggl-style running greens):** the quiet tone is the point; state is shown by wording and tone.
- **Rejected — AI-product styling:** no gradient glow, sparkles or chatty microcopy.

## Key Flows

### Flow 1 — Start and switch (Vadym, morning at the laptop)

1. Vadym opens the laptop and presses ⌘⌥I.
2. The Palette opens on a white panel; the field is focused.
3. He types «Работа planning day»; after «Работа» the category token appears, tinted.
4. He presses Enter; the panel closes.
5. An hour later he presses ⌘⌥I again; the Running row shows «planning day · Работа».
6. He types the next task and presses Enter.
7. **Climax:** the menu bar item switches to the new category and a ticking time; the previous entry is closed without any further action.

Failure: unknown category → the Palette offers to create it before submitting.

### Flow 2 — Review the day (Vadym, end of day)

1. Vadym presses ⌘⌥J.
2. The Journal opens on today: day total «в фокусе» in `day-total`, rows below.
3. He scans the rows; category is read from the dot and gray category name.
4. He clicks a row to check or edit the title.
5. **Climax:** the day total and the per-row durations agree with how he remembers the day, in a calm single glance.

### Flow 3 — Forgot to stop (Vadym, next morning)

1. Vadym opens the Journal; yesterday's last row shows a duration of 13 hours with «долго».
2. He selects the row.
3. The detail pane opens with the end time editable.
4. He sets the end time to when he actually stopped and saves.
5. **Climax:** the row's duration and the day total update to the true values; «долго» disappears.

Note: there is currently no hotkey to stop a timer. That is a product gap, not a design decision; see Open items.

## Open items

- Hotkey or palette command to stop the running timer (product change).
- Threshold and exact trigger for the «долго» note.
- Migration of existing arbitrary category colors to the eight-tone set; behavior when more than eight categories exist (colors repeat).
- Removal of the `ColorPicker` and `randomColor()` from `CategoriesView`.
- Whether Entry detail needs a "stop now" quick action.
